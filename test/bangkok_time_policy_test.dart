import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/service/bangkok_time_policy.dart';

void main() {
  test('projects a UTC instant into Bangkok time', () {
    final policy = BangkokTimePolicy(
      now: () => DateTime.parse('2026-01-01T00:00:00Z'),
    );

    expect(
      policy.toMarket(DateTime.parse('2026-01-01T10:30:00Z')),
      DateTime.parse('2026-01-01T17:30:00Z'),
    );
  });

  test('accepts an injected clock for deterministic market time', () {
    final policy = BangkokTimePolicy(
      now: () => DateTime.parse('2026-01-01T17:30:00Z'),
    );

    expect(policy.nowInMarket, DateTime.parse('2026-01-02T00:30:00Z'));
  });

  test('compares complete market calendar dates', () {
    final policy = BangkokTimePolicy(
      now: () => DateTime.parse('2026-01-31T17:00:00Z'),
    );

    expect(
      policy.isSameMarketDate(
        DateTime.parse('2026-01-31T18:00:00Z'),
        DateTime.parse('2026-02-01T01:00:00Z'),
      ),
      isTrue,
    );
  });
}
