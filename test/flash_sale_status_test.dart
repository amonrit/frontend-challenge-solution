import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/model/flash_sale_status.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);

  test('formats an active flash sale below one hour as mm:ss', () {
    final status = FlashSaleStatus.fromEnd(
      DateTime.utc(2026, 1, 1, 12, 59, 5),
      now: now,
    );

    expect(status.state, FlashSaleState.active);
    expect(status.label, '59:05');
  });

  test('formats an active flash sale at or above one hour as hh:mm:ss', () {
    final oneHour = FlashSaleStatus.fromEnd(
      DateTime.utc(2026, 1, 1, 13),
      now: now,
    );
    final multipleHours = FlashSaleStatus.fromEnd(
      DateTime.utc(2026, 1, 1, 14, 3, 4),
      now: now,
    );

    expect(oneHour.label, '01:00:00');
    expect(multipleHours.label, '02:03:04');
  });

  test('reports expired at zero or after the end instant', () {
    final zero = FlashSaleStatus.fromEnd(now, now: now);
    final past = FlashSaleStatus.fromEnd(
      DateTime.utc(2025, 12, 31, 23, 59, 59),
      now: now,
    );

    expect(zero.state, FlashSaleState.expired);
    expect(zero.label, 'Expired');
    expect(past.state, FlashSaleState.expired);
  });

  test('reports no status when a deal is not a flash sale', () {
    final status = FlashSaleStatus.fromEnd(null, now: now);

    expect(status.state, FlashSaleState.notFlashSale);
    expect(status.label, isNull);
  });
}
