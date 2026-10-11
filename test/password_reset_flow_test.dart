import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

import 'auth_screen_test.dart' show TestAuth;

import 'package:flutter_test/flutter_test.dart';

import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/auth/screens/password_reset_screens.dart';
import 'package:artisan_marketplace/routes/app_routes.dart';
import 'package:artisan_marketplace/routes/route_names.dart';

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
  });

  testWidgets('Reset email network failure stays on the request screen', (
    tester,
  ) async {
    auth.errorCode = 'network-request-failed';
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: RouteNames.passwordResetRequest,
        routes: AppRoutes.routes,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'person@example.com',
    );
    await tester.ensureVisible(find.text('Send Reset Email'));
    await tester.tap(find.text('Send Reset Email'));
    await tester.pumpAndSettle();
    expect(
      find.text('Check your internet connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('CHECK YOUR EMAIL'), findsNothing);
    expect(auth.resetEmails, isEmpty);
  });

  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'Password reset sends a real email request and returns to sign in',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          initialRoute: RouteNames.signIn,
          routes: AppRoutes.routes,
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Forgot password?');
      expect(find.text('Recover Your Passcode'), findsOneWidget);
      await tap(tester, 'Send Reset Email');
      expect(find.text('Enter your email address.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'collector@example.com',
      );
      await tap(tester, 'Send Reset Email');
      expect(auth.resetEmails, ['collector@example.com']);
      expect(find.text('CHECK YOUR EMAIL'), findsOneWidget);
      expect(find.text('Password Reset Successful!'), findsNothing);
      expect(find.text('collector@example.com'), findsOneWidget);
      expect(find.text('Try Again in 30s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      await tap(tester, 'Try Again');
      expect(auth.resetEmails, [
        'collector@example.com',
        'collector@example.com',
      ]);
      expect(find.textContaining('Request accepted.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      auth.errorCode = 'network-request-failed';
      await tap(tester, 'Try Again');
      expect(
        find.text('Check your internet connection and try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('Request accepted.'), findsNothing);
      expect(auth.resetEmails, hasLength(2));
      await tap(tester, 'Back to Sign In');
      expect(find.text('Welcome back to Craftisan'), findsOneWidget);
    },
  );
  testWidgets('Confirmation fits a small phone at 200 percent text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const PasswordResetSuccessScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Back to Sign In'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
