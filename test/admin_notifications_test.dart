import 'package:artisan_marketplace/features/admin/models/admin_demo_store.dart';
import 'package:artisan_marketplace/features/admin/screens/admin_management_screen.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MarketplaceRepository repo;
  late AdminDemoStore store;
  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = MarketplaceRepository(
      firestore: db,
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'admin'), signedIn: true),
      loadRole: () async => UserRole.admin,
    );
    await db.doc('artisanProfiles/maker').set({
      'studioName': 'Clay Studio',
      'verificationStatus': 'pending',
    });
  });
  tearDown(() => store.dispose());
  testWidgets(
    'Notification read state and preferences persist between sessions',
    (tester) async {
      store = AdminDemoStore(backend: repo);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminManagementScreen(
            section: AdminSection.notifications,
            store: store,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Application awaiting review'), findsOneWidget);
      expect(store.unreadNotifications, 1);
      await tester.tap(find.text('Mark as read'));
      await tester.pumpAndSettle();
      expect(store.unreadNotifications, 0);
      expect(find.text('Read'), findsOneWidget);
      await store.setNotifications(applications: false);
      await tester.pumpAndSettle();
      expect(
        (await db.doc('adminPreferences/admin').get()).data()!['applications'],
        false,
      );
      expect(store.notifications, isEmpty);
      final restored = AdminDemoStore(backend: repo);
      addTearDown(restored.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminManagementScreen(
            section: AdminSection.notifications,
            store: restored,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(restored.applicationNotifications, isFalse);
      expect(restored.readNoticeIds, hasLength(1));
      await restored.setNotifications(applications: true);
      await tester.pumpAndSettle();
      expect(restored.unreadNotifications, 0);
    },
  );
  testWidgets(
    'New complaint appears without reopening the notifications page',
    (tester) async {
      store = AdminDemoStore(backend: repo);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminManagementScreen(
            section: AdminSection.notifications,
            store: store,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await db.doc('marketplaceReports/report').set({
        'kind': 'Delivery', 'targetId': 'order', 'reporterId': 'courier',
        'reason': 'Wrong address',
        'notes': 'Contact customer',
      });
      await tester.pumpAndSettle();
      expect(find.text('Delivery complaint'), findsOneWidget);
      expect(store.unreadNotifications, 2);
    },
  );
}
