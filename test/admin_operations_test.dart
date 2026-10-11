import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/admin/models/admin_demo_store.dart';
import 'package:artisan_marketplace/features/admin/models/admin_operations.dart';
import 'package:artisan_marketplace/features/admin/screens/admin_management_screen.dart';
import 'package:artisan_marketplace/features/admin/services/admin_operations_repository.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/delivery_fee_policy.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  setUp(() {
    db = FakeFirebaseFirestore();
    admin = repo('admin', UserRole.admin);
    operations = AdminOperationsRepository(admin);
  });

  test(
    'Fee save persists actor and before/after activity atomically',
    () async {
      await operations.saveDeliveryPolicy(
        const DeliveryFeePolicy(fee: 350, freeDeliveryThreshold: 10000),
      );
      final policy = await admin.loadDeliveryPolicy();
      expect(policy.feeFor(9999), 350);
      expect(policy.feeFor(10000), 0);
      final entries = (await db.collection('adminActivity').get()).docs;
      expect(entries, hasLength(1));
      expect(entries.single.data()['actorId'], 'admin');
      expect(entries.single.data()['before'], isEmpty);
      expect(entries.single.data()['after']['fee'], 350);
      await operations.saveDeliveryPolicy(
        const DeliveryFeePolicy(fee: 400, freeDeliveryThreshold: 10000),
      );
      expect(
        (await db.collection('adminActivity').get()).docs.where(
          (entry) => entry.data()['before']['fee'] == 350,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'Non-admin and invalid amounts cannot change delivery settings',
    () async {
      final buyer = AdminOperationsRepository(repo('buyer', UserRole.buyer));
      await expectLater(
        buyer.saveDeliveryPolicy(const DeliveryFeePolicy(fee: 350)),
        throwsA(isA<MarketplaceFailure>()),
      );
      for (final value in [
        -1.0,
        double.nan,
        double.infinity,
        10.123,
        100001.0,
      ]) {
        await expectLater(
          operations.saveDeliveryPolicy(DeliveryFeePolicy(fee: value)),
          throwsA(isA<MarketplaceFailure>()),
        );
      }
      expect((await db.collection('marketplaceSettings').get()).docs, isEmpty);
      expect((await db.collection('adminActivity').get()).docs, isEmpty);
    },
  );

  test(
    'New LKR orders use settings; receipts and USD fees stay unchanged',
    () async {
      Product product(String id, String currency) => Product(
        id: id,
        artisanId: 'maker',
        name: 'Mug',
        category: 'Clay',
        price: 100,
        currency: currency,
        description: '',
        imageUrls: [],
        stock: 5,
        status: ProductStatus.active,
        createdAt: DateTime.utc(2026),
      );
      await db.doc('products/lkr').set(product('lkr', 'LKR').toMap());
      await db.doc('products/usd').set(product('usd', 'USD').toMap());
      final buyer = repo('buyer', UserRole.buyer);
      await operations.saveDeliveryPolicy(
        const DeliveryFeePolicy(fee: 350, freeDeliveryThreshold: 10000),
      );
      await buyer.cartQuantity('lkr', 1);
      final first = await buyer.checkout(
        'first',
        'Colombo',
        'Cash on delivery',
        expectedDeliveryFee: 350,
      );
      expect(first.deliveryFee, 350);
      await operations.saveDeliveryPolicy(
        const DeliveryFeePolicy(fee: 400, freeDeliveryThreshold: 10000),
      );
      final retry = await buyer.checkout(
        'first',
        'Colombo',
        'Cash on delivery',
      );
      expect(retry.total, first.total);
      await buyer.cartQuantity('lkr', 1);
      await expectLater(
        buyer.checkout(
          'changed',
          'Colombo',
          'Cash on delivery',
          expectedDeliveryFee: 350,
        ),
        throwsA(isA<MarketplaceFailure>()),
      );
      expect((await db.doc('orders/changed').get()).exists, isFalse);
      expect((await db.doc('products/lkr').get()).data()!['stock'], 4);
      expect((await buyer.userCollection('cart').get()).docs, hasLength(1));
      await buyer.cartQuantity('lkr', 0);
      await buyer.cartQuantity('usd', 1);
      expect(
        (await buyer.checkout(
          'usd',
          'Colombo',
          'Cash on delivery',
        )).deliveryFee,
        14,
      );
    },
  );

  test(
    'Report resolution preserves original issue and records activity',
    () async {
      await db.doc('orders/order/deliveryIssues/issue').set({
        'courierId': 'courier',
        'reason': 'Damaged parcel',
        'notes': 'Cracked mug',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026)),
      });
      final report = AdminReport.fromMap(
        'orders/order/deliveryIssues/issue',
        (await db.doc('orders/order/deliveryIssues/issue').get()).data()!,
      );
      await expectLater(
        operations.resolveReport(report, ''),
        throwsA(isA<MarketplaceFailure>()),
      );
      await operations.resolveReport(
        report,
        'Replacement arranged with the studio.',
      );
      expect(
        (await db.doc('reportResolutions/${report.resolutionId}').get())
            .data()!['resolvedBy'],
        'admin',
      );
      expect(
        (await db.doc(report.sourcePath).get()).data()!['notes'],
        'Cracked mug',
      );
      expect(
        (await db.collection('adminActivity').get()).docs.single
            .data()['action'],
        'Complaint resolved',
      );
    },
  );

  testWidgets('Admin fee settings validate and save on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = AdminDemoStore(backend: admin);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminManagementScreen(
          section: AdminSection.settings,
          store: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '-10');
    await tester.enterText(fields.at(1), '10000');
    await tester.ensureVisible(find.text('Save delivery fees'));
    await tester.tap(find.text('Save delivery fees'));
    await tester.pumpAndSettle();
    expect((await db.collection('adminActivity').get()).docs, isEmpty);
    await tester.ensureVisible(fields.at(0));
    await tester.enterText(fields.at(0), '350');
    await tester.ensureVisible(find.text('Save delivery fees'));
    await tester.tap(find.text('Save delivery fees'));
    await tester.pumpAndSettle();
    expect(
      (await db.doc('marketplaceSettings/deliveryLkr').get()).data()!['fee'],
      350,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Existing courier complaint can be resolved in admin Reports', (
    tester,
  ) async {
    await db.doc('orders/order/deliveryIssues/issue').set({
      'courierId': 'courier',
      'reason': 'Wrong address',
      'notes': 'Call the customer',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026)),
    });
    final store = AdminDemoStore(backend: admin);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminManagementScreen(
          section: AdminSection.reports,
          store: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Resolve complaint'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Resolve complaint'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolve complaint'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Address confirmed with customer.',
    );
    await tester.tap(find.text('Mark resolved'));
    await tester.pumpAndSettle();
    expect(store.reports.single.status, 'Resolved');
    expect(store.activity.single.actorId, 'admin');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Admin can record a complaint and see the actor in activity history', (tester) async {
    final store = AdminDemoStore(backend: admin);
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: AdminManagementScreen(section: AdminSection.reports, store: store)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Record complaint'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record complaint'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'p1');
    await tester.enterText(fields.at(1), 'Customer');
    await tester.enterText(fields.at(2), 'Wrong item received');
    await tester.enterText(fields.at(3), 'Customer contacted support.');
    await tester.ensureVisible(find.text('Save complaint'));
    await tester.tap(find.text('Save complaint'));
    await tester.pumpAndSettle();
    expect(store.reports.single.reason, 'Wrong item received');
    expect(store.activity.single.actorId, 'admin');
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: AdminManagementScreen(section: AdminSection.activity, store: store)));
    await tester.pumpAndSettle();
    expect(find.text('Complaint recorded'), findsOneWidget);
    expect(find.text('Admin: admin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
