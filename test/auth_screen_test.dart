import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
// Firebase's platform interfaces provide test doubles without a live backend.
// ignore: depend_on_referenced_packages
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/app.dart';
import 'package:artisan_marketplace/features/auth/models/marketplace_role.dart';
import 'package:artisan_marketplace/features/auth/widgets/auth_form.dart';
import 'package:artisan_marketplace/routes/route_names.dart';

class TestAuth extends FirebaseAuthPlatform {
  UserPlatform? signedInUser;
  @override
  UserPlatform? get currentUser => signedInUser;
  @override
  Future<void> signOut() async {
    signedInUser = null;
  }

  final resetEmails = <String>[];
  @override
  Future<void> sendPasswordResetEmail(
    String email, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    if (errorCode != null) throw FirebaseAuthException(code: errorCode!);
    resetEmails.add(email);
  }

  int deletions = 0;
  bool deleteFails = false;
  String? errorCode;
  Completer<UserCredentialPlatform>? pending;
  final calls = <({bool signUp, String email, String password})>[];

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) => this;

  Future<UserCredentialPlatform> authenticate(
    bool signUp,
    String email,
    String password,
  ) async {
    signedInUser = TestUser(this);
    calls.add((signUp: signUp, email: email, password: password));
    if (pending != null) return pending!.future;
    if (errorCode != null) throw FirebaseAuthException(code: errorCode!);
    return TestCredential(auth: this);
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
    String email,
    String password,
  ) => authenticate(false, email, password);

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
    String email,
    String password,
  ) => authenticate(true, email, password);
}

class TestCredential extends UserCredentialPlatform {
  TestCredential({required TestAuth auth})
    : super(auth: auth, user: TestUser(auth));
}

class TestMultiFactor extends MultiFactorPlatform {
  TestMultiFactor(super.auth);
}

class TestUser extends UserPlatform {
  TestUser(TestAuth auth)
    : super(
        auth,
        TestMultiFactor(auth),
        InternalUserDetails(
          userInfo: InternalUserInfo(
            uid: 'new-user-uid',
            email: 'potter@example.com',
            isAnonymous: false,
            isEmailVerified: false,
          ),
          providerData: [],
        ),
      );

  @override
  Future<void> delete() async {
    final testAuth = auth as TestAuth;
    testAuth.deletions++;
    if (testAuth.deleteFails) {
      throw FirebaseAuthException(code: 'network-request-failed');
    }
  }
}

class TestFirestore extends FirebaseFirestorePlatform {
  final writes = <({String path, Map<String, dynamic> data})>[];
  Map<String, dynamic>? profile = {'role': 'buyer'};
  String? readError;
  final reads = <String>[];
  Source? lastReadSource;
  bool fails = false;
  Completer<void>? pending;

  @override
  FirebaseFirestorePlatform delegateFor({
    required FirebaseApp app,
    required String databaseId,
  }) => this;

  @override
  CollectionReferencePlatform collection(String collectionPath) =>
      TestCollection(this, collectionPath);
}

class TestCollection extends CollectionReferencePlatform {
  TestCollection(super.firestore, super.path);

  @override
  DocumentReferencePlatform doc([String? path]) =>
      TestDocument(firestore, '${this.path}/$path');
}

class TestDocument extends DocumentReferencePlatform {
  TestDocument(super.firestore, super.path);
  @override
  Future<DocumentSnapshotPlatform> get([GetOptions? options]) async {
    final store = firestore as TestFirestore;
    store.reads.add(path);
    store.lastReadSource = options?.source;
    if (store.readError != null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: store.readError!,
      );
    }
    return DocumentSnapshotPlatform(
      store,
      path,
      store.profile,
      InternalSnapshotMetadata(hasPendingWrites: false, isFromCache: false),
    );
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    final store = firestore as TestFirestore;
    store.writes.add((path: path, data: data));
    if (store.pending != null) await store.pending!.future;
    if (store.fails) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
  }
}

Future<void> openSignIn(
  WidgetTester tester, {
  String role = 'Artisan / Studio Maker',
}) async {
  await tester.pumpWidget(const MyApp());
  await tester.ensureVisible(find.text('Sign In'));
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
  expect(find.text('Roles Selection'), findsOneWidget);
  await tapVisible(tester, role);
  await tapVisible(
    tester,
    role == 'Buyer / Patron' ? 'Continue to login' : 'Continue',
  );
}

Future<void> tapVisible(WidgetTester tester, String text) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final auth = TestAuth();
  final firestore = TestFirestore();
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = auth;
    FirebaseFirestorePlatform.instance = firestore;
  });
  setUp(() {
    auth.signedInUser = null;
    firestore.profile = {'role': 'buyer'};
    firestore.readError = null;
    firestore.reads.clear();
    auth.calls.clear();
    auth.errorCode = 'network-request-failed';
    auth.pending = null;
    auth.deletions = 0;
    auth.deleteFails = false;
    firestore.writes.clear();
    firestore.fails = false;
    firestore.pending = null;
  });

  Future<void> fillForm(WidgetTester tester, bool signUp) async {
    final fields = find.byType(TextFormField);
    if (signUp) await tester.enterText(fields.at(0), 'Studio Potter');
    await tester.enterText(fields.at(signUp ? 1 : 0), ' potter@example.com ');
    await tester.enterText(fields.at(signUp ? 2 : 1), ' password123 ');
    if (signUp) await tester.enterText(fields.at(3), ' password123 ');
  }

  for (final signUp in [false, true]) {
    for (final role in [
      MarketplaceRole.artisan,
      MarketplaceRole.buyer,
      if (!signUp) MarketplaceRole.admin,
      if (signUp) MarketplaceRole.courier,
    ]) {
      testWidgets(
        '${signUp ? 'Sign up' : 'Sign in'} preserves $role destination and prevents repeated submissions',
        (tester) async {
          auth.pending = Completer<UserCredentialPlatform>();
          String? destination;
          Object? destinationRole;
          await tester.pumpWidget(
            MaterialApp(
              initialRoute: '/auth',
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings.name == '/auth'
                    ? RouteSettings(name: '/auth', arguments: role)
                    : settings,
                builder: (context) {
                  if (settings.name == '/') return const SizedBox();
                  if (settings.name == '/auth') {
                    return AuthForm(isSignUp: signUp);
                  }
                  destination = settings.name;
                  destinationRole = settings.arguments;
                  return const Scaffold(
                    body: Text('Authenticated destination'),
                  );
                },
              ),
            ),
          );
          await fillForm(tester, signUp);
          final label = signUp ? role.signUpLabel : role.signInLabel;
          if (!signUp && role == MarketplaceRole.buyer) {
            await tester.ensureVisible(find.text(label));
            await tester.tap(find.text(label));
            await tester.pump();
            expect(find.text('Signing you in…'), findsOneWidget);
            expect(
              tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
              isNull,
            );
          } else {
            await tapVisible(tester, label);
            await tapVisible(tester, label);
          }
          tester.widget<TextField>(find.byType(TextField).last).onSubmitted!(
            '',
          );
          await tester.pump();
          expect(auth.calls, [
            (
              signUp: signUp,
              email: 'potter@example.com',
              password: ' password123 ',
            ),
          ]);
          expect(destination, isNull);
          expect(firestore.writes, isEmpty);
          if (signUp) firestore.pending = Completer<void>();
          auth.pending!.complete(TestCredential(auth: auth));
          await tester.pumpAndSettle();
          if (signUp) {
            expect(destination, isNull);
            await tapVisible(tester, label);
            expect(auth.calls, hasLength(1));
            expect(firestore.writes, hasLength(1));
            final write = firestore.writes.single;
            expect(write.path, 'users/new-user-uid');
            expect(write.data, {
              'uid': 'new-user-uid',
              'email': 'potter@example.com',
              'displayName': 'Studio Potter',
              'role': role.name,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            firestore.pending!.complete();
            await tester.pumpAndSettle();
          } else {
            expect(firestore.writes, isEmpty);
          }
          expect(auth.deletions, 0);
          expect(
            destination,
            signUp && role == MarketplaceRole.courier
                ? RouteNames.deliveryHome
                : RouteNames.marketplace,
          );
          expect(destinationRole, signUp ? role : MarketplaceRole.buyer);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final entry in {
    'email-already-in-use':
        'An account already exists with this email. Please sign in.',
    'invalid-email': 'Enter a valid email address.',
    'weak-password': 'Please choose a stronger password.',
    'user-not-found': 'The email or password is incorrect. Please try again.',
    'invalid-credential':
        'The email or password is incorrect. Please try again.',
    'wrong-password': 'The email or password is incorrect. Please try again.',
    'network-request-failed': 'Check your internet connection and try again.',
  }.entries) {
    testWidgets(
      'Firebase ${entry.key} shows a friendly error and allows retry',
      (tester) async {
        auth.errorCode = entry.key;
        await tester.pumpWidget(
          const MaterialApp(home: AuthForm(isSignUp: true)),
        );
        await fillForm(tester, true);
        await tapVisible(tester, 'Create Studio Account');
        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(AuthForm), findsOneWidget);
        await tapVisible(tester, 'Create Studio Account');
        expect(auth.calls, hasLength(2));
        expect(firestore.writes, isEmpty);
        expect(auth.deletions, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Admin signup is rejected before Auth or Firestore', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: const RouteSettings(arguments: MarketplaceRole.admin),
          builder: (_) => const AuthForm(isSignUp: true),
        ),
      ),
    );
    await fillForm(tester, true);
    await tapVisible(tester, 'Create Curator Account');
    expect(
      find.text('Administrator accounts cannot be created here.'),
      findsOneWidget,
    );
    expect(auth.calls, isEmpty);
    expect(firestore.writes, isEmpty);
  });

  for (final cleanupFails in [false, true]) {
    testWidgets(
      'Profile failure rolls back signup; cleanup failure = $cleanupFails',
      (tester) async {
        auth.errorCode = null;
        auth.deleteFails = cleanupFails;
        firestore.fails = true;
        await tester.pumpWidget(
          const MaterialApp(home: AuthForm(isSignUp: true)),
        );
        await fillForm(tester, true);
        await tapVisible(tester, 'Create Studio Account');
        expect(auth.deletions, 1);
        expect(firestore.writes, hasLength(1));
        expect(find.byType(AuthForm), findsOneWidget);
        expect(
          find.textContaining(
            cleanupFails
                ? 'could not finish account setup or remove'
                : 'Your new account was removed',
          ),
          findsOneWidget,
        );
        if (cleanupFails) {
          await tapVisible(tester, 'Create Studio Account');
          expect(auth.deletions, 2);
          expect(auth.calls, hasLength(1));
          expect(firestore.writes, hasLength(1));
          auth.deleteFails = false;
          auth.errorCode = 'network-request-failed';
          await tapVisible(tester, 'Create Studio Account');
          expect(auth.deletions, 3);
          expect(auth.calls, hasLength(2));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Profile rollback still runs after form disposal', (
    tester,
  ) async {
    auth.pending = Completer<UserCredentialPlatform>();
    firestore.fails = true;
    await tester.pumpWidget(const MaterialApp(home: AuthForm(isSignUp: true)));
    await fillForm(tester, true);
    await tapVisible(tester, 'Create Studio Account');
    await tester.pumpWidget(const SizedBox());
    auth.pending!.complete(TestCredential(auth: auth));
    await tester.pumpAndSettle();
    expect(firestore.writes, hasLength(1));
    expect(auth.deletions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Completing authentication after leaving the form is safe', (
    tester,
  ) async {
    auth.pending = Completer<UserCredentialPlatform>();
    await tester.pumpWidget(const MaterialApp(home: AuthForm(isSignUp: false)));
    await fillForm(tester, false);
    await tapVisible(tester, 'Sign In to Studio');
    await tester.pumpWidget(const SizedBox());
    auth.pending!.complete(TestCredential(auth: auth));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guest entry skips account validation after choosing a role', (
    tester,
  ) async {
    await openSignIn(tester);
    await tapVisible(tester, 'Continue without an account');
    expect(find.text('Artisan Dashboard'), findsOneWidget);
    expect(find.text('Enter your email address.'), findsNothing);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Sign Up');
    await tapVisible(tester, 'Continue without an account');
    expect(find.text('Artisan Dashboard'), findsOneWidget);
    expect(find.text('Enter your full name.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Sign in validates, toggles password visibility, and keeps role when switching pages',
    (tester) async {
      await openSignIn(tester, role: 'Buyer / Patron');
      expect(find.text('Good to see\nyou again.'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      await tapVisible(tester, 'Sign In to Collection');
      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'mypassword');
      await tapVisible(tester, 'Sign In to Collection');
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Show password'));
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isFalse,
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'collector@example.com',
      );
      await tapVisible(tester, 'Sign In to Collection');
      expect(
        find.text('Check your internet connection and try again.'),
        findsOneWidget,
      );
      expect(find.text('Artisan Dashboard'), findsNothing);
      await tapVisible(tester, 'Sign Up');
      expect(find.text('Create Collector Account'), findsOneWidget);
      expect(find.text('Full name'), findsOneWidget);
      await tapVisible(tester, 'Sign In');
      expect(find.text('Sign In to Collection'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Sign up checks name, password length and confirmation before Firebase',
    (tester) async {
      await openSignIn(tester);
      await tapVisible(tester, 'Sign Up');
      await tapVisible(tester, 'Create Studio Account');
      expect(find.text('Enter your full name.'), findsOneWidget);
      expect(find.text('Confirm your password.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Studio Potter');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'potter@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'short');
      await tester.enterText(find.byType(TextFormField).at(3), 'different');
      await tapVisible(tester, 'Create Studio Account');
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(find.text('Use at least 8 characters.'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).at(2), 'long-password');
      await tester.enterText(find.byType(TextFormField).at(3), 'long-password');
      await tapVisible(tester, 'Create Studio Account');
      expect(
        find.text('Check your internet connection and try again.'),
        findsOneWidget,
      );
      expect(find.text('Artisan Dashboard'), findsNothing);
      expect(auth.calls, [
        (signUp: true, email: 'potter@example.com', password: 'long-password'),
      ]);
    },
  );

  testWidgets(
    'Auth forms scroll on small screens with keyboard and enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openSignIn(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Sign In to Studio');
      expect(tester.takeException(), isNull);
      await tapVisible(tester, 'Sign Up');
      await tapVisible(tester, 'Create Studio Account');
      expect(tester.takeException(), isNull);
      await tapVisible(tester, 'Google');
      expect(
        find.text(
          'Google sign in is not available yet. Please try again later.',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, 'OK');
      expect(tester.takeException(), isNull);
    },
  );
}
