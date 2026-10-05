import 'dart:async';

import 'package:artisan_marketplace/features/auth/models/marketplace_role.dart';
import 'package:artisan_marketplace/features/delivery/screens/delivery_login_screen.dart';
import 'package:artisan_marketplace/routes/route_names.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_screen_test.dart' show TestAuth, TestFirestore, tapVisible;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final auth = TestAuth();
  final store = TestFirestore();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = auth;
    FirebaseFirestorePlatform.instance = store;
  });

  setUp(() {
    auth.calls.clear();
    auth.signedInUser = null;
    auth.errorCode = null;
    auth.deletions = 0;
    auth.deleteFails = false;
    store.writes.clear();
    store.pending = null;
    store.fails = false;
  });

  Future<void> openSignup(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: RouteNames.deliveryLogin,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: RouteSettings(
            name: settings.name,
            arguments: settings.name == RouteNames.deliveryLogin
                ? AuthEntry.signUp
                : settings.arguments,
          ),
          builder: (_) => settings.name == RouteNames.deliveryHome
              ? const Scaffold(body: Text('Courier dashboard'))
              : const DeliveryLoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), ' Courier Name ');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      ' potter@example.com ',
    );
    await tester.enterText(find.byType(TextFormField).at(2), ' password123 ');
  }

  testWidgets(
    'Saves courier profile before navigation and prevents duplicate signup',
    (tester) async {
      await openSignup(tester);
      store.pending = Completer<void>();
      await tapVisible(tester, 'Sign Up');
      expect(auth.calls.single, (
        signUp: true,
        email: 'potter@example.com',
        password: ' password123 ',
      ));
      expect(store.writes.single.path, 'users/new-user-uid');
      expect(store.writes.single.data, {
        'uid': 'new-user-uid',
        'email': 'potter@example.com',
        'displayName': 'Courier Name',
        'role': 'courier',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      expect(find.text('Courier dashboard'), findsNothing);
      await tapVisible(tester, 'Creating account...');
      expect(auth.calls, hasLength(1));
      store.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Courier dashboard'), findsOneWidget);
      expect(auth.deletions, 0);
    },
  );

  testWidgets('Failed profile write removes new account and allows retry', (
    tester,
  ) async {
    await openSignup(tester);
    store.fails = true;
    await tapVisible(tester, 'Sign Up');
    expect(auth.deletions, 1);
    expect(
      find.textContaining('We could not save your profile.'),
      findsOneWidget,
    );
    expect(find.text('Courier dashboard'), findsNothing);
    await tapVisible(tester, 'Got it');
    store.fails = false;
    await tapVisible(tester, 'Sign Up');
    expect(find.text('Courier dashboard'), findsOneWidget);
  });

  testWidgets('Failed cleanup is retried before creating another account', (
    tester,
  ) async {
    await openSignup(tester);
    store.fails = true;
    auth.deleteFails = true;
    await tapVisible(tester, 'Sign Up');
    expect(find.textContaining('retry cleanup'), findsOneWidget);
    await tapVisible(tester, 'Got it');
    await tapVisible(tester, 'Sign Up');
    expect(auth.calls, hasLength(1));
    expect(auth.deletions, 2);
    await tapVisible(tester, 'Got it');
    auth.deleteFails = false;
    store.fails = false;
    await tapVisible(tester, 'Sign Up');
    expect(auth.calls, hasLength(2));
    expect(find.text('Courier dashboard'), findsOneWidget);
  });

  testWidgets(
    'Existing email shows an actionable error without writing a profile',
    (tester) async {
      await openSignup(tester);
      auth.errorCode = 'email-already-in-use';
      await tapVisible(tester, 'Sign Up');
      expect(
        find.text('An account already exists with this email. Please sign in.'),
        findsOneWidget,
      );
      expect(store.writes, isEmpty);
      expect(auth.deletions, 0);
    },
  );

  testWidgets('Phone input is rejected before calling email authentication', (
    tester,
  ) async {
    await openSignup(tester);
    await tester.enterText(find.byType(TextFormField).at(1), '0771234567');
    await tapVisible(tester, 'Sign Up');
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });
}
