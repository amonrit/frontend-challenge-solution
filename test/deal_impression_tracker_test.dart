import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/shared_widget/deal_impression_tracker.dart';
import 'package:rescu/service/analytics_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

class _FakeTimer implements Timer {
  _FakeTimer(this._callback);

  final void Function() _callback;
  bool cancelled = false;

  void fire() {
    if (!cancelled) _callback();
  }

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}

VisibilityInfo _halfVisible(VisibilityDetector detector) => VisibilityInfo(
      key: detector.key!,
      size: const Size(100, 100),
      visibleBounds: const Rect.fromLTWH(0, 0, 50, 100),
    );

void main() {
  testWidgets(
      'forwards a qualified card observation with its source and position',
      (tester) async {
    var now = DateTime.utc(2026, 1, 1, 12);
    _FakeTimer? timer;
    final analytics = AnalyticsService(
      now: () => now,
      oneShotTimer: (_, callback) => timer = _FakeTimer(callback),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DealImpressionTracker(
          analytics: analytics,
          dealId: 42,
          source: 'search',
          position: 3,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );

    final detector = tester.widget<VisibilityDetector>(
      find.byType(VisibilityDetector),
    );
    expect(detector.key, const ValueKey('impression:search:42:3'));
    detector.onVisibilityChanged!(_halfVisible(detector));

    now = now.add(const Duration(seconds: 1));
    timer!.fire();

    expect(analytics.events.single.properties, {
      'deal_id': 42,
      'source': 'search',
      'position': 3,
    });
  });

  testWidgets('ends an observation when its card is disposed', (tester) async {
    var now = DateTime.utc(2026, 1, 1, 12);
    _FakeTimer? timer;
    final analytics = AnalyticsService(
      now: () => now,
      oneShotTimer: (_, callback) => timer = _FakeTimer(callback),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DealImpressionTracker(
          analytics: analytics,
          dealId: 42,
          source: 'home_feed',
          position: 0,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    final detector = tester.widget<VisibilityDetector>(
      find.byType(VisibilityDetector),
    );
    detector.onVisibilityChanged!(_halfVisible(detector));

    await tester.pumpWidget(const SizedBox());
    now = now.add(const Duration(seconds: 1));
    timer!.fire();

    expect(analytics.events, isEmpty);
  });
}
