import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/app.dart';
import 'package:artisan_marketplace/features/auth/services/auth_session.dart';
import 'package:artisan_marketplace/features/auth/widgets/auth_form.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart'
    show UserRole;

import 'auth_screen_test.dart'
    show TestAuth, TestUser, TestFirestore, tapVisible;

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
    auth.signedInUser = TestUser(auth);
    auth.errorCode = null;
    store.profile = {'role': 'buyer'};
    store.readError = null;
    store.reads.clear();
  });

  test(
    'No session restores the welcome flow without reading Firestore',
    () async {
      auth.signedInUser = null;
      expect(await AuthSession.restore(), isNull);
      expect(store.reads, isEmpty);
    },
  );

  for (final role in [
    UserRole.buyer,
    UserRole.artisan,
    UserRole.courier,
    UserRole.admin,
  ]) {
    testWidgets('Restores $role using the saved profile', (tester) async {
      store.profile = {'role': role.name};
      final restored = await AuthSession.restore();
      expect(restored, role);
      expect(store.reads, ['users/new-user-uid']);
      await tester.pumpWidget(MyApp(initialRole: restored));
      await tester.pumpAndSettle();
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      String? name;
      navigator.popUntil((route) {
        name = route.settings.name;
        return true;
      });
      expect(name, AuthSession.route(role));
      expect(tester.takeException(), isNull);
    });
  }

  for (final failure in [
    'missing',
    'permission-denied',
    'unavailable',
    'invalid-role',
  ]) {
    testWidgets('Sign-in blocks entry for $failure profile', (tester) async {
      if (failure == 'missing') store.profile = null;
      if (failure == 'invalid-role') store.profile = {'role': 'invalid-role'};
      if (failure == 'permission-denied' || failure == 'unavailable') {
        store.readError = failure;
      }
      await tester.pumpWidget(
        const MaterialApp(home: AuthForm(isSignUp: false)),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'buyer@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tapVisible(tester, 'Sign In to Studio');
      expect(store.reads, ['users/new-user-uid']);
      expect(find.byType(AuthForm), findsOneWidget);
      expect(
        find.textContaining(
          failure == 'missing'
              ? 'profile is missing'
              : failure == 'unavailable'
              ? 'internet connection'
              : failure == 'invalid-role'
              ? 'cannot access'
              : 'could not be accessed',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Logout signs out and clears the navigation stack', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/session',
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (context) {
            if (settings.name == '/session') {
              pageContext = context;
              return const Scaffold(body: Text('Session'));
            }
            return const Scaffold(body: Text('Welcome'));
          },
        ),
      ),
    );
    await AuthSession.logout(pageContext);
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
    expect(find.text('Session'), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('Startup profile errors remain on welcome and are visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(sessionError: 'Your account profile is missing.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your account profile is missing.'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
