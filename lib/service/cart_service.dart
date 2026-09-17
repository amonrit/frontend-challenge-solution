import 'dart:async';

import 'package:get/get.dart';

import '../model/cart_item_model.dart';
import '../model/deal_model.dart';
import '../model/flash_sale_status.dart';
import '../util/log_service.dart';
import 'flash_sale_clock_service.dart';
import 'reservation_gateway.dart';

class FlashSaleExpiryNotice {
  const FlashSaleExpiryNotice({
    required this.dealId,
    required this.dealName,
  });

  final int dealId;
  final String dealName;
}

class ReservationExpiryNotice {
  const ReservationExpiryNotice({
    required this.dealId,
    required this.dealName,
  });

  final int dealId;
  final String dealName;
}

/// App-wide cart. Lives for the whole session.
///
/// NOTE: the starter cart is purely local — it does not reserve stock on the
/// backend. See the "Reservations" feature task in PROBLEM.md.
class CartService extends GetxService {
  CartService({
    required ReservationGateway reservationGateway,
    FlashSaleClockService? flashSaleClock,
    DateTime Function()? now,
  })  : _reservationGateway = reservationGateway,
        _flashSaleClock = flashSaleClock,
        _now = now ?? DateTime.now;

  final ReservationGateway _reservationGateway;
  final FlashSaleClockService? _flashSaleClock;
  final DateTime Function() _now;
  Worker? _flashSaleClockWorker;
  final _operationGenerations = <CartItemModel, int>{};
  int _nextOperationGeneration = 0;

  final items = <CartItemModel>[].obs;
  final itemCount = 0.obs;
  final expiryNotices = <FlashSaleExpiryNotice>[].obs;
  final reservationExpiryNotices = <ReservationExpiryNotice>[].obs;

  @override
  void onInit() {
    super.onInit();
    final clock = _flashSaleClock;
    if (clock != null) {
      _flashSaleClockWorker = ever(clock.currentTime, (_) {
        _expireFlashDeals();
        _expireReservations();
      });
    }
  }

  Future<bool> add(DealModel deal) async {
    if (FlashSaleStatus.fromEnd(deal.flashSaleEndsAt, now: _currentTime)
        .isExpired) {
      LogService.log('cart: cannot add expired deal ${deal.id}');
      return false;
    }

    final existing = items.firstWhereOrNull((item) => item.deal.id == deal.id);
    if (existing == null) {
      return _addFirstReservation(deal);
    }

    if (existing.quantity >= deal.quantityLeft) {
      LogService.log('cart: cannot add more of deal ${deal.id}');
      return false;
    }
    if (existing.isReservationPending) {
      LogService.log(
          'cart: reservation change is already pending for ${deal.id}');
      return false;
    }
    return _replaceReservation(existing, existing.quantity + 1);
  }

  Future<bool> _addFirstReservation(DealModel deal) async {
    final item = CartItemModel(deal: deal, isReservationPending: true);
    items.add(item);
    _recount();
    final operation = _beginOperation(item);

    try {
      item.reservation = await _reservationGateway.reserve(deal.id);
      if (!_isCurrent(item, operation)) {
        await _releaseQuietly(item.reservation!.id);
        return false;
      }
      item.isReservationPending = false;
      items.refresh();
      return true;
    } catch (error) {
      LogService.error('failed to reserve deal ${deal.id}', error);
      if (_isCurrent(item, operation) && items.remove(item)) _recount();
      return false;
    }
  }

  Future<bool> _replaceReservation(CartItemModel item, int quantity) async {
    final previousQuantity = item.quantity;
    final previousReservation = item.reservation;
    final operation = _beginOperation(item);
    item.quantity = quantity;
    item.isReservationPending = true;
    items.refresh();
    _recount();

    try {
      final replacement =
          await _reservationGateway.reserve(item.deal.id, quantity: quantity);
      if (!_isCurrent(item, operation)) {
        await _releaseQuietly(replacement.id);
        return false;
      }

      item.reservation = replacement;
      item.isReservationPending = false;
      items.refresh();
      if (previousReservation != null) {
        unawaited(_releaseQuietly(previousReservation.id));
      }
      return true;
    } catch (error) {
      LogService.error(
          'failed to replace reservation for ${item.deal.id}', error);
      if (_isCurrent(item, operation)) {
        item.quantity = previousQuantity;
        item.reservation = previousReservation;
        item.isReservationPending = false;
        items.refresh();
        _recount();
      }
      return false;
    }
  }

  Future<void> decrement(int dealId) async {
    final existing = items.firstWhereOrNull((i) => i.deal.id == dealId);
    if (existing == null) return;
    if (existing.isReservationPending) {
      LogService.log('cart: reservation change is already pending for $dealId');
      return;
    }
    if (existing.quantity <= 1) {
      remove(dealId);
      return;
    }
    await _replaceReservation(existing, existing.quantity - 1);
  }

  void remove(int dealId) {
    final item = items.firstWhereOrNull((i) => i.deal.id == dealId);
    if (item == null) return;
    _removeItem(item, releaseReservation: true);
  }

  void clear() {
    final removedItems = items.toList();
    for (final item in removedItems) {
      _invalidate(item);
      final reservation = item.reservation;
      if (reservation != null) unawaited(_releaseQuietly(reservation.id));
    }
    items.clear();
    _recount();
  }

  void consumeExpiryNotice(FlashSaleExpiryNotice notice) {
    expiryNotices.remove(notice);
  }

  void consumeReservationExpiryNotice(ReservationExpiryNotice notice) {
    reservationExpiryNotices.remove(notice);
  }

  num get total => items.fold(0, (sum, i) => sum + i.lineTotal);

  bool get canCheckout =>
      items.isNotEmpty &&
      items.every((item) =>
          !item.isReservationPending &&
          item.reservation != null &&
          _currentTime.toUtc().isBefore(item.reservation!.expiresAt.toUtc()));

  DateTime get _currentTime => _flashSaleClock?.currentTime.value ?? _now();

  void _expireFlashDeals() {
    final expiredItems = items
        .where((item) => FlashSaleStatus.fromEnd(item.deal.flashSaleEndsAt,
                now: _currentTime)
            .isExpired)
        .toList();
    if (expiredItems.isEmpty) return;

    for (final item in expiredItems) {
      _removeItem(item, releaseReservation: true);
      expiryNotices.add(FlashSaleExpiryNotice(
        dealId: item.deal.id,
        dealName: item.deal.name,
      ));
    }
  }

  void _expireReservations() {
    final expiredItems = items.where((item) {
      final reservation = item.reservation;
      return !item.isReservationPending &&
          reservation != null &&
          !_currentTime.toUtc().isBefore(reservation.expiresAt.toUtc());
    }).toList();
    for (final item in expiredItems) {
      _removeItem(item, releaseReservation: true);
      reservationExpiryNotices.add(ReservationExpiryNotice(
        dealId: item.deal.id,
        dealName: item.deal.name,
      ));
    }
  }

  void _removeItem(CartItemModel item, {required bool releaseReservation}) {
    _invalidate(item);
    if (!items.remove(item)) return;
    _recount();
    final reservation = item.reservation;
    if (releaseReservation && reservation != null) {
      unawaited(_releaseQuietly(reservation.id));
    }
  }

  int _beginOperation(CartItemModel item) {
    final operation = ++_nextOperationGeneration;
    _operationGenerations[item] = operation;
    return operation;
  }

  bool _isCurrent(CartItemModel item, int operation) =>
      items.contains(item) && _operationGenerations[item] == operation;

  void _invalidate(CartItemModel item) {
    _operationGenerations.remove(item);
  }

  Future<void> _releaseQuietly(String reservationId) async {
    try {
      await _reservationGateway.release(reservationId);
    } catch (error) {
      LogService.error('failed to release reservation $reservationId', error);
    }
  }

  @override
  void onClose() {
    _flashSaleClockWorker?.dispose();
    _operationGenerations.clear();
    super.onClose();
  }

  void _recount() {
    itemCount.value = items.fold(0, (sum, i) => sum + i.quantity);
  }
}
