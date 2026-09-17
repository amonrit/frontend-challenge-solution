import 'package:get/get.dart';

import '../model/cart_item_model.dart';
import '../model/deal_model.dart';
import '../model/flash_sale_status.dart';
import '../util/log_service.dart';
import 'flash_sale_clock_service.dart';

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
    FlashSaleClockService? flashSaleClock,
    DateTime Function()? now,
  })  : _flashSaleClock = flashSaleClock,
        _now = now ?? DateTime.now;

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

  bool add(DealModel deal) {
    if (FlashSaleStatus.fromEnd(deal.flashSaleEndsAt, now: _currentTime)
        .isExpired) {
      LogService.log('cart: cannot add expired deal ${deal.id}');
      return false;
    }

    final existing = items.firstWhereOrNull((i) => i.deal.id == deal.id);
    if (existing != null) {
      if (existing.quantity >= deal.quantityLeft) {
        LogService.log('cart: cannot add more of deal ${deal.id}');
        return false;
      }
      existing.quantity++;
      items.refresh();
    } else {
      items.add(CartItemModel(deal: deal));
    }
    _recount();
    return true;
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
