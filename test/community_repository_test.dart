import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:artisan_marketplace/shared/data/community_repository.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';

void main() {
  late FakeFirebaseFirestore db;
  late CommunityRepository repo;
  setUp(() {
    db = FakeFirebaseFirestore();
    repo = CommunityRepository(
      firestore: db,
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'buyer'), signedIn: true),
    );
  });
  test(
    'Conversation is reused and messages use authenticated sender and streams',
    () async {
      final id = await repo.conversation('artisan');
      expect(await repo.conversation('artisan'), id);
      await repo.send(id, ' Hello artisan ');
      final message = (await repo.messages(id).first).docs.single.data();
      expect(message['senderId'], 'buyer');
      expect(message['text'], 'Hello artisan');
      expect(message['readAt'], isNull);
      expect(
        (await repo.inbox().first).docs.single.data()['lastMessage'],
        'Hello artisan',
      );
      await expectLater(repo.send(id, ''), throwsA(isA<MarketplaceFailure>()));
    },
  );
  test(
    'Reviews require delivered owned order and prevent duplicates',
    () async {
      await db.doc('users/buyer').set({'role': 'buyer'});
      final order = Order(
        id: 'order',
        buyerId: 'buyer',
        artisanId: 'artisan',
        items: const [
          OrderItem(
            productId: 'product',
            productName: 'Vase',
            unitPrice: 40,
            quantity: 1,
          ),
        ],
        status: OrderStatus.pending,
        deliveryAddress: 'Address',
        paymentMethod: 'Cash on delivery',
        subtotal: 40,
        deliveryFee: 14,
        total: 54,
        createdAt: DateTime.utc(2026),
      );
      await db.doc('orders/order').set(order.toMap());
      await expectLater(
        repo.review('order', 'product', 5, 'Lovely'),
        throwsA(isA<MarketplaceFailure>()),
      );
      await db.doc('orders/order').update({'status': 'delivered'});
      await repo.review('order', 'product', 5, 'Lovely');
      expect((await repo.reviews('artisan').first).docs, hasLength(1));
      final productReviews = (await repo.productReviews('product').first).docs;
      expect(productReviews, hasLength(1));
      expect(productReviews.single.data()['comment'], 'Lovely');
      expect(productReviews.single.data()['rating'], 5);
      expect((await repo.productReviews('another-product').first).docs, isEmpty);
      await expectLater(
        repo.review('order', 'product', 4, 'Again'),
        throwsA(isA<MarketplaceFailure>()),
      );
      await expectLater(
        repo.review('order', 'wrong', 5, 'Lovely'),
        throwsA(isA<MarketplaceFailure>()),
      );
      await expectLater(
        repo.review('order', 'product', 9, 'Lovely'),
        throwsA(isA<MarketplaceFailure>()),
      );
    },
  );
  test(
    'Profile creation starts pending and normal edits preserve verification',
    () async {
      await repo.saveProfile(
        studioName: 'Studio',
        location: 'Kandy',
        bio: 'Pottery',
      );
      expect(
        (await db.doc('artisanProfiles/buyer').get())
            .data()!['verificationStatus'],
        'pending',
      );
      await db.doc('artisanProfiles/buyer').update({
        'verificationStatus': 'verified',
      });
      await repo.saveProfile(
        studioName: 'New studio',
        location: 'Kandy',
        bio: 'Clay',
      );
      final data = (await db.doc('artisanProfiles/buyer').get()).data()!;
      expect(data['verificationStatus'], 'verified');
      expect(data['studioName'], 'New studio');
    },
  );
}
