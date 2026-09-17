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
  Worker? _noticeWorker;
  bool _isShowingNotice = false;

  @override
  void initState() {
    super.initState();
    _cartService = widget.cartService ?? Get.find<CartService>();
    _noticeWorker = ever(_cartService.expiryNotices, (_) => _showNextNotice());
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNextNotice());
  }

  void _showNextNotice() {
    if (!mounted || _isShowingNotice || _cartService.expiryNotices.isEmpty) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final notice = _cartService.expiryNotices.first;
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

  @override
  void dispose() {
    _noticeWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
