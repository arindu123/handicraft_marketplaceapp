import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('Local home scroll and interactions at scale $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const BuyerMarketplace(preview: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A little craft.\nA lot of comfort.'), findsOneWidget);
      expect(find.text('1 / 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Dismiss promotion'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Dismiss promotion'), findsNothing);
      final scroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Collect All'),
        220,
        scrollable: scroll,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Collect All')),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Collect All'));
      await tester.pumpAndSettle();
      expect(find.text('Collected for preview'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Artisan Picks'),
        220,
        scrollable: scroll,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cart').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Your preview bag is empty'), findsOneWidget);
      await tester.tap(find.text('Account').last);
      await tester.pumpAndSettle();
      expect(find.text('Local preview account'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
