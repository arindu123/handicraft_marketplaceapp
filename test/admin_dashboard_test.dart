import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/features/admin/screens/admin_dashboard_screen.dart';
import 'package:artisan_marketplace/features/admin/models/admin_demo_store.dart';
import 'package:artisan_marketplace/features/auth/models/marketplace_role.dart';
import 'package:artisan_marketplace/routes/app_routes.dart';
import 'package:artisan_marketplace/routes/route_names.dart';
import 'package:artisan_marketplace/core/theme/app_theme.dart';

import 'helpers/admin_test_store.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Approval decisions update directories once and remain session-only',
    () {
      final store = adminTestStore();
      final count = store.users.length;
      store.decide(store.approvals.first, true);
      store.decide(store.approvals.first, true);
      expect(store.users.length, count + 1);
      expect(store.pending, 2);
      store.decide(store.approvals[1], false);
      expect(store.users.length, count + 1);
      expect(store.pending, 1);
      final offline = AdminDemoStore();
      expect(offline.pending, 0);
      offline.dispose();
      store.dispose();
    },
  );

  testWidgets(
    'Admin signup does not expose an unauthenticated dashboard preview',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          routes: AppRoutes.routes..remove('/'),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  RouteNames.signUp,
                  arguments: MarketplaceRole.admin,
                ),
                child: const Text('Open admin signup'),
              ),
            ),
          ),
        ),
      );
      await tapText(tester, 'Open admin signup');
      expect(find.text('Preview Admin Dashboard'), findsNothing);
      expect(find.byType(AdminDashboardScreen), findsNothing);
      expect(find.text('Enter your full name.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Review can cancel then approve and updates the visible list', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminDashboardScreen(store: adminTestStore()),
      ),
    );
    await tapText(tester, 'Approvals');
    await tapText(tester, 'Review application →');
    await tapText(tester, 'Approve');
    await tapText(tester, 'Cancel');
    expect(find.text('Earth & Ember Studio'), findsWidgets);
    await tapText(tester, 'Approve');
    await tapText(tester, 'Confirm');
    expect(find.text('Earth & Ember Studio'), findsNothing);
    await tapText(tester, 'Approved');
    expect(find.text('Earth & Ember Studio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Order search and demo status updates work', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminDashboardScreen(store: adminTestStore()),
      ),
    );
    await tapText(tester, 'Orders');
    await tester.enterText(find.byType(TextField), 'no-such-order');
    await tester.pumpAndSettle();
    expect(
      find.text('No matching orders. Try another search or status.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'CR-2048');
    await tester.pumpAndSettle();
    await tapText(tester, 'Fluted terracotta vase');
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(ChoiceChip, 'Delivered'),
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Update status');
    await tapText(tester, 'Confirm');
    expect(find.text('Delivered'), findsWidgets);
    expect(find.text('Processing'), findsOneWidget); // Filter only.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Small screen and enlarged text fit all tabs and management', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: AdminDashboardScreen(store: adminTestStore()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final tab in ['Approvals', 'Orders', 'More']) {
      await tapText(tester, tab);
      expect(tester.takeException(), isNull);
    }
    await tapText(tester, 'Users & artisans');
    await tapText(tester, 'Pause');
    await tapText(tester, 'Confirm');
    expect(find.text('Paused'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
