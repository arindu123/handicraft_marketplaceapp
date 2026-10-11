import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/features/buyer/collector_profile_sections.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late BuyerDemo demo;
  setUp(() async {
    MarketplaceBackend.enabled = false;
    db = FakeFirebaseFirestore();
    await db.doc('users/buyer').set({
      'displayName': 'Nimal Perera',
      'email': 'nimal@example.com',
      'role': 'buyer',
    });
  });
  tearDown(() => demo.dispose());

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    demo = BuyerDemo(
      backend: MarketplaceRepository(
        firestore: db,
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'buyer'),
          signedIn: true,
        ),
        loadRole: () async => UserRole.buyer,
      ),
    );
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(home: BuyerProfile(demo: demo)));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(target.last), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(target.last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Profile statistics follow persisted saved items, quantities and orders',
    (tester) async {
      await open(tester);
      expect(find.text('Nimal Perera'), findsOneWidget);
      expect(find.text('nimal@example.com'), findsOneWidget);
      expect(
        tester
            .widget<CollectorStatistics>(find.byType(CollectorStatistics))
            .saved,
        0,
      );
      // Counts include persisted items even if a product is absent from the catalog.
      await db.doc('users/buyer/favorites/piece').set({'productId': 'piece'});
      await db.doc('users/buyer/cart/piece').set({
        'productId': 'piece',
        'quantity': 3,
      });
      await db.doc('orders/order-1').set({
        'id': 'order-1',
        'buyerId': 'buyer',
        'artisanId': 'maker',
        'items': [
          {
            'productId': 'piece',
            'productName': 'Handmade bowl',
            'unitPrice': 120.0,
            'quantity': 1,
          },
        ],
        'status': 'pending',
        'deliveryAddress': 'Colombo',
        'paymentMethod': 'Cash on delivery',
        'subtotal': 120.0,
        'deliveryFee': 0.0,
        'total': 120.0,
        'currency': 'LKR',
        'createdAt': DateTime.utc(2026).toIso8601String(),
      });
      await tester.pumpAndSettle();
      final stats = tester.widget<CollectorStatistics>(
        find.byType(CollectorStatistics),
      );
      expect((stats.saved, stats.bag, stats.orders), (1, 3, 1));
      await db.doc('users/buyer/favorites/piece').delete();
      await db.doc('users/buyer/cart/piece').update({'quantity': 2});
      await tester.pumpAndSettle();
      final updated = tester.widget<CollectorStatistics>(
        find.byType(CollectorStatistics),
      );
      expect((updated.saved, updated.bag, updated.orders), (0, 2, 1));
      expect(find.text('Rating'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Addresses reuse the working editor without a checkout requirement',
    (tester) async {
      await open(tester);
      await tap(tester, 'Addresses');
      expect(find.text('Delivery Addresses'), findsOneWidget);
      expect(find.text('No saved addresses yet.'), findsOneWidget);
      expect(
        find.text('Your bag is empty. Add a piece before continuing.'),
        findsNothing,
      );
      await tap(tester, 'Add a new address');
      final fields = find.byType(TextFormField);
      const values = [
        'Nimal',
        '12 Craft Lane',
        'Colombo',
        '00100',
        'Sri Lanka',
        '0771234567',
      ];
      for (var i = 0; i < values.length; i++) {
        await tester.ensureVisible(fields.at(i));
        await tester.enterText(fields.at(i), values[i]);
      }
      await tester.ensureVisible(find.text('Save address'));
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();
      final saved = await db.collection('users/buyer/addresses').get();
      expect(saved.docs.single.data()['address'], '12 Craft Lane');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Profile information and logout cancellation keep the account intact',
    (tester) async {
      await open(tester);
      await tap(tester, 'Profile Information');
      expect(find.byTooltip('Choose profile photo'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Nimal Silva');
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      await tap(tester, 'Log Out');
      expect(find.text('Log out of Craftisan?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(demo.isSignedIn, isTrue);
      expect(
        (await db.doc('users/buyer').get()).data()!['displayName'],
        'Nimal Silva',
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(1024, 768),
  ]) {
    testWidgets('Profile scrolls at 200 percent text on $size', (tester) async {
      await open(tester, size: size, scale: 2);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
