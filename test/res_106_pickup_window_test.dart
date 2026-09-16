import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/model/pickup_window_model.dart';

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
}
