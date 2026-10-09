import 'package:artisan_marketplace/features/buyer/handicraft_navigation_bar.dart';
import 'package:artisan_marketplace/features/buyer/handicraft_showcase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Six products alternate in pairs with a parcel animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 92,
          height: 66,
          child: HandicraftShowcase(imageBuilder: (_, i) => Text('Product $i')),
        ),
      ),
    );
    for (var pair = 0; pair < 3; pair++) {
      expect(find.text('Product ${pair * 2}'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Product ${pair * 2 + 1}'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(ValueKey('parcel-${pair * 3 + 2}')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2800));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('Product 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Parcel animation includes flight and the hand pressing BUY', (
    tester,
  ) async {
    await (FontLoader('sans-serif')
          ..addFont(rootBundle.load('lib/core/theme/cormorant_garamond.ttf')))
        .load();
    tester.view.physicalSize = const Size(300, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColoredBox(
            color: const Color(0xFFFFE68A),
            child: HandicraftShowcase(
              imageBuilder: (_, i) => Text('Product $i'),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/craft-flight.png'),
    );
    await tester.pump(const Duration(milliseconds: 2400));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/craft-hand-click.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Reduced motion keeps a static craft', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: HandicraftShowcase(imageBuilder: (_, i) => Text('Product $i')),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Product 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Centred craft carousel rotates and preserves destination indexes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 180);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await (FontLoader('Roboto')
            ..addFont(rootBundle.load('lib/core/theme/cormorant_garamond.ttf')))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      int? destination;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: HandicraftNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (index) => destination = index,
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage(HandicraftNavigationBar.atlas),
          tester.element(find.byType(HandicraftNavigationBar)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.search), findsNothing);
      expect(find.byKey(const ValueKey('vase')), findsOneWidget);
      await tester.tap(find.text('Saved'));
      expect(destination, 2);
      await tester.tap(find.byTooltip('Explore handmade products'));
      expect(destination, 1);
      await tester.tap(find.text('Cart'));
      expect(destination, 3);
      await tester.tap(find.text('Profile'));
      expect(destination, 4);
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('basket')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('previews/handicraft-navigation.png'),
      );
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('parcel-2')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1200));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('previews/handicraft-parcel.png'),
      );
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('elephant')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
