import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/deal/deal_details_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/analytics_service.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/fake_api_service.dart';

import 'support/immediate_reservation_gateway.dart';

class _CountingDealRepo extends DealRepo {
  _CountingDealRepo(this.deal) : super(api: FakeApiService());

  final DealModel deal;
  int fetchByIdCalls = 0;

  @override
  Future<DealModel> fetchById(int id) async {
    fetchByIdCalls++;
    return deal;
  }
}

class _DelayedDealRepo extends DealRepo {
  _DelayedDealRepo() : super(api: FakeApiService());

  final response = Completer<DealModel>();

  @override
  Future<DealModel> fetchById(int id) => response.future;
}

void main() {
  final deal = DealModel(
    id: 1,
    name: 'Test deal',
    description: '',
    imageUrl: '',
    originalPrice: 100,
    price: 50,
    currencyCode: 'THB',
    quantityLeft: 5,
    storeId: 1,
    storeName: 'Test store',
    storeAddress: '',
    lat: 0,
    lng: 0,
    rating: null,
    tags: [],
    pickupWindow: PickupWindowModel(
      start: DateTime(2026, 1, 1, 12),
      end: DateTime(2026, 1, 1, 13),
    ),
    flashSaleEndsAt: null,
  );

  final secondDeal = DealModel(
    id: 2,
    name: 'Second test deal',
    description: '',
    imageUrl: '',
    originalPrice: 100,
    price: 50,
    currencyCode: 'THB',
    quantityLeft: 0,
    storeId: 2,
    storeName: 'Second test store',
    storeAddress: '',
    lat: 0,
    lng: 0,
    rating: null,
    tags: [],
    pickupWindow: PickupWindowModel(
      start: DateTime(2026, 1, 1, 12),
      end: DateTime(2026, 1, 1, 13),
    ),
    flashSaleEndsAt: null,
  );

  setUp(() {
    Get.testMode = true;
    Get.rootController.routing.args = deal;
  });

  tearDown(Get.reset);

  test('uses the supplied model without an initial repository fetch', () {
    final repo = _CountingDealRepo(deal);
    final controller = DealDetailsController(
      dealRepo: repo,
      cartService:
          CartService(reservationGateway: ImmediateReservationGateway()),
      analytics: AnalyticsService(),
    )..onInit();

    expect(controller.deal.id, deal.id);
    expect(repo.fetchByIdCalls, 0);
    controller.onClose();
  });

  test('stops refreshing availability when its controller closes', () async {
    final cart = CartService(reservationGateway: ImmediateReservationGateway());
    final repo = _CountingDealRepo(deal);
    final controller = DealDetailsController(
      dealRepo: repo,
      cartService: cart,
      analytics: AnalyticsService(),
    )..onInit();

    await cart.add(deal);
    await Future<void>.delayed(Duration.zero);
    expect(repo.fetchByIdCalls, 1);

    controller.onClose();
    await cart.add(deal);
    await Future<void>.delayed(Duration.zero);

    expect(repo.fetchByIdCalls, 1);
  });

  test('keeps a different live controller subscribed after another closes',
      () async {
    final cart = CartService(reservationGateway: ImmediateReservationGateway());
    final firstRepo = _CountingDealRepo(deal);
    final secondRepo = _CountingDealRepo(secondDeal);

    Get.rootController.routing.args = deal;
    final firstController = DealDetailsController(
      dealRepo: firstRepo,
      cartService: cart,
      analytics: AnalyticsService(),
    )..onInit();

    Get.rootController.routing.args = secondDeal;
    final secondController = DealDetailsController(
      dealRepo: secondRepo,
      cartService: cart,
      analytics: AnalyticsService(),
    )..onInit();

    firstController.onClose();
    await cart.add(deal);
    await Future<void>.delayed(Duration.zero);

    expect(firstRepo.fetchByIdCalls, 0);
    expect(secondRepo.fetchByIdCalls, 1);

    secondController.onClose();
  });

  test('ignores an availability response that finishes after close', () async {
    final cart = CartService(reservationGateway: ImmediateReservationGateway());
    final repo = _DelayedDealRepo();
    final controller = DealDetailsController(
      dealRepo: repo,
      cartService: cart,
      analytics: AnalyticsService(),
    )..onInit();

    await cart.add(deal);
    await Future<void>.delayed(Duration.zero);
    controller.onClose();

    repo.response.complete(secondDeal);
    await Future<void>.delayed(Duration.zero);

    expect(controller.quantityLeft, deal.quantityLeft);
  });
}
