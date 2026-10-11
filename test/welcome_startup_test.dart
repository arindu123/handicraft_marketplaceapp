import 'dart:async';

import 'package:artisan_marketplace/app.dart';
import 'package:artisan_marketplace/features/auth/screens/welcome_screen.dart';
import 'package:artisan_marketplace/shared/widgets/brand_splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets(
    'Brand splash shows for four seconds then welcome waits for initialization',
    (tester) async {
      final ready = Completer<void>();
      await tester.pumpWidget(MyApp(initialization: ready.future));
      expect(find.byType(BrandSplashScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
      await tester.pump(const Duration(milliseconds: 3900));
      expect(find.byType(BrandSplashScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byType(BrandSplashScreen), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      await tester.tap(find.text('Explore the marketplace'));
      await tester.pump();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      ready.complete();
      await tester.pumpAndSettle();
      expect(find.text('Discover Handmade Products'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Returning from another app shows splash then roles', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore the marketplace'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(BrandSplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2900));
    expect(find.byType(BrandSplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byType(BrandSplashScreen), findsNothing);
    expect(find.text('Roles Selection'), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inactive notification does not restart the entry flow', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(BrandSplashScreen), findsNothing);
  });

  testWidgets('Initialization failure leaves Welcome visible', (tester) async {
    final ready = Completer<void>();
    await tester.pumpWidget(MyApp(initialization: ready.future));
    ready.completeError(StateError('Offline'));
    await tester.pump(const Duration(seconds: 4));
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
