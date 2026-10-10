import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Saved layout filters categories and offers discovery when empty',
    (tester) async {
      MarketplaceBackend.enabled = false;
      final demo = BuyerDemo()..catalogError = null;
      addTearDown(demo.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (const bool.fromEnvironment('PREVIEW')) {
        for (final entry in {
          'CormorantGaramond': 'lib/core/theme/cormorant_garamond.ttf',
          'Roboto': 'lib/core/theme/cormorant_garamond.ttf',
          'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        }.entries) {
          await (FontLoader(
            entry.key,
          )..addFont(rootBundle.load(entry.value))).load();
        }
      }
      await tester.pumpWidget(MaterialApp(home: BuyerFavorites(demo: demo)));
      await tester.pumpAndSettle();
      expect(find.text('Your favourites start here'), findsOneWidget);
      if (const bool.fromEnvironment('PREVIEW')) {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('previews/saved-empty.png'),
        );
      }
      demo.favorites.addAll([
        const DemoProduct(
          'Clay cup',
          'Ceramics',
          20,
          'Maker',
          'Studio',
          '',
          '',
          0,
          id: 'cup',
        ),
        const DemoProduct(
          'Woven bag',
          'Textiles',
          40,
          'Maker',
          'Studio',
          '',
          '',
          0,
          id: 'bag',
        ),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: BuyerFavorites(key: UniqueKey(), demo: demo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 saved pieces'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ceramics'));
      await tester.pumpAndSettle();
      expect(find.text('1 saved piece'), findsOneWidget);
      expect(find.text('Woven bag'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
