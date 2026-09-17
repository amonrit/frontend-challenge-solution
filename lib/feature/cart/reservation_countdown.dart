import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../service/flash_sale_clock_service.dart';

class ReservationCountdown extends StatelessWidget {
  const ReservationCountdown({
    required this.expiresAt,
    required this.clock,
    super.key,
  });

  final DateTime expiresAt;
  final FlashSaleClockService clock;

  @override
  Widget build(BuildContext context) => Obx(() {
        final remaining =
            expiresAt.toUtc().difference(clock.currentTime.value.toUtc());
        if (remaining <= Duration.zero) {
          return const Text('Reservation expired');
        }
        return Text('Reservation expires in ${_format(remaining)}');
      });

  static String _format(Duration remaining) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    return hours > 0
        ? '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}'
        : '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
