import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rescu/feature/deal/deal_details_screen.dart';
import 'package:rescu/feature/shared_widget/deal_card.dart';
import 'package:rescu/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('can repeatedly open and leave a deal from Home', (tester) async {
    app.main();
    await _pumpUntilFound(tester, find.byType(DealCard));

    expect(find.byType(DealCard), findsWidgets);

    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.tap(find.byType(DealCard).first);
      await _pumpUntilFound(tester, find.byType(DealDetailsScreen));

      expect(find.byType(DealDetailsScreen), findsOneWidget);

      await tester.pageBack();
      await _pumpUntilFound(tester, find.byType(DealCard));

      expect(find.byType(DealCard), findsWidgets);
    }
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}
