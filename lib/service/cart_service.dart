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

  final items = <CartItemModel>[].obs;
  final itemCount = 0.obs;
  final expiryNotices = <FlashSaleExpiryNotice>[].obs;

  @override
  void onInit() {
    super.onInit();
    final clock = _flashSaleClock;
    if (clock != null) {
      _flashSaleClockWorker =
          ever(clock.currentTime, (_) => _expireFlashDeals());
    }
  }

  Future<bool> add(DealModel deal) async {
    if (FlashSaleStatus.fromEnd(deal.flashSaleEndsAt, now: _currentTime)
        .isExpired) {
      LogService.log('cart: cannot add expired deal ${deal.id}');
      return false;
    }

    final existing = items.firstWhereOrNull((i) => i.deal.id == deal.id);
    if (existing != null) {
      LogService.log(
          'cart: quantity replacement is not available yet for ${deal.id}');
      return false;
    }

    final item = CartItemModel(deal: deal);
    items.add(item);
    _recount();

    try {
      item.reservation = await _reservationGateway.reserve(deal.id);
      if (!items.contains(item)) {
        await _reservationGateway.release(item.reservation!.id);
        return false;
      }
      items.refresh();
      return true;
    } catch (error) {
      LogService.error('failed to reserve deal ${deal.id}', error);
      if (items.remove(item)) _recount();
      return false;
    }
  }

  void decrement(int dealId) {
    final existing = items.firstWhereOrNull((i) => i.deal.id == dealId);
    if (existing == null) return;
    existing.quantity--;
    if (existing.quantity <= 0) {
      items.removeWhere((i) => i.deal.id == dealId);
    } else {
      items.refresh();
    }
    _recount();
  }

  void remove(int dealId) {
    items.removeWhere((i) => i.deal.id == dealId);
    _recount();
  }

  void clear() {
    items.clear();
    _recount();
  }

  void consumeExpiryNotice(FlashSaleExpiryNotice notice) {
    expiryNotices.remove(notice);
  }

  num get total => items.fold(0, (sum, i) => sum + i.lineTotal);

  DateTime get _currentTime => _flashSaleClock?.currentTime.value ?? _now();

  void _expireFlashDeals() {
    final expiredItems = items
        .where((item) => FlashSaleStatus.fromEnd(item.deal.flashSaleEndsAt,
                now: _currentTime)
            .isExpired)
        .toList();
    if (expiredItems.isEmpty) return;

    final expiredIds = expiredItems.map((item) => item.deal.id).toSet();
    items.removeWhere((item) => expiredIds.contains(item.deal.id));
    _recount();
    for (final item in expiredItems) {
      expiryNotices.add(FlashSaleExpiryNotice(
        dealId: item.deal.id,
        dealName: item.deal.name,
      ));
    }
  }

  @override
  void onClose() {
    _flashSaleClockWorker?.dispose();
    super.onClose();
  }

  void _recount() {
    itemCount.value = items.fold(0, (sum, i) => sum + i.quantity);
  }
}
