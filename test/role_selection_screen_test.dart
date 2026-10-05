import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/auth/screens/role_selection_screen.dart';
import 'package:artisan_marketplace/routes/app_routes.dart';
import 'package:artisan_marketplace/routes/route_names.dart';

void main() {
  testWidgets(
    'Roles route selects one role and forwards the choice to sign up',
    (tester) async {
      Object? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          initialRoute: RouteNames.roleSelection,
          routes: {
            ...AppRoutes.routes,
            RouteNames.signUp: (context) {
              selected = ModalRoute.of(context)?.settings.arguments;
              return const Scaffold(body: Text('Destination'));
            },
          },
        ),
      );
      expect(find.text('Roles Selection'), findsOneWidget);
      for (final title in [
        'Artisan / Studio Maker',
        'Buyer / Patron',
        'Fragile Delivery Courier',
        'Marketplace Curator & Admin',
      ]) {
        await tester.ensureVisible(find.text(title));
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        if (title == 'Buyer / Patron') {
          expect(find.text('Continue to login'), findsOneWidget);
          await tester.tap(find.byTooltip('Back to roles'));
          await tester.pumpAndSettle();
        }
        expect(find.text('ACTIVE'), findsOneWidget);
        final activeCard = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.selected == true &&
              widget.properties.inMutuallyExclusiveGroup == true,
        );
        expect(activeCard, findsOneWidget);
        expect(
          find.descendant(of: activeCard, matching: find.text(title)),
          findsOneWidget,
        );
      }
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(selected, MarketplaceRole.admin);
      expect(find.text('Destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Role cards fit small screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        routes: AppRoutes.routes,
        initialRoute: RouteNames.roleSelection,
      ),
    );
    for (final title in [
      'Artisan / Studio Maker',
      'Buyer / Patron',
      'Fragile Delivery Courier',
      'Marketplace Curator & Admin',
    ]) {
      await tester.ensureVisible(find.text(title));
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      if (title == 'Buyer / Patron') {
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Back to roles'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.text('Continue'));
    expect(find.text('Continue').hitTestable(), findsOneWidget);
  });
}
