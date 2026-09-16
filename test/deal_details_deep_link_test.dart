import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/deal/deal_details_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/analytics_service.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/fake_api_service.dart';

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
  test('loads a deal by route id when no model argument is supplied', () async {
    Get.testMode = true;
    Get.rootController.routing.args = null;
    Get.rootController.routing.current = '/deal?id=42&source=push';
    final repo = _DeepLinkDealRepo(_deal(42));
    final controller = DealDetailsController(
      dealRepo: repo,
      cartService: CartService(),
      analytics: AnalyticsService(),
    );

    controller.onInit();
    await Future<void>.delayed(Duration.zero);

    expect(repo.requestedId, 42);
    expect(controller.deal.id, 42);
    controller.onClose();
    Get.reset();
  });
}
