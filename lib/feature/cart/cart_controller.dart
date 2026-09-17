import 'package:get/get.dart';

import '../../repository/order_repo.dart';
import '../../service/api_exception.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class CartController extends GetxController {
  final CartService cartService;
  final OrderRepo orderRepo;
  final void Function(String title, String message)? _showMessage;

  CartController({
    required this.cartService,
    required this.orderRepo,
    void Function(String title, String message)? showMessage,
  }) : _showMessage = showMessage;

  final isCheckingOut = false.obs;

  Future<void> checkout() async {
    if (cartService.items.isEmpty || isCheckingOut.value) return;
    if (!cartService.canCheckout) {
      _message('Reservation required',
          'Wait for every item to reserve, or add expired items again.');
      return;
    }
    isCheckingOut.value = true;
    try {
      final order = await orderRepo.checkout(cartService.items.toList());
      cartService.clear();
      _message('Order confirmed', 'Order #${order.id} — pick up soon!');
    } on ApiException catch (e) {
      LogService.error('checkout failed', e);
      if (e.statusCode == 410) {
        cartService.clear();
        _message('Reservation expired',
            'One or more holds expired. Please add your items again.');
      } else {
        _message('Checkout failed', e.message);
      }
    } finally {
      isCheckingOut.value = false;
    }
  }

  void _message(String title, String message) {
    final showMessage = _showMessage;
    if (showMessage != null) {
      showMessage(title, message);
      return;
    }
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }
}
