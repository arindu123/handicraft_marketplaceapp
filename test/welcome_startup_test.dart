import 'dart:async';

import 'package:artisan_marketplace/app.dart';
import 'package:artisan_marketplace/features/auth/screens/welcome_screen.dart';
import 'package:artisan_marketplace/shared/widgets/brand_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Welcome appears before initialization and stays until navigation',
    (tester) async {
      final ready = Completer<void>();
      await tester.pumpWidget(MyApp(initialization: ready.future));
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(BrandSplashScreen), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(WelcomeScreen), findsOneWidget);
      await tester.tap(find.text('Explore the marketplace'));
      await tester.pump();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      ready.complete();
      await tester.pumpAndSettle();
      expect(find.text('Handmade.\nMade for you.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Initialization failure leaves Welcome visible', (tester) async {
    final ready = Completer<void>();
    await tester.pumpWidget(MyApp(initialization: ready.future));
    ready.completeError(StateError('Offline'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(
      find.text('Unable to start the app. Please close it and try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
