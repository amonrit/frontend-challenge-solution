import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/cart/cart_controller.dart';
import 'package:rescu/model/cart_item_model.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/order_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/model/reservation_model.dart';
import 'package:rescu/repository/order_repo.dart';
import 'package:rescu/service/api_exception.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/fake_api_service.dart';

import 'support/immediate_reservation_gateway.dart';

void main() {
  test('410 clears the submitted cart and explains the recovery', () async {
    final cart = _cart();
    final messages = <String>[];
    final controller = CartController(
      cartService: cart,
      orderRepo: _FailingCheckoutRepo(410),
      showMessage: (title, message) => messages.add('$title|$message'),
    );

    await controller.checkout();

    expect(cart.items, isEmpty);
    expect(controller.isCheckingOut.value, isFalse);
    expect(messages.single, contains('Reservation expired'));
  });

  test('502 preserves confirmed holds for a user retry', () async {
    final cart = _cart();
    final controller = CartController(
      cartService: cart,
      orderRepo: _FailingCheckoutRepo(502),
      showMessage: (_, __) {},
    );

    await controller.checkout();

    expect(cart.items, hasLength(1));
    expect(cart.items.single.reservation?.id, 'confirmed');
    expect(controller.isCheckingOut.value, isFalse);
  });
}

CartService _cart() {
  final cart = CartService(reservationGateway: ImmediateReservationGateway());
  cart.items.add(CartItemModel(deal: _deal(), reservation: _reservation()));
  cart.itemCount.value = 1;
  return cart;
}

class _FailingCheckoutRepo extends OrderRepo {
  _FailingCheckoutRepo(this.statusCode) : super(api: FakeApiService());

  final int statusCode;

  @override
  Future<OrderModel> checkout(List<CartItemModel> items) async =>
      throw ApiException('checkout failed', statusCode: statusCode);
}

ReservationModel _reservation() => ReservationModel(
    id: 'confirmed', dealId: 42, quantity: 1, expiresAt: DateTime.utc(2030));

DealModel _deal() => DealModel(
      id: 42,
      name: 'Deal',
      description: '',
      imageUrl: '',
      originalPrice: 100,
      price: 50,
      currencyCode: 'THB',
      quantityLeft: 1,
      storeId: 1,
      storeName: 'Store',
      storeAddress: '',
      lat: 0,
      lng: 0,
      rating: null,
      tags: const [],
      pickupWindow: PickupWindowModel(
          start: DateTime.utc(2026), end: DateTime.utc(2026, 1, 1, 1)),
      flashSaleEndsAt: null,
    );
