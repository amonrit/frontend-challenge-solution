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

    final firstReservation = _reservation('first', quantity: 1);
    gateway.reserveResults[0].complete(firstReservation);
    await firstAdd;

    expect(cart.items, hasLength(1));
    expect(cart.items.single.reservation, isNull);
    expect(gateway.releasedIds, [firstReservation.id]);

    final secondReservation = _reservation('second', quantity: 1);
    gateway.reserveResults[1].complete(secondReservation);
    await secondAdd;

    expect(cart.items, hasLength(1));
    expect(cart.items.single.reservation?.id, secondReservation.id);
  });

  test('replaces a hold before releasing the old hold for an increment',
      () async {
    final gateway = _ControlledReservationGateway();
    final cart = CartService(reservationGateway: gateway);
    final deal = _deal();

    final firstAdd = cart.add(deal);
    final original = _reservation('original', quantity: 1);
    gateway.reserveResults[0].complete(original);
    await firstAdd;

    final increment = cart.add(deal);

    expect(cart.items.single.quantity, 2);
    expect(gateway.releasedIds, isEmpty);

    final replacement = _reservation('replacement', quantity: 2);
    gateway.reserveResults[1].complete(replacement);
    await increment;

    expect(cart.items.single.quantity, 2);
    expect(cart.items.single.reservation?.id, replacement.id);
    expect(gateway.releasedIds, [original.id]);
  });

  test('restores the original hold when an increment replacement is contested',
      () async {
    final gateway = _ControlledReservationGateway();
    final cart = CartService(reservationGateway: gateway);
    final deal = _deal();

    final firstAdd = cart.add(deal);
    final original = _reservation('original', quantity: 1);
    gateway.reserveResults[0].complete(original);
    await firstAdd;

    final increment = cart.add(deal);
    gateway.reserveResults[1].completeError(const ApiException(
      'Could not reserve: someone grabbed the last one. Try again.',
      statusCode: 409,
    ));
    await increment;

    expect(cart.items.single.quantity, 1);
    expect(cart.items.single.reservation?.id, original.id);
    expect(gateway.releasedIds, isEmpty);
  });

  test('does not start a second replacement while the first is pending',
      () async {
    final gateway = _ControlledReservationGateway();
    final cart = CartService(reservationGateway: gateway);
    final deal = _deal(quantityLeft: 3);

    final firstAdd = cart.add(deal);
    gateway.reserveResults[0].complete(_reservation('original', quantity: 1));
    await firstAdd;

    final firstIncrement = cart.add(deal);
    final secondIncrement = cart.add(deal);

    expect(cart.items.single.quantity, 2);
    expect(gateway.reserveResults, hasLength(2));

    gateway.reserveResults[1]
        .complete(_reservation('replacement', quantity: 2));
    await firstIncrement;
    expect(await secondIncrement, isFalse);
  });

  test('replaces a two-unit hold before releasing it for a decrement',
      () async {
    final gateway = _ControlledReservationGateway();
    final cart = CartService(reservationGateway: gateway);
    final deal = _deal(quantityLeft: 3);

    final firstAdd = cart.add(deal);
    final original = _reservation('original', quantity: 1);
    gateway.reserveResults[0].complete(original);
    await firstAdd;

    final increment = cart.add(deal);
    final twoUnits = _reservation('two-units', quantity: 2);
    gateway.reserveResults[1].complete(twoUnits);
    await increment;

    final decrement = cart.decrement(deal.id);

    expect(cart.items.single.quantity, 1);
    final oneUnit = _reservation('one-unit', quantity: 1);
    gateway.reserveResults[2].complete(oneUnit);
    await decrement;

    expect(cart.items.single.quantity, 1);
    expect(cart.items.single.reservation?.id, oneUnit.id);
    expect(gateway.releasedIds, [original.id, twoUnits.id]);
  });

  test('releases a confirmed hold when its line is removed', () async {
    final gateway = _ControlledReservationGateway();
    final cart = CartService(reservationGateway: gateway);
    final deal = _deal();

    final add = cart.add(deal);
    final reservation = _reservation('confirmed', quantity: 1);
    gateway.reserveResults.single.complete(reservation);
    await add;

    cart.remove(deal.id);

    expect(cart.items, isEmpty);
    expect(gateway.releasedIds, [reservation.id]);
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

ReservationModel _reservation(String id, {required int quantity}) =>
    ReservationModel(
      id: id,
      dealId: 42,
      quantity: quantity,
      expiresAt: DateTime.utc(2026, 1, 1, 12, 5),
    );

DealModel _deal({int quantityLeft = 2}) => DealModel(
      id: 42,
      name: 'Reserved deal',
      description: 'Test deal',
      imageUrl: '',
      originalPrice: 100,
      price: 50,
      currencyCode: 'THB',
      quantityLeft: quantityLeft,
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
