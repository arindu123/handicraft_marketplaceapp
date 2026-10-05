import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Fixtures are isolated to the test database, never the running application.
void main() {
  late FakeFirebaseFirestore db;
  late MarketplaceRepository repository;
  Product product(String id, double price, {int stock = 4}) => Product(
    id: id,
    artisanId: 'maker',
    name: 'Backend piece $id',
    category: 'Textiles',
    price: price,
    currency: 'USD',
    description: 'Backend description',
    imageUrls: [],
    stock: stock,
    status: ProductStatus.active,
    createdAt: DateTime.utc(2026),
  );
  setUp(() {
    MarketplaceBackend.enabled = false;
    db = FakeFirebaseFirestore();
    repository = MarketplaceRepository(
      firestore: db,
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'buyer'), signedIn: true),
      loadRole: () async => UserRole.buyer,
    );
  });
  Future<void> phone(
    WidgetTester tester,
    Widget screen, {
    double width = 390,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        240,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(tester.element(finder.first), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'Home starts empty and updates from backend without rebuilding the app',
    (tester) async {
      await phone(tester, BuyerMarketplace(backend: repository), width: 320);
      expect(find.textContaining('No pieces found'), findsOneWidget);
      expect(find.textContaining('Terracotta Ribbed Vase'), findsNothing);
      await db
          .collection('products')
          .doc('new')
          .set(product('new', 900).toMap());
      await tester.pumpAndSettle();
      await tap(tester, 'Backend piece new');
      expect(find.text(r'$900.00'), findsWidgets);
      expect(find.text('4 available'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      await db.collection('products').doc('new').update({'stock': 0});
      await tester.pumpAndSettle();
      expect(find.text('Out of stock'), findsOneWidget);
      final add = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add to cart'),
      );
      expect(add.onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Search does not hide prices above 200 and responds to backend changes',
    (tester) async {
      await db
          .collection('products')
          .doc('high')
          .set(product('high', 900).toMap());
      final state = BuyerDemo(backend: repository);
      addTearDown(state.dispose);
      await phone(tester, BuyerSearch(demo: state), width: 320);
      expect(find.text('1 pieces found'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'missing');
      await tester.pumpAndSettle();
      expect(find.text('0 pieces found'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      await tap(tester, 'Filters');
      await tester.enterText(
        find.widgetWithText(TextField, 'Maximum price'),
        '100',
      );
      await tester.pumpAndSettle();
      expect(find.text('0 pieces found'), findsOneWidget);
      await tap(tester, 'Clear all');
      expect(find.text('1 pieces found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Saved address and real COD checkout survive Address Payment Review',
    (tester) async {
      await db.collection('products').doc('p1').set(product('p1', 60).toMap());
      await repository.cartQuantity('p1', 2);
      final state = BuyerDemo(backend: repository);
      addTearDown(state.dispose);
      await phone(tester, BuyerCheckout(demo: state), width: 320);
      expect(find.text('No saved addresses yet.'), findsOneWidget);
      final next = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continue to payment  \u2192'),
      );
      expect(next.onPressed, isNull);
      await tap(tester, 'Add a new address');
      final fields = find.byType(TextFormField);
      for (var i = 0; i < 6; i++) {
        await tester.enterText(
          fields.at(i),
          [
            'Test buyer',
            'Test street',
            'Test city',
            '12345',
            'Test country',
            '0123456789',
          ][i],
        );
      }
      await tap(tester, 'Save address');
      expect(
        (await repository.userCollection('addresses').get()).docs,
        hasLength(1),
      );
      await tap(tester, 'Continue to payment  \u2192');
      expect(find.text('Payment method'), findsOneWidget);
      expect(find.text('Cash on delivery'), findsOneWidget);
      await tap(tester, 'Stripe card payment - Demo');
      expect(find.text('Stripe demo preview'), findsOneWidget);
      expect((await db.collection('orders').get()).docs, isEmpty);
      await tap(tester, 'Back to payment methods');

      expect(find.textContaining('Visa'), findsNothing);
      await tap(tester, 'Continue to review  \u2192');
      expect(find.text('Review your order'), findsOneWidget);
      await tap(tester, 'Place order');
      final order = (await db.collection('orders').get()).docs.single.data();
      expect(order['status'], 'pending');
      expect(order['total'], 134);
      expect(order['paymentMethod'], 'Cash on delivery');
      expect((await repository.userCollection('cart').get()).docs, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'No connection never falls back to products or fake order success',
    () async {
      final state = BuyerDemo();
      addTearDown(state.dispose);
      expect(state.products, isEmpty);
      expect(state.orders, isEmpty);
      expect(state.name, isEmpty);
      await expectLater(state.checkout(), throwsA(isA<MarketplaceFailure>()));
    },
  );
}
