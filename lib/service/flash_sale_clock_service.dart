import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

typedef PeriodicTimerFactory = Timer Function(
  Duration duration,
  void Function(Timer timer) callback,
);

/// App-scoped source of time for flash-sale state.
class FlashSaleClockService extends GetxService with WidgetsBindingObserver {
  FlashSaleClockService({
    DateTime Function()? now,
    PeriodicTimerFactory? periodicTimer,
  })  : _now = now ?? DateTime.now,
        _periodicTimer = periodicTimer ?? Timer.periodic;

  final DateTime Function() _now;
  final PeriodicTimerFactory _periodicTimer;
  late final Rx<DateTime> currentTime;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    currentTime = _now().obs;
    WidgetsBinding.instance.addObserver(this);
    _timer = _periodicTimer(const Duration(seconds: 1), (_) => refresh());
  }

  void refresh() {
    currentTime.value = _now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void onClose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
