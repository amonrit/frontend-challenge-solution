import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/home/widget/home_feed_list.dart';
import 'package:rescu/feature/shared_widget/deal_card.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';

DealModel _deal(int id) => DealModel(
      id: id,
      name: 'Deal $id',
      description: 'Test deal',
      imageUrl: 'https://example.test/$id.jpg',
      originalPrice: 100,
      price: 50,
      currencyCode: 'THB',
      quantityLeft: 1,
      storeId: id,
      storeName: 'Store $id',
      storeAddress: 'Address',
      lat: 13.75,
      lng: 100.5,
      rating: null,
      tags: const [],
      pickupWindow: PickupWindowModel(
        start: DateTime(2026, 1, 1, 12),
        end: DateTime(2026, 1, 1, 13),
      ),
      flashSaleEndsAt: null,
    );

void main() {
  testWidgets('builds only a viewport-sized subset of a large feed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeFeedList(
            deals: List.generate(100, _deal),
            flashDeals: const [],
            todayOnly: false,
            onTodayChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(DealCard).evaluate().length, lessThan(100));
  });
}
