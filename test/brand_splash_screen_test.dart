import 'package:artisan_marketplace/shared/widgets/brand_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('Brand splash fits $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: BrandSplashScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(
        tester.getSize(find.byType(Image)).width,
        lessThanOrEqualTo(size.shortestSide),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
