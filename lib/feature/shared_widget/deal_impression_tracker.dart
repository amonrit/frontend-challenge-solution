import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../service/analytics_service.dart';

/// Forwards one card's visibility signal without owning a qualification timer.
class DealImpressionTracker extends StatefulWidget {
  const DealImpressionTracker({
    super.key,
    required this.dealId,
    required this.source,
    required this.position,
    required this.child,
    this.analytics,
  });

  final int dealId;
  final String source;
  final int position;
  final Widget child;
  final AnalyticsService? analytics;

  @override
  State<DealImpressionTracker> createState() => _DealImpressionTrackerState();
}

class _DealImpressionTrackerState extends State<DealImpressionTracker> {
  String get _observationId =>
      '${widget.source}:${widget.dealId}:${widget.position}';

  AnalyticsService? get _analytics =>
      widget.analytics ??
      (Get.isRegistered<AnalyticsService>()
          ? Get.find<AnalyticsService>()
          : null);

  @override
  void didUpdateWidget(covariant DealImpressionTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldObservationId =
        '${oldWidget.source}:${oldWidget.dealId}:${oldWidget.position}';
    if (oldObservationId != _observationId) {
      (oldWidget.analytics ?? _analytics)
          ?.endImpressionObservation(oldObservationId);
      VisibilityDetectorController.instance
          .forget(ValueKey('impression:$oldObservationId'));
    }
  }

  @override
  void dispose() {
    _analytics?.endImpressionObservation(_observationId);
    VisibilityDetectorController.instance
        .forget(ValueKey('impression:$_observationId'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analytics = _analytics;
    if (analytics == null) return widget.child;

    final detectorKey = ValueKey('impression:$_observationId');
    return VisibilityDetector(
      key: detectorKey,
      onVisibilityChanged: (info) => analytics.observeImpression(
        observationId: _observationId,
        dealId: widget.dealId,
        source: widget.source,
        position: widget.position,
        visibleFraction: info.visibleFraction,
      ),
      child: widget.child,
    );
  }
}
