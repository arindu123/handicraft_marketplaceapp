import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MarketplaceRepository repository;
  setUp(() async {
    MarketplaceBackend.enabled = false;
    db = FakeFirebaseFirestore();
    repository = MarketplaceRepository(
      firestore: db,
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'buyer'), signedIn: true),
      loadRole: () async => UserRole.buyer,
    );
    await db.doc('orders/order-1').set({
      'id': 'order-1',
      'buyerId': 'buyer',
      'artisanId': 'artisan',
      'items': [
        {
          'productId': 'vase',
          'productName': 'Vase',
          'unitPrice': 120.0,
          'quantity': 1,
        },
      ],
      'status': 'pending',
      'deliveryAddress': 'Colombo',
      'paymentMethod': 'Cash on delivery',
      'subtotal': 120.0,
      'deliveryFee': 14.0,
      'total': 134.0,
      'currency': 'LKR',
      'createdAt': DateTime.utc(2026).toIso8601String(),
    });
  });

  testWidgets('live milestone alerts exclude initial and unchanged snapshots', (
    tester,
  ) async {
    final demo = BuyerDemo(backend: repository);
    await tester.pumpAndSettle();
    expect(demo.orderAlerts, isEmpty);
    for (final status in BuyerOrderStatus.values.skip(1).take(5)) {
      await db.doc('orders/order-1').update({'status': status.name});
      await tester.pumpAndSettle();
      expect(demo.orderAlerts, [
        'Order #order-1: ${BuyerDemo.statusMessage(status)}',
      ]);
      demo.orderAlerts.clear();
      await db.doc('orders/order-1').update({
        'updatedAt': DateTime.utc(2026, 1, status.index + 1).toIso8601String(),
      });
      await tester.pumpAndSettle();
      expect(demo.orderAlerts, isEmpty);
    }
    demo.dispose();
  });

  testWidgets(
    'bell opens persisted updates and reading opens the matching order',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await db.doc('users/buyer/notifications/order-1_confirmed').set({
        'orderId': 'order-1',
        'status': 'confirmed',
        'title': 'Order update',
        'body': 'Your artisan has confirmed your order.',
        'read': false,
        'createdAt': Timestamp.now(),
      });
      await tester.pumpWidget(
        MaterialApp(home: BuyerMarketplace(backend: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Order notifications'));
      await tester.pumpAndSettle();
      expect(
        find.text('Your artisan has confirmed your order.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Your artisan has confirmed your order.'));
      await tester.pumpAndSettle();
      expect(find.text('Order details\n#order-1'), findsOneWidget);
      expect(
        (await db.doc('users/buyer/notifications/order-1_confirmed').get())
            .data()!['read'],
        true,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
