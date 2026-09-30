import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/features/admin/models/admin_demo_store.dart';
import 'package:artisan_marketplace/features/admin/screens/admin_dashboard_screen.dart';
import 'package:artisan_marketplace/features/admin/screens/admin_management_screen.dart';

void main() {
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
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  testWidgets(
    'Users opens selected artisan and preserves search after review',
    (t) async {
      await t.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(const MaterialApp(home: AdminDashboardScreen()));
      await t.pumpAndSettle();
      await tap(t, 'More');
      await tap(t, 'Users & artisans');
      await t.enterText(find.byType(TextField), 'Clay House');
      await t.pumpAndSettle();
      await tap(t, 'Review Profile');
      expect(find.text('Clay House'), findsNWidgets(2));
      expect(find.text('Nugegoda'), findsOneWidget);
      expect(find.text('2 products in demo catalogue'), findsOneWidget);
      expect(find.text('Verification status'), findsOneWidget);
      expect(find.text('Account status'), findsOneWidget);
      await tap(t, 'Verify artisan');
      await tap(t, 'Cancel');
      expect(find.text('Pending'), findsOneWidget);
      await tap(t, 'Verify artisan');
      await tap(t, 'Confirm');
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Verify artisan'), findsNothing);
      await tap(t, 'Pause in demo');
      await tap(t, 'Confirm');
      expect(find.text('Paused'), findsOneWidget);
      await tap(t, 'Reactivate in demo');
      await tap(t, 'Confirm');
      await tap(t, 'Back to Users');
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        'Clay House',
      );
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == 'Clay House'),
        findsOneWidget,
      );
      await tap(t, 'Review Profile');
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    },
  );

  testWidgets(
    'Non-artisans have no review action; approved applicant retains verification',
    (t) async {
      final store = AdminDemoStore();
      addTearDown(store.dispose);
      store.users.addAll([
        AdminDirectoryItem('Demo Courier', 'Courier · Colombo'),
        AdminDirectoryItem('Demo Admin', 'Admin · Colombo'),
      ]);
      store.decide(store.approvals.first, true);
      await t.pumpWidget(
        MaterialApp(
          home: AdminManagementScreen(
            section: AdminSection.users,
            store: store,
          ),
        ),
      );
      await t.pumpAndSettle();
      for (final query in ['Buyer', 'Courier', 'Admin']) {
        await t.enterText(find.byType(TextField), query);
        await t.pumpAndSettle();
        expect(find.text('Review Profile'), findsNothing);
      }
      await t.enterText(find.byType(TextField), 'Earth & Ember');
      await t.pumpAndSettle();
      await tap(t, 'Review Profile');
      expect(find.text('Earth & Ember Studio'), findsNWidgets(2));
      expect(find.text('Galle, Sri Lanka'), findsOneWidget);
      expect(find.text('AP-108 · Approved'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Verify artisan'), findsNothing);
      expect(
        store.users.where((u) => u.name == 'Earth & Ember Studio'),
        hasLength(1),
      );
    },
  );
}
