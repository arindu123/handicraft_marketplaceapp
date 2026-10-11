import 'package:artisan_marketplace/features/delivery/screens/delivery_login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_screen_test.dart' show TestAuth;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final auth = TestAuth();
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = auth;
  });
  setUp(() {
    auth.errorCode = null;
    auth.resetEmails.clear();
    auth.calls.clear();
  });

  Future<void> openReset(WidgetTester tester, {String email = ''}) async {
    await tester.pumpWidget(const MaterialApp(home: DeliveryLoginScreen()));
    await tester.pump();
    if (email.isNotEmpty) {
      await tester.enterText(find.byType(TextFormField).first, email);
    }
    await tester.ensureVisible(find.text('Forgot Password?'));
    await tester.tap(find.text('Forgot Password?'));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> send(WidgetTester tester) async {
    await tester.tap(find.text('Send reset email'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('courier reset uses entered email without requiring a password', (
    tester,
  ) async {
    await openReset(tester, email: ' courier@example.com ');
    expect(
      find.widgetWithText(TextFormField, 'courier@example.com'),
      findsOneWidget,
    );
    await send(tester);
    expect(auth.resetEmails, ['courier@example.com']);
    expect(auth.calls, isEmpty);
    expect(find.text('Check your email'), findsOneWidget);
    await tester.tap(find.text('Back to Log In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('courier reset rejects missing and invalid email', (
    tester,
  ) async {
    await openReset(tester);
    await send(tester);
    expect(find.text('Enter your email address.'), findsOneWidget);
    final emailField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(emailField, 'invalid');
    await send(tester);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(auth.resetEmails, isEmpty);
  });

  testWidgets('courier reset shows network error and allows retry', (
    tester,
  ) async {
    auth.errorCode = 'network-request-failed';
    await openReset(tester, email: 'courier@example.com');
    await send(tester);
    expect(
      find.text('Check your internet connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Check your email'), findsNothing);
    auth.errorCode = null;
    await send(tester);
    expect(auth.resetEmails, ['courier@example.com']);
    expect(find.text('Check your email'), findsOneWidget);
  });
}
