import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/shared_widget/the_network_image.dart';

void main() {
  testWidgets('passes a display-sized decode hint to cached images',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(devicePixelRatio: 2),
          child: TheNetworkImage(
            url: 'https://example.test/deal.jpg',
            width: 160,
            height: 160,
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 320);
    expect(image.memCacheHeight, 320);
  });
}
