import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/shared_widget/flash_sale_notice_host.dart';
import 'package:rescu/service/cart_service.dart';

void main() {
  testWidgets('shows and consumes each queued flash-sale expiry notice',
      (tester) async {
    final cart = CartService();
    cart.expiryNotices.add(const FlashSaleExpiryNotice(
      dealId: 42,
      dealName: 'Flash sushi box',
    ));

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => FlashSaleNoticeHost(
        cartService: cart,
        child: child!,
      ),
      home: const Scaffold(body: SizedBox()),
    ));
    await tester.pump();

    expect(
      find.text('Flash sushi box expired and was removed from your bag.'),
      findsOneWidget,
    );

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    expect(cart.expiryNotices, isEmpty);
    cart.onClose();
  });
}
