import 'dart:async';

import 'package:get/get.dart';

import '../util/log_service.dart';

typedef OneShotTimerFactory = Timer Function(
  Duration duration,
  void Function() callback,
);

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime at;

  AnalyticsEvent(this.name, this.properties, {DateTime? at})
      : at = at ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'properties': properties,
        'at': at.toIso8601String(),
      };
}

/// In-memory analytics sink. Events are visible on the debug screen
/// (overflow menu on Home -> "Analytics debug") and in the console.
///
/// The "Impression tracking" feature task builds on top of this service.
class AnalyticsService extends GetxService {
  AnalyticsService({
    DateTime Function()? now,
    OneShotTimerFactory? oneShotTimer,
  })  : _now = now ?? DateTime.now,
        _oneShotTimer = oneShotTimer ?? Timer.new;

  final DateTime Function() _now;
  final OneShotTimerFactory _oneShotTimer;
  final _impressionObservations = <String, _ImpressionObservation>{};
  Timer? _qualificationTimer;

  final events = <AnalyticsEvent>[].obs;

  void logEvent(String name, [Map<String, dynamic> properties = const {}]) {
    final event = AnalyticsEvent(name, properties, at: _now());
    events.add(event);
    LogService.log('analytics: $name $properties');
  }

  void observeImpression({
    required String observationId,
    required int dealId,
    required String source,
    required int position,
    required double visibleFraction,
  }) {
    if (visibleFraction < 0.5 ||
        _impressionObservations.containsKey(observationId)) {
      return;
    }

    _impressionObservations[observationId] = _ImpressionObservation(
      dealId: dealId,
      source: source,
      position: position,
      startedAt: _now(),
    );
    _scheduleQualification();
  }

  void _scheduleQualification() {
    _qualificationTimer?.cancel();
    if (_impressionObservations.isEmpty) return;

    final now = _now();
    final nextDeadline = _impressionObservations.values
        .map((observation) =>
            observation.startedAt.add(const Duration(seconds: 1)))
        .reduce((earliest, deadline) =>
            deadline.isBefore(earliest) ? deadline : earliest);
    final delay = nextDeadline.difference(now);
    _qualificationTimer = _oneShotTimer(
      delay.isNegative ? Duration.zero : delay,
      _recordDueImpressions,
    );
  }

  void _recordDueImpressions() {
    _qualificationTimer = null;
    final now = _now();
    final due = _impressionObservations.entries
        .where((entry) => !now
            .isBefore(entry.value.startedAt.add(const Duration(seconds: 1))))
        .toList();
    for (final entry in due) {
      _impressionObservations.remove(entry.key);
      final observation = entry.value;
      logEvent('deal_impression', {
        'deal_id': observation.dealId,
        'source': observation.source,
        'position': observation.position,
      });
    }
    _scheduleQualification();
  }

  @override
  void onClose() {
    _qualificationTimer?.cancel();
    _impressionObservations.clear();
    super.onClose();
  }
}

class _ImpressionObservation {
  const _ImpressionObservation({
    required this.dealId,
    required this.source,
    required this.position,
    required this.startedAt,
  });

  final int dealId;
  final String source;
  final int position;
  final DateTime startedAt;
}
