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

  testWidgets(
      '100 visibility callbacks use one active qualification timer without rebuilding the parent',
      (tester) async {
    var now = DateTime.utc(2026, 1, 1, 12);
    var parentBuilds = 0;
    final timers = <_FakeTimer>[];
    final analytics = AnalyticsService(
      now: () => now,
      oneShotTimer: (_, callback) {
        final timer = _FakeTimer(callback);
        timers.add(timer);
        return timer;
      },
    );

    await tester.pumpWidget(_TrackerFixture(
      analytics: analytics,
      onBuild: () => parentBuilds++,
    ));

    final detectors = tester.widgetList<VisibilityDetector>(
      find.byType(VisibilityDetector),
    );
    expect(detectors, hasLength(100));
    for (final detector in detectors) {
      detector.onVisibilityChanged!(_halfVisible(detector));
    }

    expect(parentBuilds, 1);
    expect(timers.where((timer) => timer.isActive), hasLength(1));

    now = now.add(const Duration(seconds: 1));
    timers.last.fire();
    await tester.pump();

    expect(parentBuilds, 1);
    expect(analytics.events.where((event) => event.name == 'deal_impression'),
        hasLength(100));
  });
}

class _TrackerFixture extends StatelessWidget {
  const _TrackerFixture({required this.analytics, required this.onBuild});

  final AnalyticsService analytics;
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
            (index) => DealImpressionTracker(
              analytics: analytics,
              dealId: index,
              source: 'home_feed',
              position: index,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ),
    );
  }
}
