import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/home/home_controller.dart';
import 'package:rescu/feature/home/home_screen.dart';
import 'package:rescu/feature/home/widget/home_feed_list.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/paged_response_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/fake_api_service.dart';

class _ImmediateHomeRepo extends DealRepo {
  _ImmediateHomeRepo() : super(api: FakeApiService());

  @override
  Future<PagedResponseModel<DealModel>> fetchDeals({int page = 1}) async {
    return PagedResponseModel(items: [_deal], page: page, totalPages: 1);
  }

  @override
  Future<List<DealModel>> fetchFlashDeals() async => const [];
}

final _deal = DealModel(
  id: 1,
  name: 'Test deal',
  description: '',
  imageUrl: '',
  originalPrice: 100,
  price: 50,
  currencyCode: 'THB',
  quantityLeft: 1,
  storeId: 1,
  storeName: 'Test store',
  storeAddress: '',
  lat: 0,
  lng: 0,
  rating: null,
  tags: const [],
  pickupWindow: PickupWindowModel(
    start: DateTime(2026, 1, 1, 12),
    end: DateTime(2026, 1, 1, 13),
  ),
  flashSaleEndsAt: null,
);

void main() {
  tearDown(Get.reset);

  testWidgets('scroll state does not rebuild the Home feed', (tester) async {
    Get.testMode = true;
    final controller = Get.put(HomeController(dealRepo: _ImmediateHomeRepo()));

    await tester.pumpWidget(const GetMaterialApp(home: HomeScreen()));
    await tester.pump();

    final feedFinder = find.byType(HomeFeedList);
    expect(feedFinder, findsOneWidget);
    final feedBeforeScroll = feedFinder.evaluate().single.widget;

    controller.scrollOffset.value = 900;
    await tester.pump();

    expect(identical(feedFinder.evaluate().single.widget, feedBeforeScroll),
        isTrue);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    controller.todayOnly.value = true;
    await tester.pump();

    expect(identical(feedFinder.evaluate().single.widget, feedBeforeScroll),
        isFalse);
  });
}
