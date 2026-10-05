import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:artisan_marketplace/shared/data/cloudinary_upload.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MarketplaceRepository repo;
  Product product({
    String id = 'p1',
    String artisan = 'artisan',
    double price = 48,
    int stock = 5,
  }) => Product(
    id: id,
    artisanId: artisan,
    name: 'Handmade mug',
    category: 'Stoneware',
    price: price,
    currency: 'USD',
    description: 'Clay mug',
    imageUrls: const [],
    stock: stock,
    status: ProductStatus.active,
    createdAt: DateTime.utc(2026),
  );
  MarketplaceRepository repository(String uid, UserRole role) =>
      MarketplaceRepository(
        firestore: db,
        auth: MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true),
        imageUploader: CloudinaryUpload(
          client: MockClient(
            (_) async => http.Response(
              '{"secure_url":"https://res.cloudinary.com/yrpisypt/image/upload/product.jpg"}',
              200,
            ),
          ),
        ),
        loadRole: () async => role,
      );
  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = repository('buyer', UserRole.buyer);
    await db.collection('products').doc('p1').set(product().toMap());
  });
  test(
    'Cart quantities and favorites persist and are isolated by UID',
    () async {
      await repo.cartQuantity('p1', 1, increment: true);
      await repo.cartQuantity('p1', 2, increment: true);
      expect(
        (await db.doc('users/buyer/cart/p1').get()).data()!['quantity'],
        3,
      );
      await repo.favorite('p1', true);
      expect(
        (await repo.userCollection('favorites').get()).docs.single
            .data()
            .keys
            .toSet(),
        {'productId', 'addedAt'},
      );
      expect(
        (await repository(
          'other',
          UserRole.buyer,
        ).userCollection('cart').get()).docs,
        isEmpty,
      );
      await repo.cartQuantity('p1', 0);
      await repo.favorite('p1', false);
      expect((await repo.userCollection('cart').get()).docs, isEmpty);
      expect((await repo.userCollection('favorites').get()).docs, isEmpty);
    },
  );
  test('Checkout snapshots current prices, persists one order, clears cart, and retries idempotently', () async {
    await repo.cartQuantity('p1', 2);
    await db.doc('products/p1').update({'price': 60});
    final order = await repo.checkout(
      'request1',
      '42 Main Street',
      'Cash on delivery',
    );
    expect(order.status, OrderStatus.pending);
    expect(order.items.single.unitPrice, 60);
    expect(order.subtotal, 120);
    expect(order.total, 134);
    expect(order.buyerId, 'buyer');
    expect(order.artisanId, 'artisan');
    expect((await db.doc('products/p1').get()).data()!['stock'], 3);
    expect((await repo.userCollection('cart').get()).docs, isEmpty);
    expect(
      (await repo.checkout(
        'request1',
        '42 Main Street',
        'Cash on delivery',
      )).id,
      order.id,
    );
    expect((await db.collection('orders').get()).docs, hasLength(1));
  });
  test('Missing product fails checkout without clearing cart', () async {
    await repo.cartQuantity('p1', 1);
    await db.doc('products/p1').delete();
    await expectLater(
      repo.checkout('failed', '42 Main Street', 'Cash on delivery'),
      throwsA(isA<MarketplaceFailure>()),
    );
    expect((await repo.userCollection('cart').get()).docs, hasLength(1));
    expect((await db.collection('orders').get()).docs, isEmpty);
  });
  test(
    'Checkout stores delivery contact and pickup details for the courier',
    () async {
      await db.doc('artisanProfiles/artisan').set({
        'studioName': 'Clay Studio',
        'location': 'Colombo 07',
      });
      await repo.cartQuantity('p1', 1);
      final order = await repo.checkout(
        'contact-order',
        '42 Flower Road',
        'Cash on delivery',
        recipientName: 'Pasindu',
        recipientPhone: '0771234567',
        deliveryInstructions: 'Ring the bell',
      );
      final saved = Order.fromMap(
        (await db.doc('orders/contact-order').get()).data()!,
      );
      expect(saved.recipientName, 'Pasindu');
      expect(saved.recipientPhone, '0771234567');
      expect(saved.pickupAddress, 'Colombo 07');
      expect(saved.pickupName, 'Clay Studio');
      expect(saved.deliveryInstructions, 'Ring the bell');
      expect(order.toMap(), saved.toMap());
    },
  );
  test('Mixed artisans and insufficient stock are rejected', () async {
    await db
        .doc('products/p2')
        .set(product(id: 'p2', artisan: 'other').toMap());
    await repo.cartQuantity('p1', 1);
    await repo.cartQuantity('p2', 1);
    await expectLater(
      repo.checkout('mixed', 'Address', 'Cash on delivery'),
      throwsA(isA<MarketplaceFailure>()),
    );
    expect((await repo.userCollection('cart').get()).docs, hasLength(2));
    await expectLater(
      repo.cartQuantity('p1', 6),
      throwsA(isA<MarketplaceFailure>()),
    );
  });
  test(
    'Artisan product ownership comes from Auth, and other owners cannot edit',
    () async {
      final artisan = repository('maker', UserRole.artisan);
      final saved = await artisan.saveProduct(
        product(id: '', artisan: 'spoofed'),
        [
          Uint8List.fromList([1, 2, 3]),
        ],
      );
      expect(saved.artisanId, 'maker');
      expect(saved.imageUrls, hasLength(1));
      expect(
        (await db.doc('products/${saved.id}').get()).data()!['artisanId'],
        'maker',
      );
      await expectLater(
        artisan.saveProduct(product(), []),
        throwsA(isA<MarketplaceFailure>()),
      );
      await expectLater(
        repo.saveProduct(product(id: ''), []),
        throwsA(isA<MarketplaceFailure>()),
      );
    },
  );
  test('Failed image upload validation leaves no product document', () async {
    final artisan = repository('maker', UserRole.artisan);
    await expectLater(
      artisan.saveProduct(product(id: 'failed'), [
        Uint8List(10 * 1024 * 1024 + 1),
      ]),
      throwsA(isA<MarketplaceFailure>()),
    );
    expect((await db.doc('products/failed').get()).exists, isFalse);
  });
  test(
    'Buyer artisan and courier share one order and permitted lifecycle',
    () async {
      await repo.cartQuantity('p1', 1);
      await repo.checkout('shared', 'Address', 'Cash on delivery');
      final artisan = repository('artisan', UserRole.artisan);
      await artisan.advanceOrder('shared');
      expect(
        (await artisan.orders('artisanId').first).single.status,
        OrderStatus.confirmed,
      );
      final courier = repository('courier', UserRole.courier);
      expect((await courier.availableDeliveries().first).single.id, 'shared');
      await courier.acceptDelivery('shared');
      expect(await courier.availableDeliveries().first, isEmpty);
      await expectLater(
        repository('other-courier', UserRole.courier).acceptDelivery('shared'),
        throwsA(isA<MarketplaceFailure>()),
      );
      for (final status in [
        OrderStatus.pickedUp,
        OrderStatus.onTheWay,
        OrderStatus.delivered,
      ]) {
        await courier.advanceOrder(
          'shared',
          confirmationCode: status == OrderStatus.delivered ? '123456' : null,
        );
        expect((await repo.orders('buyerId').first).single.status, status);
      }
      await expectLater(
        courier.advanceOrder('shared'),
        throwsA(isA<MarketplaceFailure>()),
      );
    },
  );
}
