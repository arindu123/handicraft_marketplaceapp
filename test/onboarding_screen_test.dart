import 'package:artisan_marketplace/features/auth/screens/onboarding_screen.dart';
import 'package:artisan_marketplace/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app({double scale = 1, bool reducedMotion = false}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      disableAnimations: reducedMotion,
    ),
    child: child!,
  ),
  home: const OnboardingScreen(),
  routes: {
    RouteNames.roleSelection: (_) =>
        const Scaffold(body: Text('Existing role selection')),
  },
);

void main() {
  testWidgets('Continue, back, swipe, and final action use existing route', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Discover Handmade Products'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Empower Artisans'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous page'));
    await tester.pumpAndSettle();
    expect(find.text('Discover Handmade Products'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Shop with Delivery'), findsOneWidget);
    await tester.tap(find.text('Choose Your Role'));
    await tester.pumpAndSettle();
    expect(find.text('Existing role selection'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('Skip works immediately with reduced motion', (tester) async {
    await tester.pumpWidget(app(reducedMotion: true));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Existing role selection'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(1024, 768),
    const Size(568, 320),
  ]) {
    testWidgets('Stories fit $size with large text and safe insets', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(scale: 2));
      await tester.pumpAndSettle();
      for (var page = 0; page < 3; page++) {
        expect(tester.takeException(), isNull);
        final scroll = find
            .descendant(
              of: find.byType(PageView),
              matching: find.byType(SingleChildScrollView),
            )
            .first;
        await tester.drag(scroll, const Offset(0, -1000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (page < 2) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        }
      }
      await tester.tap(find.text('Choose Your Role'));
      await tester.pumpAndSettle();
      expect(find.text('Existing role selection'), findsOneWidget);
    });
  }
}
