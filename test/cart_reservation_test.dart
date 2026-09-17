import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/model/reservation_model.dart';
import 'package:rescu/service/api_exception.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/reservation_gateway.dart';

void main() {
  test('optimistically adds then rolls back when reservation is contested',
      () async {
    final gateway = _ControlledReservationGateway();
    final cart = CartService(reservationGateway: gateway);
    final deal = _deal();

    final add = cart.add(deal);

    expect(cart.items, hasLength(1));
    expect(cart.items.single.deal.id, deal.id);

    gateway.reserveResult.completeError(const ApiException(
      'Could not reserve: someone grabbed the last one. Try again.',
      statusCode: 409,
    ));
    await add;

    expect(cart.items, isEmpty);
    expect(cart.itemCount.value, 0);
  });
}

class _ControlledReservationGateway implements ReservationGateway {
  final reserveResult = Completer<ReservationModel>();

  @override
  Future<ReservationModel> reserve(int dealId, {int quantity = 1}) =>
      reserveResult.future;

  @override
  Future<void> release(String reservationId) async {}
}

DealModel _deal() => DealModel(
      id: 42,
      name: 'Reserved deal',
      description: 'Test deal',
      imageUrl: '',
      originalPrice: 100,
      price: 50,
      currencyCode: 'THB',
      quantityLeft: 2,
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
      flashSaleEndsAt: null,
    );
