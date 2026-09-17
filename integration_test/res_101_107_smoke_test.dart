import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rescu/feature/deal/deal_details_screen.dart';
import 'package:rescu/feature/home/widget/home_feed_list.dart';
import 'package:rescu/feature/order/widget/pickup_countdown.dart';
import 'package:rescu/feature/shared_widget/deal_card.dart';
import 'package:rescu/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RES-101 Search renders the final query state', (tester) async {
    await _launchHome(tester);
    await tester.tap(find.byIcon(Icons.search));
    await _pumpUntilFound(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'sushi');
    await tester.enterText(find.byType(TextField), 'bakery');
    await _pumpUntilAnyFound(
      tester,
      [find.text('No deals found'), find.byType(DealCard)],
    );
  });

  testWidgets('RES-102 Orders countdown survives route exit', (tester) async {
    await _launchHome(tester);
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await _pumpUntilFound(tester, find.text('My orders'));
    await _pumpUntilFound(tester, find.byType(PickupCountdown));
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('RES-103 can repeatedly open and leave a Home deal',
      (tester) async {
    await _launchHome(tester);
    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.tap(find.byType(DealCard).first);
      await _pumpUntilFound(tester, find.byType(DealDetailsScreen));
      await tester.pageBack();
      await _pumpUntilFound(tester, find.byType(HomeFeedList));
    }
  });

  testWidgets('RES-104 Home remains usable after a feed scroll',
      (tester) async {
    await _launchHome(tester);
    await tester.drag(find.byType(HomeFeedList), const Offset(0, -900));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DealCard), findsWidgets);
  });

  testWidgets('RES-105 lazy Home feed remains scrollable', (tester) async {
    await _launchHome(tester);
    await tester.drag(find.byType(HomeFeedList), const Offset(0, -900));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HomeFeedList), findsOneWidget);
  });

  testWidgets('RES-106 Pickup today only renders market-today cards',
      (tester) async {
    await _launchHome(tester);
    await tester.tap(find.text('Pickup today'));
    await tester.pump(const Duration(seconds: 1));
    final todayCards = tester.widgetList<DealCard>(find.byType(DealCard));
    expect(todayCards, isNotEmpty);
    expect(
      todayCards,
      everyElement(predicate(
        (Object? card) => (card as DealCard).deal.pickupWindow.isToday,
      )),
    );
  });

  testWidgets('RES-107 simulated deep link resolves a deal by id',
      (tester) async {
    await _launchHome(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await _pumpUntilFound(tester, find.text('Simulate deep link…'));
    await tester.tap(find.text('Simulate deep link…'));
    await _pumpUntilFound(tester, find.byType(AlertDialog));
    await tester.tap(find.text('Open'));
    await _pumpUntilFound(tester, find.byType(DealDetailsScreen));
    expect(find.byType(DealDetailsScreen), findsOneWidget);
  });
}

Future<void> _launchHome(WidgetTester tester) async {
  Get.reset();
  await app.main();
  await _pumpUntilFound(tester, find.byType(HomeFeedList));
  expect(find.byType(DealCard), findsWidgets);
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 24; attempt++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpUntilAnyFound(
  WidgetTester tester,
  List<Finder> finders,
) async {
  for (var attempt = 0; attempt < 24; attempt++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finders.any((finder) => finder.evaluate().isNotEmpty)) return;
  }
  throw TestFailure('Timed out waiting for one of $finders');
}
