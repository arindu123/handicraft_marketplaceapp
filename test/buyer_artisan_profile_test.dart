import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/routes/route_names.dart';
import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';

void main() {
  testWidgets('Guest can browse an artisan but must sign in to follow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final demo = BuyerDemo()
      ..products = List.of(demoProducts)
      ..catalogError = null;
    addTearDown(demo.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        routes: {
          RouteNames.signIn: (_) =>
              Scaffold(appBar: AppBar(), body: const Text('Sign in required')),
        },
        home: BuyerArtisanProfile(
          demo: demo,
          artisan: buyerArtisans.first,
          avatarProduct: demoProducts.first,
        ),
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

    expect(find.text('Artisan Profile'), findsOneWidget);
    await tap('Follow Artisan');
    expect(find.text('Sign in required'), findsOneWidget);
    expect(demo.followedArtisans, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Reviews'), 250);
    await tester.pumpAndSettle();
    expect(find.text('Reviews'), findsOneWidget);
    expect(find.text('Maya L.'), findsOneWidget);
    await tap('Handcrafted Terracotta Ribbed Vase');
    expect(find.text('Product details'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Artisan Profile'), findsOneWidget);
  });
}
