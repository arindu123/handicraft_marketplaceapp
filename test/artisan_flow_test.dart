import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/artisan/artisan_dashboard_screen.dart';
import 'package:artisan_marketplace/routes/route_names.dart';

void main() {
  Future<void> start(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: RouteNames.marketplace,
        routes: {RouteNames.marketplace: (_) => const ArtisanDashboardScreen()},
      ),
    );
    await t.pumpAndSettle();
  }



   Future<void> tap(WidgetTester t, String label) async {
    final f = find.text(label);
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    if (f.first.hitTestable().evaluate().isEmpty) {
      await t.ensureVisible(f.first);
      await t.pumpAndSettle();
    }
    await t.tap(f.first);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  testWidgets('Artisan publishes, views and edits a session product', (
    t,
  ) async {
    await start(t);
    await tap(t, 'Add Product');
    expect(find.text('Step 1 of 3 — Images'), findsOneWidget);
    await tap(t, 'Next: Product Details');
    expect(find.text('Step 2 of 3 — Product Details'), findsOneWidget);
    expect(find.text('Select category'), findsOneWidget);
    await t.enterText(find.byType(TextFormField).at(0), 'Coastal Vase');
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    await tap(t, 'Terracotta');
    await t.enterText(find.byType(TextFormField).at(1), '72');
    await t.enterText(
      find.byType(TextFormField).at(2),
      'Hand-thrown coastal clay.',
    );
    await tap(t, 'Next: Preview & Review');
    expect(find.text('Step 3 of 3 — Preview'), findsOneWidget);
    expect(find.text('Coastal Vase'), findsOneWidget);
    await tap(t, 'Publish Product');
    expect(find.text('Product Published'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'View Product'), findsOneWidget);
    await tap(t, 'View Product');
    expect(find.text('Coastal Vase'), findsOneWidget);
    await tap(t, 'Edit Product');
    await tap(t, 'Next: Product Details');
    await t.enterText(find.byType(TextFormField).at(0), 'Coastal Vase Updated');
    await tap(t, 'Next: Preview & Review');
    await tap(t, 'Save Changes');
    expect(find.text('View Product'), findsOneWidget);
    expect(find.text('Coastal Vase Updated'), findsOneWidget);
  });
  testWidgets('Artisan orders, profile and verification are reachable', (
    t,
  ) async {
    await start(t);
    await tap(t, 'Products');
    expect(find.text('My Products'), findsOneWidget);
    await tap(t, 'Orders');
    await tap(t, 'Order Details');
    expect(find.text('Order Details'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    await tap(t, 'Profile');
    await tap(t, 'Verification Status');
    expect(find.text('Guild Certified Potter'), findsOneWidget);
  });
}
