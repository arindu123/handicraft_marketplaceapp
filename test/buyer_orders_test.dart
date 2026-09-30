import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';

void main() {
  testWidgets('Buyer can inspect a tracked order and its labelled stages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final demo = BuyerDemo();
    addTearDown(demo.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BuyerOrders(demo: demo),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tap(String text) async {
      final finder = find.text(text);
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(finder, 250);
      }
      await tester.ensureVisible(finder.first);
      await tester.tap(finder.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    expect(find.text('On The Way'), findsOneWidget);
    await tap('Handcrafted Terracotta Ribbed Vase');
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Demo Visa ending in 4092'), findsOneWidget);
    await tap('Track Order');
    expect(find.text('Order Tracking'), findsOneWidget);
    for (final stage in BuyerOrderStatus.values) {
      expect(find.text(stage.label), findsOneWidget);
    }
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Guild Courier · Marco V.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Order Details'), findsOneWidget);
  });

  test('New checkout order is session-only and starts confirmed', () {
    final demo = BuyerDemo();
    final order = demo.createOrder({demoProducts.first: 1}, 134);
    expect(order.status, BuyerOrderStatus.confirmed);
    expect(order.total, 134);
    expect(demo.orders.first, order);
    demo.dispose();
  });
}
