import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/auth/models/marketplace_role.dart';
import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/routes/app_routes.dart';
import 'package:artisan_marketplace/routes/route_names.dart';

void main() {
  Future<void> start(WidgetTester tester, MarketplaceRole role) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        routes: AppRoutes.routes,
        initialRoute: RouteNames.marketplace,
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(
            settings: RouteSettings(
              name: RouteNames.marketplace,
              arguments: role,
            ),
            builder: AppRoutes.routes[RouteNames.marketplace]!,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text);
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
    }
    if (target.hitTestable().evaluate().isEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pumpAndSettle();
    }
    await tester.tap(target.first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Buyer can search, select a piece and complete checkout', (
    tester,
  ) async {
    await start(tester, MarketplaceRole.buyer);
    expect(find.byType(BuyerMarketplace), findsOneWidget);
    await tapText(tester, 'Search');
    await tester.enterText(find.byType(TextField), 'mug');
    await tester.pumpAndSettle();
    expect(find.text('1 pieces found'), findsOneWidget);
    await tapText(tester, demoProducts[1].name);
    await tapText(tester, 'Add to Cart · \$48.00');
    expect(find.text('Atelier Bag (1 pieces)'), findsOneWidget);
    await tapText(tester, 'Proceed to Checkout · \$62.00');
    await tapText(tester, 'Continue to Payment');
    await tapText(tester, 'Demo Visa ending in 4092');
    await tapText(tester, 'Continue to Review');
    expect(find.text('Review & Place Order'), findsOneWidget);
    await tapText(tester, 'Place Order · \$62.00');
    expect(find.text('Your order successfully placed'), findsOneWidget);
    await tapText(tester, 'Back to dashboard');
    expect(find.byType(BuyerMarketplace), findsOneWidget);
    expect(find.byType(BuyerCheckout), findsNothing);
    await tapText(tester, 'Favorites');
    expect(find.text('Curated Atelier Pieces'), findsOneWidget);
    await tapText(tester, 'Profile');
    expect(find.text('Collector Profile'), findsOneWidget);
  });

  testWidgets('Artisan entry remains separate from Buyer marketplace', (
    tester,
  ) async {
    await start(tester, MarketplaceRole.artisan);
    expect(find.text('Artisan Dashboard'), findsOneWidget);
    expect(find.byType(BuyerMarketplace), findsNothing);
  });

  testWidgets('Category filters show matching pieces and can be cleared', (
    tester,
  ) async {
    await start(tester, MarketplaceRole.buyer);
    await tapText(tester, 'Search');
    await tapText(tester, 'Stoneware');
    expect(find.text('Filter Artifacts · 1 active'), findsOneWidget);
    expect(find.text('1 pieces found'), findsOneWidget);
    await tapText(tester, 'Clear');
    expect(find.text('3 pieces found'), findsOneWidget);
    expect(find.text('Filter Artifacts · 0 active'), findsOneWidget);
  });
}
