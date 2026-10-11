import 'dart:async';

import 'package:artisan_marketplace/features/auth/services/auth_session.dart';
import 'package:artisan_marketplace/features/admin/services/admin_operations_repository.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/features/delivery/services/courier_google_sign_in.dart';
import 'package:artisan_marketplace/features/delivery/screens/delivery_login_screen.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late CourierGoogleSignIn service;
  setUp(() {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      mockUser: MockUser(
        uid: 'google-user',
        email: 'courier@example.com',
        displayName: 'Google Courier',
      ),
      signedIn: true,
    );
    service = CourierGoogleSignIn(
      auth: auth,
      firestore: db,
      authenticate: () => auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: 'mock-token'),
      ),
    );
  });
  test('Google account creates courier profile and retry preserves delivery preferences', () async {
    await expectLater(
      service.signIn(),
      throwsA(isA<CourierApprovalException>()),
    );
    final profile = await db.doc('users/google-user').get();
    expect(profile.data()?['role'], 'courier');
    expect(profile.data()?['courierApproval'], 'pending');
    expect(auth.currentUser, isNull);
    expect(profile.data()?['email'], 'courier@example.com');
    await db.doc('users/google-user').update({'deliveryOnline': true});
    final admin = MarketplaceRepository(
      firestore: db,
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'admin'), signedIn: true),
      loadRole: () async => UserRole.admin,
    );
    await AdminOperationsRepository(admin).reviewCourier('google-user', true);
    await db.doc('courierPublicProfiles/google-user').update({
      'area': 'Colombo',
    });
    expect(await service.signIn(), UserRole.courier);
    expect(
      (await db.doc('users/google-user').get()).data()?['deliveryOnline'],
      true,
    );
    expect(
      (await db.doc('courierPublicProfiles/google-user').get()).data()?['area'],
      'Colombo',
    );
  });
  for (final role in [UserRole.buyer, UserRole.artisan, UserRole.admin]) {
    test(
      'Existing $role role is retained without creating a courier profile',
      () async {
        await db.doc('users/google-user').set({
          'role': role.name,
          'displayName': 'Original name',
        });
        expect(await service.signIn(), role);
        expect(
          (await db.doc('users/google-user').get()).data()?['displayName'],
          'Original name',
        );
        expect(
          (await db.doc('courierPublicProfiles/google-user').get()).exists,
          false,
        );
      },
    );
  }
  test(
    'Cancellation creates no profile and invalid roles do not become couriers',
    () async {
      final cancelled = CourierGoogleSignIn(
        auth: auth,
        firestore: db,
        authenticate: () async => throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        ),
      );
      expect(await cancelled.signIn(), isNull);
      expect((await db.doc('users/google-user').get()).exists, false);
      await db.doc('users/google-user').set({'role': 'invalid'});
      await expectLater(service.signIn(), throwsA(isA<ProfileException>()));
      expect(
        (await db.doc('courierPublicProfiles/google-user').get()).exists,
        false,
      );
    },
  );
  testWidgets(
    'Google login runs without email fields and blocks duplicate taps',
    (tester) async {
      final completion = Completer<UserRole?>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryLoginScreen(
            googleSignIn: () {
              calls++;
              return completion.future;
            },
          ),
          routes: {
            AuthSession.route(UserRole.courier): (_) =>
                const Scaffold(body: Text('Courier workspace')),
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue with Google'));
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      await tester.tap(find.text('Continue with Google'));
      expect(calls, 1);
      completion.complete(UserRole.courier);
      await tester.pumpAndSettle();
      expect(find.text('Courier workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
