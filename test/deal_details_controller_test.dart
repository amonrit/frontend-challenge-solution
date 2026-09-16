import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/deal/deal_details_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/analytics_service.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/fake_api_service.dart';

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

  setUp(() {
    Get.testMode = true;
    Get.rootController.routing.args = deal;
  });

  tearDown(Get.reset);

  test('stops refreshing availability when its controller closes', () async {
    final cart = CartService();
    final repo = _CountingDealRepo(deal);
    final controller = DealDetailsController(
      dealRepo: repo,
      cartService: cart,
      analytics: AnalyticsService(),
    )..onInit();

    cart.add(deal);
    await Future<void>.delayed(Duration.zero);
    expect(repo.fetchByIdCalls, 1);

    controller.onClose();
    cart.add(deal);
    await Future<void>.delayed(Duration.zero);

    expect(repo.fetchByIdCalls, 1);
  });
}
