import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'cart uses live catalog and persisted quantities without sample data',
    (tester) async {
      MarketplaceBackend.enabled = false;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final db = FakeFirebaseFirestore();
      final repository = MarketplaceRepository(
        firestore: db,
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'buyer'),
          signedIn: true,
        ),
        loadRole: () async => UserRole.buyer,
      );
      final demo = BuyerDemo(backend: repository);
      await db
          .doc('products/vase')
          .set(
            Product(
              id: 'vase',
              artisanId: 'maker',
              name: 'Live clay vase',
              category: 'Clay',
              price: 1800,
              currency: 'LKR',
              description: 'Handmade',
              imageUrls: [],
              stock: 5,
              status: ProductStatus.active,
              createdAt: DateTime.utc(2026),
            ).toMap(),
          );
      await tester.pumpWidget(MaterialApp(home: BuyerCart(demo: demo)));
      await tester.pumpAndSettle();
      expect(find.text('Your cart is empty.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Checkout (0)'),
            )
            .onPressed,
        isNull,
      );
      await tester.scrollUntilVisible(
        find.text('Live clay vase'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Live clay vase'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, 1000));
      await tester.pumpAndSettle();
      await db.doc('users/buyer/cart/vase').set({
        'productId': 'vase',
        'quantity': 2,
      });
      await tester.pumpAndSettle();
      expect(find.text('Cart (2)'), findsOneWidget);
      expect(find.text('Your cart is empty.'), findsNothing);
      await db.doc('products/vase').update({'price': 2000.0});
      await tester.pumpAndSettle();
      expect(demo.subtotal, 4000);
      await tester.tap(find.byTooltip('Clear cart'));
      await tester.pumpAndSettle();
      expect((await db.collection('users/buyer/cart').get()).docs, isEmpty);
      expect(find.text('Your cart is empty.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await db.doc('users/buyer/favorites/vase').set({'productId': 'vase'});
      await tester.pumpWidget(MaterialApp(home: BuyerFavorites(demo: demo)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Add to cart'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Add to cart'));
      await tester.pumpAndSettle();
      expect(
        (await db.doc('users/buyer/cart/vase').get()).data()!['quantity'],
        1,
      );
      expect(find.text('Live clay vase added to cart'), findsOneWidget);
      await db.doc('products/vase').update({'stock': 0});
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Out of stock'),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      demo.dispose();
    },
  );
}
