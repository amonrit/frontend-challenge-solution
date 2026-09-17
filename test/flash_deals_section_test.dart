import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/home/widget/flash_deals_section.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/service/flash_sale_clock_service.dart';

DealModel _flashDeal(DateTime endsAt) => DealModel(
      id: 1,
      name: 'Expired flash deal',
      description: 'Test deal',
      imageUrl: 'https://example.test/deal.jpg',
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
      flashSaleEndsAt: endsAt,
    );

FlashSaleClockService _clock(DateTime Function() now) => FlashSaleClockService(
      now: now,
      periodicTimer: (_, __) => Timer(const Duration(days: 1), () {}),
    );

void main() {
  tearDown(Get.reset);

  testWidgets('renders an expired flash deal as Expired', (tester) async {
    final clock = Get.put(_clock(() => DateTime.utc(2026, 1, 1, 12)));
    addTearDown(clock.onClose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlashDealsSection(deals: [_flashDeal(DateTime.utc(2000))]),
        ),
      ),
    );

    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Ends soon'), findsNothing);
    clock.onClose();
  });

  testWidgets('renders and updates an active flash countdown', (tester) async {
    var now = DateTime.utc(2026, 1, 1, 12);
    final clock = Get.put(_clock(() => now));
    addTearDown(clock.onClose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlashDealsSection(
            deals: [_flashDeal(now.add(const Duration(seconds: 59)))],
          ),
        ),
      ),
    );

    expect(find.text('00:59'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    clock.refresh();
    await tester.pump();

    expect(find.text('00:58'), findsOneWidget);
    clock.onClose();
  });
}
