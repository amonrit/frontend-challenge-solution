import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/analytics_debug/analytics_debug_screen.dart';
import 'package:rescu/service/analytics_service.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('shows local event and delivery state separately',
      (tester) async {
    Get.testMode = true;
    Get.put(AnalyticsService());

    await tester.pumpWidget(const GetMaterialApp(
      home: AnalyticsDebugScreen(),
    ));

    expect(find.text('Pending impressions: 0'), findsOneWidget);
    expect(find.text('Sending impressions: 0'), findsOneWidget);
    expect(find.text('Delivery: idle'), findsOneWidget);
  });
}
