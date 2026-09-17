import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../util/log_service.dart';

typedef OneShotTimerFactory = Timer Function(
  Duration duration,
  void Function() callback,
);
typedef AnalyticsBatchSender = Future<void> Function(
  List<Map<String, dynamic>> events,
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
class AnalyticsService extends GetxService with WidgetsBindingObserver {
  AnalyticsService({
    DateTime Function()? now,
    OneShotTimerFactory? oneShotTimer,
    AnalyticsBatchSender? batchSender,
  })  : _now = now ?? DateTime.now,
        _oneShotTimer = oneShotTimer ?? Timer.new,
        _batchSender = batchSender;

  final DateTime Function() _now;
  final OneShotTimerFactory _oneShotTimer;
  final AnalyticsBatchSender? _batchSender;
  final _impressionObservations = <String, _ImpressionObservation>{};
  final _impressedDealIds = <int>{};
  final _pendingImpressionEvents = <Map<String, dynamic>>[];
  Timer? _qualificationTimer;
  Timer? _batchTimer;
  DateTime? _firstPendingAt;
  bool _isSendingBatch = false;

  final events = <AnalyticsEvent>[].obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

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
    if (visibleFraction < 0.5) {
      endImpressionObservation(observationId);
      return;
    }
    if (_impressedDealIds.contains(dealId) ||
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

  void endImpressionObservation(String observationId) {
    if (_impressionObservations.remove(observationId) != null) {
      _scheduleQualification();
    }
  }

  void _scheduleQualification() {
    _qualificationTimer?.cancel();
    _qualificationTimer = null;
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
      if (!_impressedDealIds.add(observation.dealId)) continue;
      logEvent('deal_impression', {
        'deal_id': observation.dealId,
        'source': observation.source,
        'position': observation.position,
      });
      _enqueueImpression({
        'deal_id': observation.dealId,
        'source': observation.source,
        'position': observation.position,
      });
    }
    _scheduleQualification();
  }

  void _enqueueImpression(Map<String, dynamic> event) {
    _pendingImpressionEvents.add(event);
    _firstPendingAt ??= _now();
    if (_pendingImpressionEvents.length >= 10) {
      unawaited(_sendNextBatch());
      return;
    }
    _scheduleBatchDeadline();
  }

  void _scheduleBatchDeadline({Duration? retryDelay}) {
    if (_isSendingBatch ||
        _pendingImpressionEvents.isEmpty ||
        _batchTimer != null) {
      return;
    }
    final delay = retryDelay ??
        _firstPendingAt!.add(const Duration(seconds: 15)).difference(_now());
    _batchTimer = _oneShotTimer(
      delay.isNegative ? Duration.zero : delay,
      () {
        _batchTimer = null;
        unawaited(_sendNextBatch());
      },
    );
  }

  Future<void> _sendNextBatch() async {
    final sender = _batchSender;
    if (_isSendingBatch || _pendingImpressionEvents.isEmpty || sender == null) {
      return;
    }

    _batchTimer?.cancel();
    _batchTimer = null;
    _isSendingBatch = true;
    final batch = List<Map<String, dynamic>>.from(_pendingImpressionEvents);
    final batchFirstPendingAt = _firstPendingAt;
    _pendingImpressionEvents.clear();
    _firstPendingAt = null;
    var sent = false;
    try {
      await sender(batch);
      sent = true;
    } catch (error) {
      LogService.error('failed to send analytics batch', error);
      _pendingImpressionEvents.insertAll(0, batch);
      _firstPendingAt = batchFirstPendingAt;
    } finally {
      _isSendingBatch = false;
      if (!sent) {
        _scheduleBatchDeadline(retryDelay: const Duration(seconds: 15));
      } else if (_pendingImpressionEvents.length >= 10) {
        unawaited(_sendNextBatch());
      } else {
        _scheduleBatchDeadline();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _impressionObservations.clear();
      _qualificationTimer?.cancel();
      _qualificationTimer = null;
      return;
    }
    if (state == AppLifecycleState.resumed &&
        !_isSendingBatch &&
        _pendingImpressionEvents.isNotEmpty) {
      final deadline = _firstPendingAt!.add(const Duration(seconds: 15));
      if (!_now().isBefore(deadline)) {
        _batchTimer?.cancel();
        _batchTimer = null;
        unawaited(_sendNextBatch());
      } else {
        _scheduleBatchDeadline();
      }
    }
  }

  @override
  void onClose() {
    _qualificationTimer?.cancel();
    _batchTimer?.cancel();
    _impressionObservations.clear();
    _impressedDealIds.clear();
    _pendingImpressionEvents.clear();
    WidgetsBinding.instance.removeObserver(this);
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
