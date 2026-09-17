import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/main.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/flash_sale_clock_service.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('registers the non-null flash-sale clock before the cart',
      (tester) async {
    Get.testMode = true;

    await initDependencies();

    expect(Get.isRegistered<FlashSaleClockService>(), isTrue);
    expect(Get.find<CartService>(), isNotNull);

    Get.delete<CartService>(force: true);
    Get.delete<FlashSaleClockService>(force: true);
    Get.reset();
  });
}
