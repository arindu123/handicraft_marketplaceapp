import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Guest can view products but adding to cart opens login', (
    tester,
  ) async {
    final demo = BuyerDemo();
    addTearDown(demo.dispose);
    const product = DemoProduct(
      'Clay cup',
      'Ceramics',
      20,
      'Maker',
      'Studio',
      'Handmade cup',
      'Colombo',
      0,
      id: 'cup',
      stock: 3,
    );
    demo.products = [product];
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteNames.signIn: (_) => const Scaffold(body: Text('Login screen')),
        },
        home: BuyerProductDetails(demo: demo, product: product),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Product details'), findsOneWidget);
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(find.text('Login screen'), findsOneWidget);
    expect(demo.cart, isEmpty);
  });

  for (final page in ['profile', 'cart', 'checkout']) {
    testWidgets('Guest $page shows sign in instead of account details', (
      tester,
    ) async {
      final demo = BuyerDemo();
      addTearDown(demo.dispose);
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            RouteNames.signIn: (_) =>
                const Scaffold(body: Text('Login screen')),
          },
          home: switch (page) {
            'profile' => BuyerProfile(demo: demo),
            'cart' => BuyerCart(demo: demo),
            _ => BuyerCheckout(demo: demo),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Collector Hub'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      await tester.ensureVisible(find.text('Sign in'));
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Login screen'), findsOneWidget);
    });
  }
}
