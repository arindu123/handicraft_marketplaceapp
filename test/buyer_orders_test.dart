import 'package:flutter/material.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
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
    demo.orders.add(
      BuyerDemoOrder(
        id: 'test-order',
        items: {demoProducts.first: 1},
        date: '2026-01-01',
        status: BuyerOrderStatus.onTheWay,
        address: 'Test address',
        payment: 'Cash on delivery',
        deliveryFee: 14,
      ),
    );
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
    expect(find.text('Cash on delivery'), findsOneWidget);
    await tap('Track Order');
    expect(find.text('Order Tracking'), findsOneWidget);
    for (final stage in BuyerOrderStatus.values.where(
      (s) => s != BuyerOrderStatus.cancelled,
    )) {
      expect(find.text(stage.label), findsOneWidget);
    }
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Assigned Guild Courier'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Order Details'), findsOneWidget);
  });

  test('Disconnected checkout cannot fabricate a confirmed order', () {
    final demo = BuyerDemo();
    expect(
      () => demo.createOrder({demoProducts.first: 1}, 134),
      throwsA(isA<MarketplaceFailure>()),
    );
    expect(demo.orders, isEmpty);
    demo.dispose();
  });
}
