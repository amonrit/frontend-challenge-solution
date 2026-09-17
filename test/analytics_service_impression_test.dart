import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/service/analytics_service.dart';

class _FakeTimer implements Timer {
  _FakeTimer(this._callback);

  final void Function() _callback;
  bool cancelled = false;

  void fire() {
    if (!cancelled) _callback();
  }

  @override
  void cancel() {
    cancelled = true;
  }

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}

void main() {
  test('records one deal impression after one continuous visible second', () {
    var now = DateTime.utc(2026, 1, 1, 12);
    _FakeTimer? qualificationTimer;
    final analytics = AnalyticsService(
      now: () => now,
      oneShotTimer: (duration, callback) {
        expect(duration, const Duration(seconds: 1));
        return qualificationTimer = _FakeTimer(callback);
      },
    );

    analytics.observeImpression(
      observationId: 'home_feed:42:0',
      dealId: 42,
      source: 'home_feed',
      position: 0,
      visibleFraction: 0.5,
    );

    expect(analytics.events, isEmpty);

    now = now.add(const Duration(seconds: 1));
    qualificationTimer!.fire();

    expect(analytics.events, hasLength(1));
    expect(analytics.events.single.name, 'deal_impression');
    expect(analytics.events.single.properties, {
      'deal_id': 42,
      'source': 'home_feed',
      'position': 0,
    });
  });
}
