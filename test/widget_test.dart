import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/app.dart';

void main() {
  testWidgets('Welcome, next, back, swipe and completion navigate correctly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    expect(find.text('Craftisan'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Next: Kiln Provenance'), findsOneWidget);
    await tester.tap(find.text('Next: Kiln Provenance'));
    await tester.pumpAndSettle();
    expect(find.text('Next: Direct Patronage'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous page'));
    await tester.pumpAndSettle();
    expect(find.text('Next: Kiln Provenance'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text('Next: Direct Patronage'), findsOneWidget);
    await tester.tap(find.text('Next: Direct Patronage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skip reaches the existing app screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Artisan Marketplace'), findsOneWidget);
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
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Next: Kiln Provenance'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Next: Direct Patronage'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
