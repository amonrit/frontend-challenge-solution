import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/home/widget/flash_deals_section.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';

DealModel _expiredFlashDeal() => DealModel(
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
      flashSaleEndsAt: DateTime.utc(2000),
    );

void main() {
  testWidgets('renders an expired flash deal as Expired', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlashDealsSection(deals: [_expiredFlashDeal()]),
        ),
      ),
    );

    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Ends soon'), findsNothing);
  });
}
