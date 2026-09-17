import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../model/flash_sale_status.dart';
import '../../service/flash_sale_clock_service.dart';

typedef FlashSaleExpiryBuilder = Widget Function(
  BuildContext context,
  bool isExpired,
);

/// Rebuilds interaction affordances only when a sale crosses into expiry.
class FlashSaleExpiryGate extends StatefulWidget {
  const FlashSaleExpiryGate({
    super.key,
    required this.endsAt,
    required this.builder,
    this.clock,
  });

  final DateTime? endsAt;
  final FlashSaleExpiryBuilder builder;
  final FlashSaleClockService? clock;

  @override
  State<FlashSaleExpiryGate> createState() => _FlashSaleExpiryGateState();
}

class _FlashSaleExpiryGateState extends State<FlashSaleExpiryGate> {
  FlashSaleClockService? _clock;
  Worker? _clockWorker;
  var _isExpired = false;

  @override
  void initState() {
    super.initState();
    if (widget.endsAt == null) return;

    _clock = widget.clock ?? Get.find<FlashSaleClockService>();
    _isExpired = _statusIsExpired();
    _clockWorker = ever(_clock!.currentTime, (_) {
      final nextIsExpired = _statusIsExpired();
      if (nextIsExpired != _isExpired && mounted) {
        setState(() => _isExpired = nextIsExpired);
      }
    });
  }

  bool _statusIsExpired() => FlashSaleStatus.fromEnd(
        widget.endsAt,
        now: _clock!.currentTime.value,
      ).isExpired;

  @override
  void dispose() {
    _clockWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _isExpired);
}
