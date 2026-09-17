import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/flash_sale_clock_service.dart';

import 'support/immediate_reservation_gateway.dart';

DealModel _flashDeal(DateTime endsAt) => DealModel(
      id: 1,
      name: 'Flash deal',
      description: 'Test deal',
      imageUrl: '',
      originalPrice: 100,
      price: 50,
      currencyCode: 'THB',
      quantityLeft: 3,
      storeId: 1,
      storeName: 'Test store',
      storeAddress: 'Address',
      lat: 13.75,
      lng: 100.5,
      rating: null,
      tags: const [],
      pickupWindow: PickupWindowModel(
        start: DateTime.utc(2026, 1, 1, 12),
        end: DateTime.utc(2026, 1, 1, 13),
      ),
      flashSaleEndsAt: endsAt,
    );

void main() {
  testWidgets('rejects an already-expired deal at the cart mutation boundary',
      (tester) async {
    final now = DateTime.utc(2026, 1, 1, 12);
    final clock = FlashSaleClockService(
      now: () => now,
      periodicTimer: (_, __) => Timer(const Duration(days: 1), () {}),
    )..onInit();
    final cart = CartService(
      reservationGateway: ImmediateReservationGateway(),
      flashSaleClock: clock,
    )..onInit();

    expect(await cart.add(_flashDeal(now.subtract(const Duration(seconds: 1)))),
        isFalse);
    expect(cart.items, isEmpty);

    cart.onClose();
    clock.onClose();
  });

  testWidgets('removes an expired cart line once and queues one notice',
      (tester) async {
    var now = DateTime.utc(2026, 1, 1, 12);
    final clock = FlashSaleClockService(
      now: () => now,
      periodicTimer: (_, __) => Timer(const Duration(days: 1), () {}),
    )..onInit();
    final cart = CartService(
      reservationGateway: ImmediateReservationGateway(),
      flashSaleClock: clock,
    )..onInit();
    final deal = _flashDeal(now.add(const Duration(seconds: 1)));

    expect(await cart.add(deal), isTrue);
    expect(await cart.add(deal), isTrue);
    expect(await cart.add(deal), isTrue);

    now = now.add(const Duration(seconds: 2));
    clock.refresh();
    await tester.pump();

    expect(cart.items, isEmpty);
    expect(cart.itemCount.value, 0);
    expect(cart.expiryNotices, hasLength(1));
    expect(cart.expiryNotices.single.dealId, deal.id);

    clock.refresh();
    await tester.pump();
    expect(cart.expiryNotices, hasLength(1));

    cart.onClose();
    clock.onClose();
  });
}
