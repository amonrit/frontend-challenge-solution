import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/shared_widget/deal_card.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/service/flash_sale_clock_service.dart';

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

  testWidgets('renders an expired Home card as disabled', (tester) async {
    final clock = Get.put(FlashSaleClockService(
      now: () => DateTime.utc(2026, 1, 1, 12),
      periodicTimer: (_, __) => Timer(const Duration(days: 1), () {}),
    ));
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: DealCard(deal: _expiredDeal()))),
    );

    expect(find.text('Expired'), findsOneWidget);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    clock.onClose();
  });
}
