import 'dart:typed_data';

import 'package:artisan_marketplace/shared/data/cloudinary_upload.dart';
import 'package:artisan_marketplace/shared/data/profile_repository.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/features/delivery/widgets/delivery_profile_editor.dart';
import 'package:artisan_marketplace/features/delivery/widgets/delivery_profile_widgets.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late ProfileRepository repo;
  bool uploadFails = false;
  setUp(() async {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(mockUser: MockUser(uid: 'pasindu'), signedIn: true);
    uploadFails = false;
    repo = ProfileRepository(
      firestore: db,
      auth: auth,
      uploader: CloudinaryUpload(
        client: MockClient((_) async {
          if (uploadFails) throw http.ClientException('offline');
          return http.Response(
            '{"secure_url":"https://res.cloudinary.com/avatar.jpg"}',
            200,
          );
        }),
      ),
    );
    await db.collection('users').doc('pasindu').set({
      'displayName': 'Pasindu Kavishka',
      'email': 'pasindu@example.com',
      'role': 'courier',
      'uid': 'pasindu',
      'createdAt': 'original',
    });
  });

  test(
    'Loads the signed-in profile and persists edits without changing identity',
    () async {
      expect((await repo.watch().first)['displayName'], 'Pasindu Kavishka');
      await repo.save(
        displayName: ' Pasindu K ',
        area: ' Colombo ',
        photo: Uint8List.fromList([1, 2, 3]),
      );
      final saved = await repo.watch().first;
      expect(saved['displayName'], 'Pasindu K');
      expect(saved['area'], 'Colombo');
      expect(saved['photoUrl'], 'https://res.cloudinary.com/avatar.jpg');
      expect(saved['role'], 'courier');
      expect(saved['email'], 'pasindu@example.com');
      expect(saved['createdAt'], 'original');
      await repo.save(displayName: 'Pasindu', area: 'Galle');
      expect((await repo.watch().first)['photoUrl'], saved['photoUrl']);
    },
  );

  test('Upload failure leaves saved profile untouched', () async {
    uploadFails = true;
    await expectLater(
      repo.save(
        displayName: 'Changed',
        area: 'Galle',
        photo: Uint8List.fromList([1]),
      ),
      throwsA(isA<MarketplaceFailure>()),
    );
    expect((await repo.watch().first)['displayName'], 'Pasindu Kavishka');
    expect((await repo.watch().first).containsKey('photoUrl'), isFalse);
  });

  test('Courier availability persists and rejects other roles', () async {
    await repo.setDeliveryAvailability(true);
    final online = await repo.watch().firstWhere(
      (profile) => profile['deliveryOnline'] == true,
    );
    expect(online['deliveryOnline'], isTrue);
    await repo.setDeliveryAvailability(false);
    final offline = await repo.watch().firstWhere(
      (profile) => profile['deliveryOnline'] == false,
    );
    expect(offline['deliveryOnline'], isFalse);
    await db.collection('users').doc('pasindu').update({'role': 'buyer'});
    await expectLater(
      repo.setDeliveryAvailability(true),
      throwsA(isA<MarketplaceFailure>()),
    );
    expect((await repo.watch().first)['deliveryOnline'], isFalse);
  });

  test('Rejects invalid fields and oversized photos', () async {
    await expectLater(
      repo.save(displayName: ' ', area: ''),
      throwsA(isA<MarketplaceFailure>()),
    );
    await expectLater(
      repo.save(
        displayName: 'Pasindu',
        area: '',
        photo: Uint8List(5 * 1024 * 1024 + 1),
      ),
      throwsA(isA<MarketplaceFailure>()),
    );
  });

  test('Guest cannot edit a profile', () async {
    await auth.signOut();
    await expectLater(
      repo.save(displayName: 'Guest', area: ''),
      throwsA(isA<MarketplaceFailure>()),
    );
  });

  testWidgets('Profile editor displays saved name and saves changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final profile = (await tester.runAsync(() => repo.watch().first))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      DeliveryProfileEditor(repository: repo, profile: profile),
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    expect(find.text('PK'), findsOneWidget);
    expect(find.byTooltip('Choose profile photo'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Full name'), 150,
      scrollable: find.byType(Scrollable).first);
    expect(find.text('Pasindu Kavishka'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Pasindu Updated');
    await tester.scrollUntilVisible(
      find.text('Delivery area'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.descendant(
        of: find.widgetWithText(DeliveryProfileField, 'Delivery area'),
        matching: find.byType(TextFormField),
      ),
      'Kandy',
    );
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Open editor'), findsOneWidget);
    final saved = await tester.runAsync(() => repo.watch().first);
    expect(saved!['displayName'], 'Pasindu Updated');
    expect(saved['area'], 'Kandy');
  });
}
