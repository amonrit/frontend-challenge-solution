import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../service/cart_service.dart';

/// Presents cart expiry events at the app root while keeping CartService UI-free.
class FlashSaleNoticeHost extends StatefulWidget {
  const FlashSaleNoticeHost({
    super.key,
    required this.child,
    this.cartService,
  });

  final Widget child;
  final CartService? cartService;

  @override
  State<FlashSaleNoticeHost> createState() => _FlashSaleNoticeHostState();
}

class _FlashSaleNoticeHostState extends State<FlashSaleNoticeHost> {
  late final CartService _cartService;
  Worker? _flashNoticeWorker;
  Worker? _reservationNoticeWorker;
  bool _isShowingNotice = false;

  @override
  void initState() {
    super.initState();
    _cartService = widget.cartService ?? Get.find<CartService>();
    _flashNoticeWorker =
        ever(_cartService.expiryNotices, (_) => _showNextNotice());
    _reservationNoticeWorker =
        ever(_cartService.reservationExpiryNotices, (_) => _showNextNotice());
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNextNotice());
  }

  void _showNextNotice() {
    if (!mounted || _isShowingNotice) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    if (_cartService.expiryNotices.isNotEmpty) {
      _showFlashNotice(messenger, _cartService.expiryNotices.first);
      return;
    }
    if (_cartService.reservationExpiryNotices.isNotEmpty) {
      _showReservationNotice(
          messenger, _cartService.reservationExpiryNotices.first);
    }
  }

  void _showFlashNotice(
      ScaffoldMessengerState messenger, FlashSaleExpiryNotice notice) {
    _isShowingNotice = true;
    messenger
        .showSnackBar(SnackBar(
          content: Text(
            '${notice.dealName} expired and was removed from your bag.',
          ),
        ))
        .closed
        .whenComplete(() {
      if (!mounted) return;
      _cartService.consumeExpiryNotice(notice);
      _isShowingNotice = false;
      _showNextNotice();
    });
  }

  void _showReservationNotice(
      ScaffoldMessengerState messenger, ReservationExpiryNotice notice) {
    _isShowingNotice = true;
    messenger
        .showSnackBar(SnackBar(
          content: Text('Your reservation for ${notice.dealName} expired.'),
        ))
        .closed
        .whenComplete(() {
      if (!mounted) return;
      _cartService.consumeReservationExpiryNotice(notice);
      _isShowingNotice = false;
      _showNextNotice();
    });
  }

  @override
  void dispose() {
    _flashNoticeWorker?.dispose();
    _reservationNoticeWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
