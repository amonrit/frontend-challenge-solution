import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/flash_sale_status.dart';
import '../../service/flash_sale_clock_service.dart';

/// Rebuilds only its label when the app-scoped flash-sale clock changes.
class FlashSaleCountdown extends StatelessWidget {
  const FlashSaleCountdown({
    super.key,
    required this.endsAt,
    this.clock,
    this.style,
  });

  final DateTime? endsAt;
  final FlashSaleClockService? clock;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final saleClock = clock ?? Get.find<FlashSaleClockService>();
    return Obx(() {
      final status = FlashSaleStatus.fromEnd(
        endsAt,
        now: saleClock.currentTime.value,
      );
      if (status.label == null) return const SizedBox.shrink();
      return Text(status.label!, style: style);
    });
  }
}
