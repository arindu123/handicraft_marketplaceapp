import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/app.dart';

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
  await tapVisible(tester, 'Continue');
}

Future<void> tapVisible(WidgetTester tester, String text) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Guest entry skips account validation after choosing a role', (
    tester,
  ) async {
    await openSignIn(tester);
    await tapVisible(tester, 'Continue without an account');
    expect(find.text('Artisan Marketplace'), findsOneWidget);
    expect(find.text('Enter your email address.'), findsNothing);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Sign Up');
    await tapVisible(tester, 'Continue without an account');
    expect(find.text('Artisan Marketplace'), findsOneWidget);
    expect(find.text('Enter your full name.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Sign in validates, toggles password visibility, and keeps role when switching pages',
    (tester) async {
      await openSignIn(tester, role: 'Buyer / Patron');
      expect(find.text('Buyer / Patron'), findsOneWidget);
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
        find.text('Sign in is not available yet. Please try again later.'),
        findsOneWidget,
      );
      expect(find.text('Artisan Marketplace'), findsNothing);
      await tapVisible(tester, 'Sign Up');
      expect(find.text('Create Collector Account'), findsOneWidget);
      expect(find.text('Full name'), findsOneWidget);
      await tapVisible(tester, 'Sign In');
      expect(find.text('Sign In to Collection'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Sign up checks name, password length and confirmation without pretending to create an account',
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
        find.text(
          'Account creation is not available yet. Please try again later.',
        ),
        findsOneWidget,
      );
      expect(find.text('Artisan Marketplace'), findsNothing);
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
