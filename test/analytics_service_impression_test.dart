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
        if (qualificationTimer == null) {
          expect(duration, const Duration(seconds: 1));
        }
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

  test('cancels qualification when visibility drops below the threshold', () {
    var now = DateTime.utc(2026, 1, 1, 12);
    _FakeTimer? qualificationTimer;
    final analytics = AnalyticsService(
      now: () => now,
      oneShotTimer: (_, callback) => qualificationTimer = _FakeTimer(callback),
    );

    analytics.observeImpression(
      observationId: 'home_feed:42:0',
      dealId: 42,
      source: 'home_feed',
      position: 0,
      visibleFraction: 0.5,
    );
    analytics.observeImpression(
      observationId: 'home_feed:42:0',
      dealId: 42,
      source: 'home_feed',
      position: 0,
      visibleFraction: 0.49,
    );

    now = now.add(const Duration(seconds: 1));
    qualificationTimer!.fire();

    expect(analytics.events, isEmpty);
  });

  test('records the first qualifying source once for a deal in the session',
      () {
    var now = DateTime.utc(2026, 1, 1, 12);
    final timers = <_FakeTimer>[];
    final analytics = AnalyticsService(
      now: () => now,
      oneShotTimer: (_, callback) {
        final timer = _FakeTimer(callback);
        timers.add(timer);
        return timer;
      },
    );

    analytics.observeImpression(
      observationId: 'home_feed:42:0',
      dealId: 42,
      source: 'home_feed',
      position: 0,
      visibleFraction: 0.5,
    );
    analytics.observeImpression(
      observationId: 'search:42:3',
      dealId: 42,
      source: 'search',
      position: 3,
      visibleFraction: 0.5,
    );

    now = now.add(const Duration(seconds: 1));
    timers.last.fire();

    expect(analytics.events, hasLength(1));
    expect(analytics.events.single.properties, {
      'deal_id': 42,
      'source': 'home_feed',
      'position': 0,
    });
  });

  test('sends ten qualifying impressions as one FIFO batch', () async {
    var now = DateTime.utc(2026, 1, 1, 12);
    final timers = <_FakeTimer>[];
    final sentBatches = <List<Map<String, dynamic>>>[];
    final analytics = AnalyticsService(
      now: () => now,
      oneShotTimer: (_, callback) {
        final timer = _FakeTimer(callback);
        timers.add(timer);
        return timer;
      },
      batchSender: (events) async => sentBatches.add(events),
    );

    for (var index = 0; index < 10; index++) {
      analytics.observeImpression(
        observationId: 'home_feed:${index + 1}:$index',
        dealId: index + 1,
        source: 'home_feed',
        position: index,
        visibleFraction: 0.5,
      );
    }

    now = now.add(const Duration(seconds: 1));
    timers.last.fire();
    await Future<void>.value();

    expect(sentBatches, hasLength(1));
    expect(
      sentBatches.single.map((event) => event['deal_id']).toList(),
      List.generate(10, (index) => index + 1),
    );
  });

  test('sends an incomplete batch fifteen seconds after its first event',
      () async {
    var now = DateTime.utc(2026, 1, 1, 12);
    final timers = <_FakeTimer>[];
    final timerDurations = <Duration>[];
    final sentBatches = <List<Map<String, dynamic>>>[];
    final analytics = AnalyticsService(
      now: () => now,
      oneShotTimer: (duration, callback) {
        timerDurations.add(duration);
        final timer = _FakeTimer(callback);
        timers.add(timer);
        return timer;
      },
      batchSender: (events) async => sentBatches.add(events),
    );

    analytics.observeImpression(
      observationId: 'search:42:0',
      dealId: 42,
      source: 'search',
      position: 0,
      visibleFraction: 0.5,
    );
    now = now.add(const Duration(seconds: 1));
    timers.last.fire();

    expect(sentBatches, isEmpty);
    expect(timerDurations.last, const Duration(seconds: 15));

    now = now.add(const Duration(seconds: 15));
    timers.last.fire();
    await Future<void>.value();

    expect(sentBatches, [
      [
        {
          'deal_id': 42,
          'source': 'search',
          'position': 0,
        }
      ]
    ]);
  });

  test(
      'keeps impressions qualified during an in-flight send for the next batch',
      () async {
    var now = DateTime.utc(2026, 1, 1, 12);
    final timers = <_FakeTimer>[];
    final sentBatches = <List<Map<String, dynamic>>>[];
    final firstSend = Completer<void>();
    final analytics = AnalyticsService(
      now: () => now,
      oneShotTimer: (_, callback) {
        final timer = _FakeTimer(callback);
        timers.add(timer);
        return timer;
      },
      batchSender: (events) {
        sentBatches.add(events);
        return sentBatches.length == 1 ? firstSend.future : Future.value();
      },
    );

    for (var index = 0; index < 10; index++) {
      analytics.observeImpression(
        observationId: 'home_feed:${index + 1}:$index',
        dealId: index + 1,
        source: 'home_feed',
        position: index,
        visibleFraction: 0.5,
      );
    }
    now = now.add(const Duration(seconds: 1));
    timers.last.fire();
    await Future<void>.value();

    analytics.observeImpression(
      observationId: 'search:11:0',
      dealId: 11,
      source: 'search',
      position: 0,
      visibleFraction: 0.5,
    );
    now = now.add(const Duration(seconds: 1));
    timers.last.fire();

    expect(sentBatches, hasLength(1));
    expect(sentBatches.single, hasLength(10));

    firstSend.complete();
    await Future<void>.value();
    await Future<void>.value();

    now = now.add(const Duration(seconds: 15));
    timers.last.fire();
    await Future<void>.value();

    expect(sentBatches, hasLength(2));
    expect(sentBatches.last.single['deal_id'], 11);
  });
}
