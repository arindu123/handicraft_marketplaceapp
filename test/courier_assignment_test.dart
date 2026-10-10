import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/admin/models/admin_demo_store.dart';
import 'package:artisan_marketplace/features/admin/services/admin_operations_repository.dart';
import 'package:artisan_marketplace/features/admin/widgets/admin_courier_assignment.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MarketplaceRepository admin;
  late AdminOperationsRepository operations;
  MarketplaceRepository repo(String uid, UserRole role) =>
      MarketplaceRepository(
        firestore: db,
        auth: MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true),
        loadRole: () async => role,
      );
  setUp(() async {
    db = FakeFirebaseFirestore();
    admin = repo('admin', UserRole.admin);
    operations = AdminOperationsRepository(admin);
    for (final id in ['courier', 'courier2']) {
      await db.doc('users/$id').set({
        'role': 'courier',
        'active': true,
        'displayName': id,
      });
    }
    await db
        .doc('orders/order')
        .set(
          Order(
            id: 'order',
            buyerId: 'buyer',
            artisanId: 'maker',
            items: [],
            status: OrderStatus.confirmed,
            deliveryAddress: 'Colombo',
            paymentMethod: 'Cash on delivery',
            subtotal: 100,
            deliveryFee: 14,
            total: 114,
            createdAt: DateTime.utc(2026),
          ).toMap(),
        );
  });
  test(
    'Assign and reassign are audited; former courier loses control',
    () async {
      await operations.assignCourier(
        'order',
        'courier',
        expectedStatus: 'confirmed',
        expectedCourierId: null,
      );
      await operations.assignCourier(
        'order',
        'courier2',
        expectedStatus: 'courierAssigned',
        expectedCourierId: 'courier',
      );
      final order = (await db.doc('orders/order').get()).data()!;
      expect(order['courierId'], 'courier2');
      expect(order['status'], 'courierAssigned');
      final logs = (await db.collection('adminActivity').get()).docs;
      expect(logs, hasLength(2));
      expect(logs.last.data()['before']['courierId'], 'courier');
      await expectLater(
        repo('courier', UserRole.courier).advanceOrder('order'),
        throwsA(isA<MarketplaceFailure>()),
      );
      await repo('courier2', UserRole.courier).advanceOrder('order');
      expect(
        (await db.doc('orders/order').get()).data()!['status'],
        'pickedUp',
      );
      await expectLater(
        operations.assignCourier(
          'order',
          'courier',
          expectedStatus: 'pickedUp',
          expectedCourierId: 'courier2',
        ),
        throwsA(isA<MarketplaceFailure>()),
      );
      expect((await db.collection('adminActivity').get()).docs, hasLength(2));
    },
  );
  test(
    'Non-admin, paused courier, stale and unpacked orders cannot be assigned',
    () async {
      await expectLater(
        AdminOperationsRepository(repo('buyer', UserRole.buyer)).assignCourier(
          'order',
          'courier',
          expectedStatus: 'confirmed',
          expectedCourierId: null,
        ),
        throwsA(isA<MarketplaceFailure>()),
      );
      await db.doc('users/courier').update({'active': false});
      await expectLater(
        operations.assignCourier(
          'order',
          'courier',
          expectedStatus: 'confirmed',
          expectedCourierId: null,
        ),
        throwsA(isA<MarketplaceFailure>()),
      );
      await operations.assignCourier(
        'order',
        'courier2',
        expectedStatus: 'confirmed',
        expectedCourierId: null,
      );
      await db.doc('users/courier').update({'active': true});
      await expectLater(
        operations.assignCourier(
          'order',
          'courier',
          expectedStatus: 'confirmed',
          expectedCourierId: null,
        ),
        throwsA(isA<MarketplaceFailure>()),
      );
      await db.doc('orders/order').update({
        'status': 'pending',
        'courierId': null,
      });
      await expectLater(
        operations.assignCourier(
          'order',
          'courier',
          expectedStatus: 'pending',
          expectedCourierId: null,
        ),
        throwsA(isA<MarketplaceFailure>()),
      );
      expect((await db.collection('adminActivity').get()).docs, hasLength(1));
    },
  );
  testWidgets(
    'Assignment control saves selected courier and shows live owner',
    (tester) async {
      final store = AdminDemoStore(backend: admin);
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminCourierAssignment(
                store: store,
                order: AdminOrder(
                  'order',
                  'buyer',
                  'Mug',
                  'Studio',
                  114,
                  'confirmed',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('courier2').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assign courier'));
      await tester.pumpAndSettle();
      expect(
        (await db.doc('orders/order').get()).data()!['courierId'],
        'courier2',
      );
      expect(find.text('Current courier: courier2'), findsOneWidget);
      expect(find.text('Reassign courier'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
