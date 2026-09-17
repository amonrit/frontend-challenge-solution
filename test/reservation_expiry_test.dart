import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/cart/reservation_countdown.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/model/reservation_model.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/flash_sale_clock_service.dart';
import 'package:rescu/service/reservation_gateway.dart';

void main() {
  testWidgets('expires a confirmed reservation and releases its hold',
      (tester) async {
    var now = DateTime.utc(2026, 1, 1, 12);
    final clock = FlashSaleClockService(
      now: () => now,
      periodicTimer: (_, __) => Timer(const Duration(days: 1), () {}),
    )..onInit();
    final gateway = _ExpiryGateway(
      ReservationModel(
        id: 'expires-soon',
        dealId: 42,
        quantity: 1,
        expiresAt: now.add(const Duration(seconds: 1)),
      ),
    );
    final cart = CartService(
      reservationGateway: gateway,
      flashSaleClock: clock,
    )..onInit();

    await cart.add(_deal());
    now = now.add(const Duration(seconds: 2));
    clock.refresh();
    await tester.pump();

    expect(cart.items, isEmpty);
    expect(cart.reservationExpiryNotices, hasLength(1));
    expect(gateway.releasedIds, ['expires-soon']);

    cart.onClose();
    clock.onClose();
  });

  testWidgets('updates only reservation countdown text from the shared clock',
      (tester) async {
    var now = DateTime.utc(2026, 1, 1, 12);
    final clock = FlashSaleClockService(
      now: () => now,
      periodicTimer: (_, __) => Timer(const Duration(days: 1), () {}),
    )..onInit();
    final expiresAt = now.add(const Duration(seconds: 1));

    await tester.pumpWidget(MaterialApp(
      home: ReservationCountdown(expiresAt: expiresAt, clock: clock),
    ));
    expect(find.text('Reservation expires in 00:01'), findsOneWidget);

    now = now.add(const Duration(seconds: 2));
    clock.refresh();
    await tester.pump();

    expect(find.text('Reservation expired'), findsOneWidget);
    clock.onClose();
  });

  testWidgets(
      'a shared tick updates 100 reservation labels without rebuilding their parent',
      (tester) async {
    var now = DateTime.utc(2026, 1, 1, 12);
    var parentBuilds = 0;
    var timerCreations = 0;
    final clock = FlashSaleClockService(
      now: () => now,
      periodicTimer: (_, __) {
        timerCreations++;
        return _NoopTimer();
      },
    )..onInit();
    final expiresAt = now.add(const Duration(minutes: 1));

    await tester.pumpWidget(_ReservationCountdownFixture(
      clock: clock,
      expiresAt: expiresAt,
      onBuild: () => parentBuilds++,
    ));

    expect(timerCreations, 1);
    expect(parentBuilds, 1);
    expect(find.text('Reservation expires in 01:00'), findsNWidgets(100));

    now = now.add(const Duration(seconds: 1));
    clock.refresh();
    await tester.pump();

    expect(parentBuilds, 1);
    expect(find.text('Reservation expires in 00:59'), findsNWidgets(100));
    clock.onClose();
  });
}

class _ReservationCountdownFixture extends StatelessWidget {
  const _ReservationCountdownFixture({
    required this.clock,
    required this.expiresAt,
    required this.onBuild,
  });

  final FlashSaleClockService clock;
  final DateTime expiresAt;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return MaterialApp(
      home: SingleChildScrollView(
        child: Column(
          children: List.generate(
            100,
            (index) => ReservationCountdown(
              key: ValueKey(index),
              expiresAt: expiresAt,
              clock: clock,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoopTimer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => true;

  @override
  int get tick => 0;
}

class _ExpiryGateway implements ReservationGateway {
  _ExpiryGateway(this.reservation);

  final ReservationModel reservation;
  final releasedIds = <String>[];

  @override
  Future<ReservationModel> reserve(int dealId, {int quantity = 1}) async =>
      reservation;

  @override
  Future<void> release(String reservationId) async {
    releasedIds.add(reservationId);
  }
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
