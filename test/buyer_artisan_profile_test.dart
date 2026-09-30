import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';

void main() {
  testWidgets('Buyer can view, follow, and browse a verified artisan', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final demo = BuyerDemo();
    addTearDown(demo.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BuyerProductDetails(demo: demo, product: demoProducts.first),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tap(String label) async {
      final finder = find.text(label);
      await tester.ensureVisible(finder.first);
      await tester.pumpAndSettle();
      await tester.tap(finder.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tap('View Artisan');
    expect(find.text('Artisan Profile'), findsOneWidget);
    expect(find.text('Verified Guild Artisan'), findsOneWidget);
    await tap('Follow Artisan');
    expect(find.text('Following'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Reviews'), 250);
    await tester.pumpAndSettle();
    expect(find.text('Reviews'), findsOneWidget);
    expect(find.text('Maya L.'), findsOneWidget);
    await tap('Handcrafted Terracotta Ribbed Vase');
    expect(find.text('Product Detail'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Artisan Profile'), findsOneWidget);
  });
}
