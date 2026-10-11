import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/app.dart';

void main() {
  testWidgets('Onboarding stays on the current story until navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore the marketplace'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 15));
    expect(find.text('Discover Handmade Products'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Empower Artisans'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Welcome, next, back, swipe and completion navigate correctly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Craftisan Marketplace logo'), findsOneWidget);
    await tester.tap(find.text('Explore the marketplace'));
    await tester.pumpAndSettle();
    expect(find.text('Discover Handmade Products'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Empower Artisans'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous page'));
    await tester.pumpAndSettle();
    expect(find.text('Discover Handmade Products'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text('Empower Artisans'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Your Role'));
    await tester.pumpAndSettle();
    expect(find.text('Roles Selection'), findsOneWidget);
    expect(find.text('Full name'), findsNothing);
    expect(find.text('Explore the marketplace'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skip opens role selection before authentication', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore the marketplace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Roles Selection'), findsOneWidget);
  });

  testWidgets('Small screens with large text scroll without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Explore the marketplace'));
    await tester.tap(find.text('Explore the marketplace'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
