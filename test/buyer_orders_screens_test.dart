import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_orders_screens.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MarketplaceRepository repository;
  late BuyerDemo demo;

  Map<String, dynamic> orderData(OrderStatus status) => {
    'id': 'order-1',
    'buyerId': 'buyer-1',
    'artisanId': 'artisan-1',
    'courierId': status.index >= OrderStatus.courierAssigned.index
        ? 'courier-1'
        : null,
    'items': [
      {
        'productId': 'product-1',
        'productName': 'Backend pottery vase',
        'imageUrl': null,
        'unitPrice': 1200.0,
        'quantity': 1,
      },
    ],
    'status': status.name,
    'deliveryAddress': '12 Sample Street, Colombo',
    'paymentMethod': 'Cash on delivery',
    'subtotal': 1200.0,
    'deliveryFee': 0.0,
    'total': 1200.0,
    'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
    'currency': 'LKR',
  };

  setUp(() async {
    MarketplaceBackend.enabled = false;
    db = FakeFirebaseFirestore();
    repository = MarketplaceRepository(
      firestore: db,
      auth: MockFirebaseAuth(
        mockUser: MockUser(uid: 'buyer-1'),
        signedIn: true,
      ),
      loadRole: () async => UserRole.buyer,
    );
    demo = BuyerDemo(backend: repository);
    await db.doc('users/buyer-1').set({'role': 'buyer'});
    await db.doc('orders/order-1').set(orderData(OrderStatus.confirmed));
  });

  tearDown(() => demo.dispose());

  testWidgets('buyer orders show live Firestore assignment and progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: BuyerOrdersScreen(demo: demo)));
    await tester.pumpAndSettle();

    expect(find.text('Backend pottery vase'), findsOneWidget);
    expect(find.text('Artisan confirmed'), findsOneWidget);
    expect(find.text('Your courier is assigned'), findsNothing);
    expect(find.text('Leave a review'), findsNothing);

    await db.doc('orders/order-1').update({
      'status': OrderStatus.courierAssigned.name,
      'courierId': 'courier-1',
    });
    await tester.pumpAndSettle();
    expect(find.text('Courier assigned'), findsOneWidget);
    await tester.tap(find.text('View assignment'));
    await tester.pumpAndSettle();
    expect(find.text('Your courier is assigned'), findsOneWidget);

    await db.doc('orders/order-1').update({
      'status': OrderStatus.pickedUp.name,
    });
    await tester.pumpAndSettle();
    expect(find.text('Order details\n#order-1'), findsOneWidget);
    expect(find.text('Picked up'), findsWidgets);
    final showCode = find.text('Show delivery code');
    await tester.scrollUntilVisible(
      showCode,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(showCode);
    expect(find.text('\u2022\u2022\u2022\u2022\u2022\u2022'), findsOneWidget);
    await tester.tap(showCode);
    await tester.pumpAndSettle();
    expect(find.text('Delivery confirmation code'), findsOneWidget);
    expect(
      find.textContaining('Share it only when your parcel is handed'),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await db.doc('orders/order-1').update({
      'status': OrderStatus.delivered.name,
    });
    await tester.pumpAndSettle();
    final leaveReview = find.text('Leave a review');
    await tester.scrollUntilVisible(
      leaveReview,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(leaveReview);
    expect(leaveReview, findsOneWidget);
    await tester.tap(leaveReview);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Arrived safely.');
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();
    expect(
      (await db.doc('reviews/buyer-1_order-1_product-1').get()).exists,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
