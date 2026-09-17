import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/service/flash_sale_clock_service.dart';

class _FakeTimer implements Timer {
  bool cancelled = false;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;

  @override
  void cancel() {
    cancelled = true;
  }
}

void main() {
  testWidgets('owns one periodic timer and cancels it on close',
      (tester) async {
    var timerCreations = 0;
    _FakeTimer? timer;
    final service = FlashSaleClockService(
      now: () => DateTime.utc(2026, 1, 1, 12),
      periodicTimer: (duration, _) {
        timerCreations++;
        expect(duration, const Duration(seconds: 1));
        return timer = _FakeTimer();
      },
    );

    service.onInit();

    expect(timerCreations, 1);
    expect(service.currentTime.value, DateTime.utc(2026, 1, 1, 12));

    service.onClose();

    expect(timer, isNotNull);
    expect(timer!.cancelled, isTrue);
  });

  testWidgets('refreshes its clock immediately when the app resumes',
      (tester) async {
    var currentTime = DateTime.utc(2026, 1, 1, 12);
    final service = FlashSaleClockService(
      now: () => currentTime,
      periodicTimer: (_, __) => _FakeTimer(),
    );
    service.onInit();

    currentTime = currentTime.add(const Duration(minutes: 5));
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(service.currentTime.value, currentTime);
    service.onClose();
  });
}
