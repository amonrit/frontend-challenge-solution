import 'package:intl/intl.dart';
import 'package:rescu/service/bangkok_time_policy.dart';

/// A store's pickup window. The API sends instants as ISO-8601 UTC strings.
class PickupWindowModel {
  final DateTime start;
  final DateTime end;

  const PickupWindowModel({
    required this.start,
    required this.end,
    this.timePolicy,
  });

  final BangkokTimePolicy? timePolicy;

  factory PickupWindowModel.fromJson(Map<String, dynamic> json) {
    return PickupWindowModel(
      start: DateTime.parse(json['start'] as String? ?? ''),
      end: DateTime.parse(json['end'] as String? ?? ''),
    );
  }

  /// Human readable label, e.g. "17:30 – 21:00".
  String get label {
    final policy = timePolicy ?? BangkokTimePolicy();
    return '${DateFormat('HH:mm').format(policy.toMarket(start))} – '
        '${DateFormat('HH:mm').format(policy.toMarket(end))}';
  }

  /// Whether pickup starts today.
  bool get isToday {
    final policy = timePolicy ?? BangkokTimePolicy();
    return policy.isSameMarketDate(start, DateTime.now());
  }

  /// Whether the store is currently accepting pickups.
  bool get isOpenNow {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  Duration get untilStart => start.difference(DateTime.now());
}
