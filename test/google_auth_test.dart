import 'package:artisan_marketplace/features/auth/services/auth_session.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late MockUser user;
  setUp(() {
    db = FakeFirebaseFirestore();
    user = MockUser(
      uid: 'google-user',
      email: 'maker@example.com',
      displayName: 'Maker',
    );
    auth = MockFirebaseAuth(mockUser: user, signedIn: true);
  });
  Future<UserRole?> login(UserRole role) => AuthSession.signInWithGoogle(
    newAccountRole: role,
    auth: auth,
    db: db,
    authenticate: () async => auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: 'test-token'),
    ),
  );
  for (final role in [UserRole.buyer, UserRole.artisan, UserRole.courier]) {
    test('Google creates and restores a $role profile', () async {
      expect(await login(role), role);
      final saved = (await db.collection('users').doc(user.uid).get()).data()!;
      expect(saved['uid'], user.uid);
      expect(saved['email'], user.email);
      expect(saved['displayName'], 'Maker');
      expect(saved['role'], role.name);
      expect(saved['createdAt'], isNotNull);
      expect(await login(UserRole.buyer), role);
      expect((await db.collection('users').doc(user.uid).get()).data(), saved);
    });
  }
  test('existing admin role is preserved without profile writes', () async {
    await db.collection('users').doc(user.uid).set({
      'role': 'admin',
      'displayName': 'Existing',
    });
    expect(await login(UserRole.buyer), UserRole.admin);
    expect((await db.collection('users').doc(user.uid).get()).data(), {
      'role': 'admin',
      'displayName': 'Existing',
    });
  });
  test(
    'Google cannot create an administrator and failed setup signs out',
    () async {
      await expectLater(
        login(UserRole.admin),
        throwsA(isA<ProfileException>()),
      );
      expect(auth.currentUser, isNull);
      expect(
        (await db.collection('users').doc(user.uid).get()).exists,
        isFalse,
      );
    },
  );
  test('cancellation returns without creating a profile', () async {
    expect(
      await AuthSession.signInWithGoogle(
        newAccountRole: UserRole.buyer,
        auth: auth,
        db: db,
        authenticate: () async => throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        ),
      ),
      isNull,
    );
    expect((await db.collection('users').get()).docs, isEmpty);
  });
  test('invalid existing profile fails and signs out', () async {
    await db.collection('users').doc(user.uid).set({'role': 'unknown'});
    await expectLater(login(UserRole.buyer), throwsA(isA<ProfileException>()));
    expect(auth.currentUser, isNull);
    expect((await db.collection('users').doc(user.uid).get()).data(), {
      'role': 'unknown',
    });
  });
  test('Firebase authentication failure does not create a profile', () async {
    await expectLater(
      AuthSession.signInWithGoogle(
        newAccountRole: UserRole.buyer,
        auth: auth,
        db: db,
        authenticate: () async =>
            throw FirebaseAuthException(code: 'network-request-failed'),
      ),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(auth.currentUser?.uid, user.uid);
    expect((await db.collection('users').get()).docs, isEmpty);
  });
  test('missing Google configuration gives a useful message', () async {
    await expectLater(
      AuthSession.signInWithGoogle(
        newAccountRole: UserRole.buyer,
        auth: auth,
        db: db,
        authenticate: () async => throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      ),
      throwsA(
        isA<ProfileException>().having(
          (error) => error.message,
          'message',
          contains('not configured'),
        ),
      ),
    );
    expect((await db.collection('users').get()).docs, isEmpty);
  });
}
