import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/order/widget/pickup_countdown.dart';

void main() {
  Future<void> pumpCountdowns(
    WidgetTester tester, {
    int count = 1,
    DateTime Function()? now,
  }) {
    final pickupStart =
        (now?.call() ?? DateTime.now()).add(const Duration(minutes: 1));
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: List.generate(
            count,
            (_) => PickupCountdown(
              pickupStart: pickupStart,
              now: now ?? DateTime.now,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('stops its periodic callback when disposed', (tester) async {
    await pumpCountdowns(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('updates its visible countdown while mounted', (tester) async {
    var currentTime = DateTime.utc(2026, 1, 1, 12);
    await pumpCountdowns(tester, now: () => currentTime);
    final before = tester.widget<Text>(find.byType(Text)).data;

    currentTime = currentTime.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final after = tester.widget<Text>(find.byType(Text)).data;

    expect(after, isNot(before));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stops every countdown callback when multiple are disposed',
      (tester) async {
    await pumpCountdowns(tester, count: 3);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('stops its callback after its route is popped', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final pickupStart = DateTime.now().add(const Duration(minutes: 1));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: navigatorKey,
          initialRoute: '/',
          onGenerateRoute: (settings) => PageRouteBuilder<void>(
            pageBuilder: (_, __, ___) => settings.name == '/orders'
                ? PickupCountdown(pickupStart: pickupStart)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );

    navigatorKey.currentState!.pushNamed('/orders');
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
