import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/deal/deal_details_controller.dart';
import 'package:rescu/feature/deal/deal_details_screen.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/analytics_service.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/fake_api_service.dart';
import 'package:rescu/service/flash_sale_clock_service.dart';

class _UnusedDealRepo extends DealRepo {
  _UnusedDealRepo() : super(api: FakeApiService());
}

DealModel _expiredDeal() => DealModel(
      id: 1,
      name: 'Expired flash deal',
      description: 'Test deal',
      imageUrl: '',
      originalPrice: 100,
      price: 50,
      currencyCode: 'THB',
      quantityLeft: 1,
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
      flashSaleEndsAt: DateTime.utc(2000),
    );

void main() {
  tearDown(Get.reset);

  testWidgets('disables the expired detail action', (tester) async {
    Get.testMode = true;
    final deal = _expiredDeal();
    final clock = Get.put(FlashSaleClockService(
      now: () => DateTime.utc(2026, 1, 1, 12),
      periodicTimer: (_, __) => Timer(const Duration(days: 1), () {}),
    ));
    final cart = Get.put(CartService(flashSaleClock: clock));
    final controller = DealDetailsController(
      dealRepo: _UnusedDealRepo(),
      cartService: cart,
      analytics: AnalyticsService(),
    );
    Get.lazyPut(() => controller);

    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    unawaited(Get.to<void>(() => const DealDetailsScreen(), arguments: deal));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final buttonFinder = find.ancestor(
      of: find.text('Expired'),
      matching: find.byWidgetPredicate(
        (widget) => widget is ButtonStyleButton,
        description: 'a Material button',
      ),
    );
    expect(buttonFinder, findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(buttonFinder);
    expect(button.onPressed, isNull);
    expect(cart.items, isEmpty);

    controller.onClose();
    cart.onClose();
    clock.onClose();
  });
}
