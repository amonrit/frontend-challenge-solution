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

    gateway.reserveResults.single.completeError(const ApiException(
      'Could not reserve: someone grabbed the last one. Try again.',
      statusCode: 409,
    ));
    await add;

    expect(cart.items, isEmpty);
    expect(cart.itemCount.value, 0);
  });

  test('releases a stale hold without changing a replacement line', () async {
    final gateway = _ControlledReservationGateway();
    final cart = CartService(reservationGateway: gateway);
    final deal = _deal();

    final firstAdd = cart.add(deal);
    cart.remove(deal.id);
    final secondAdd = cart.add(deal);

    final firstReservation = _reservation('first');
    gateway.reserveResults[0].complete(firstReservation);
    await firstAdd;

    expect(cart.items, hasLength(1));
    expect(cart.items.single.reservation, isNull);
    expect(gateway.releasedIds, [firstReservation.id]);

    final secondReservation = _reservation('second');
    gateway.reserveResults[1].complete(secondReservation);
    await secondAdd;

    expect(cart.items, hasLength(1));
    expect(cart.items.single.reservation?.id, secondReservation.id);
  });
}

class _ControlledReservationGateway implements ReservationGateway {
  final reserveResults = <Completer<ReservationModel>>[];
  final releasedIds = <String>[];

  @override
  Future<ReservationModel> reserve(int dealId, {int quantity = 1}) {
    final result = Completer<ReservationModel>();
    reserveResults.add(result);
    return result.future;
  }

  @override
  Future<void> release(String reservationId) async {
    releasedIds.add(reservationId);
  }
}

ReservationModel _reservation(String id) => ReservationModel(
      id: id,
      dealId: 42,
      quantity: 1,
      expiresAt: DateTime.utc(2026, 1, 1, 12, 5),
    );

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
