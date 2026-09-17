import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/deal/deal_details_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/analytics_service.dart';
import 'package:rescu/service/api_exception.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/fake_api_service.dart';

import 'support/immediate_reservation_gateway.dart';

class _DeepLinkDealRepo extends DealRepo {
  _DeepLinkDealRepo(this.loadedDeal) : super(api: FakeApiService());

  final DealModel loadedDeal;
  int? requestedId;

  @override
  Future<DealModel> fetchById(int id) async {
    requestedId = id;
    return loadedDeal;
  }
}

class _FailingDealRepo extends DealRepo {
  _FailingDealRepo() : super(api: FakeApiService());

  @override
  Future<DealModel> fetchById(int id) async {
    throw const ApiException('Deal not found', statusCode: 404);
  }
}

DealModel _deal(int id) {
  return DealModel(
    id: id,
    name: 'Deep-link deal',
    description: '',
    imageUrl: '',
    originalPrice: 100,
    price: 50,
    currencyCode: 'THB',
    quantityLeft: 5,
    storeId: id,
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
}

void main() {
  tearDown(Get.reset);

  test('loads a deal by route id when no model argument is supplied', () async {
    Get.testMode = true;
    Get.rootController.routing.args = null;
    Get.rootController.routing.current = '/deal?id=42&source=push';
    final repo = _DeepLinkDealRepo(_deal(42));
    final controller = DealDetailsController(
      dealRepo: repo,
      cartService:
          CartService(reservationGateway: ImmediateReservationGateway()),
      analytics: AnalyticsService(),
    );

    controller.onInit();
    await Future<void>.delayed(Duration.zero);

    expect(repo.requestedId, 42);
    expect(controller.deal.id, 42);
    controller.onClose();
  });

  test('preserves the deep-link source when route parameters are unavailable',
      () async {
    Get.testMode = true;
    Get.rootController.routing.args = null;
    Get.rootController.routing.current = '/deal?id=42&source=push';
    final analytics = AnalyticsService();
    final controller = DealDetailsController(
      dealRepo: _DeepLinkDealRepo(_deal(42)),
      cartService:
          CartService(reservationGateway: ImmediateReservationGateway()),
      analytics: analytics,
    );

    controller.onInit();
    await Future<void>.delayed(Duration.zero);

    final event = analytics.events.singleWhere(
      (event) => event.name == 'deal_details_view',
    );
    expect(event.properties['source'], 'push');
    controller.onClose();
  });

  test('maps an invalid route id to an error without fetching', () {
    Get.testMode = true;
    Get.rootController.routing.args = null;
    Get.rootController.routing.current = '/deal?id=not-a-number';
    final repo = _DeepLinkDealRepo(_deal(42));
    final controller = DealDetailsController(
      dealRepo: repo,
      cartService:
          CartService(reservationGateway: ImmediateReservationGateway()),
      analytics: AnalyticsService(),
    )..onInit();

    expect(controller.errorMessage.value, 'This deal link is invalid.');
    expect(repo.requestedId, isNull);
    controller.onClose();
  });

  test('maps repository failures to a retryable error state', () async {
    Get.testMode = true;
    Get.rootController.routing.args = null;
    Get.rootController.routing.current = '/deal?id=42';
    final controller = DealDetailsController(
      dealRepo: _FailingDealRepo(),
      cartService:
          CartService(reservationGateway: ImmediateReservationGateway()),
      analytics: AnalyticsService(),
    )..onInit();

    await Future<void>.delayed(Duration.zero);

    expect(controller.loadedDeal, isNull);
    expect(controller.isLoading.value, isFalse);
    expect(controller.errorMessage.value,
        'Unable to load this deal. Please try again.');
    controller.onClose();
  });
}
