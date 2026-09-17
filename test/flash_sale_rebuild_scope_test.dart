import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/shared_widget/flash_sale_countdown.dart';
import 'package:rescu/service/flash_sale_clock_service.dart';

class _FakeTimer implements Timer {
  bool cancelled = false;

  @override
  void cancel() {
    cancelled = true;
  }

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}

class _CountdownFixture extends StatelessWidget {
  const _CountdownFixture({
    required this.clock,
    required this.endsAt,
    required this.onBuild,
  });

  final FlashSaleClockService clock;
  final DateTime endsAt;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SingleChildScrollView(
        child: Column(
          children: List.generate(
            100,
            (index) => FlashSaleCountdown(
              key: ValueKey(index),
              clock: clock,
              endsAt: endsAt,
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
      'a shared tick updates 100 labels without rebuilding their parent',
      (tester) async {
    var now = DateTime.utc(2026, 1, 1, 12);
    var timerCreations = 0;
    var parentBuilds = 0;
    _FakeTimer? timer;
    final clock = FlashSaleClockService(
      now: () => now,
      periodicTimer: (_, __) {
        timerCreations++;
        return timer = _FakeTimer();
      },
    )..onInit();

    await tester.pumpWidget(_CountdownFixture(
      clock: clock,
      endsAt: now.add(const Duration(minutes: 1)),
      onBuild: () => parentBuilds++,
    ));

    expect(timerCreations, 1);
    expect(parentBuilds, 1);
    expect(find.text('01:00'), findsNWidgets(100));

    now = now.add(const Duration(seconds: 1));
    clock.refresh();
    await tester.pump();

    expect(parentBuilds, 1);
    expect(find.text('00:59'), findsNWidgets(100));

    await tester.pumpWidget(const SizedBox());
    clock.onClose();
    expect(timer!.cancelled, isTrue);

    now = now.add(const Duration(seconds: 1));
    clock.refresh();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
