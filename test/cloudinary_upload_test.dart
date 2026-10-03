import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:artisan_marketplace/shared/data/cloudinary_upload.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';

void main() {
  test(
    'Unsigned multipart request sends preset and file and reads secure_url',
    () async {
      final uploader = CloudinaryUpload(
        client: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://api.cloudinary.com/v1_1/yrpisypt/image/upload',
          );
          expect(request.method, 'POST');
          expect(
            request.headers['content-type'],
            contains('multipart/form-data'),
          );
          expect(request.body, contains('name="upload_preset"'));
          expect(request.body, contains('craftisan_products'));
          expect(request.body, contains('name="file"'));
          expect(request.body, isNot(contains('api_secret')));
          return http.Response(
            '{"secure_url":"https://res.cloudinary.com/image.jpg"}',
            200,
          );
        }),
      );
      expect(
        await uploader.upload(Uint8List.fromList([1, 2, 3])),
        'https://res.cloudinary.com/image.jpg',
      );
    },
  );
  for (final response in [
    http.Response('denied', 400),
    http.Response('invalid json', 200),
    http.Response('{}', 200),
    http.Response('{"secure_url":"http://unsafe/image.jpg"}', 200),
  ]) {
    test('Rejects invalid upload response ${response.body}', () async {
      final uploader = CloudinaryUpload(
        client: MockClient((_) async => response),
      );
      await expectLater(
        uploader.upload(Uint8List.fromList([1])),
        throwsFormatException,
      );
    });
  }
  test(
    'Upload failure leaves no product, and retry saves the secure URL',
    () async {
      final db = FakeFirebaseFirestore();
      var fail = true;
      final repo = MarketplaceRepository(
        firestore: db,
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'artisan'),
          signedIn: true,
        ),
        loadRole: () async => UserRole.artisan,
        imageUploader: CloudinaryUpload(
          client: MockClient((_) async {
            expect((await db.collection('products').get()).docs, isEmpty);
            if (fail) throw http.ClientException('offline');
            return http.Response(
              '{"secure_url":"https://res.cloudinary.com/image.jpg"}',
              200,
            );
          }),
        ),
      );
      final draft = Product(
        id: 'p',
        artisanId: 'ignored',
        name: 'Vase',
        category: 'Clay',
        price: 20,
        currency: 'USD',
        description: '',
        imageUrls: [],
        stock: 1,
        status: ProductStatus.active,
        createdAt: DateTime.utc(2026),
      );
      await expectLater(
        repo.saveProduct(draft, [
          Uint8List.fromList([1]),
        ]),
        throwsA(isA<MarketplaceFailure>()),
      );
      expect((await db.doc('products/p').get()).exists, isFalse);
      fail = false;
      await repo.saveProduct(draft, [
        Uint8List.fromList([1]),
      ]);
      expect((await db.doc('products/p').get()).data()!['imageUrls'], [
        'https://res.cloudinary.com/image.jpg',
      ]);
    },
  );
}
