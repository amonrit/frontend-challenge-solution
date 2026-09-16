import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/service/bangkok_time_policy.dart';

void main() {
  test('formats an API UTC instant in Bangkok market time', () {
    final window = PickupWindowModel(
      start: DateTime.parse('2026-01-01T10:30:00.000Z'),
      end: DateTime.parse('2026-01-01T14:00:00.000Z'),
    );

    expect(window.label, '17:30 – 21:00');
  });

  test('isToday compares the complete calendar date', () {
    final now = DateTime.now();
    final nextMonth = DateTime(
      now.year + (now.month == 12 ? 1 : 0),
      now.month == 12 ? 1 : now.month + 1,
      now.day,
      12,
    );
    final window = PickupWindowModel(
      start: nextMonth,
      end: nextMonth.add(const Duration(hours: 1)),
    );

    expect(window.isToday, isFalse);
  });

  test('keeps a pickup that crosses UTC midnight on the Bangkok date', () {
    final policy = BangkokTimePolicy(
      now: () => DateTime.parse('2026-01-01T17:00:00Z'),
    );
    final window = PickupWindowModel(
      start: DateTime.parse('2026-01-01T17:30:00Z'),
      end: DateTime.parse('2026-01-01T18:30:00Z'),
      timePolicy: policy,
    );

    expect(window.isToday, isTrue);
    expect(window.label, '00:30 – 01:30');
  });

  test('handles the Bangkok month-end boundary', () {
    final policy = BangkokTimePolicy(
      now: () => DateTime.parse('2026-01-31T17:00:00Z'),
    );
    final window = PickupWindowModel(
      start: DateTime.parse('2026-01-31T17:30:00Z'),
      end: DateTime.parse('2026-01-31T18:30:00Z'),
      timePolicy: policy,
    );

    expect(window.isToday, isTrue);
  });

  test('handles the Bangkok year-end boundary', () {
    final policy = BangkokTimePolicy(
      now: () => DateTime.parse('2026-12-31T17:00:00Z'),
    );
    final window = PickupWindowModel(
      start: DateTime.parse('2026-12-31T17:30:00Z'),
      end: DateTime.parse('2026-12-31T18:30:00Z'),
      timePolicy: policy,
    );

    expect(window.isToday, isTrue);
  });

  test('uses UTC instants consistently regardless of local DateTime zone', () {
    final policy = BangkokTimePolicy(
      now: () => DateTime.parse('2026-06-15T02:00:00Z'),
    );
    final window = PickupWindowModel(
      start: DateTime.parse('2026-06-15T02:30:00Z'),
      end: DateTime.parse('2026-06-15T03:30:00Z'),
      timePolicy: policy,
    );

    expect(window.isToday, isTrue);
    expect(window.label, '09:30 – 10:30');
  });
}
