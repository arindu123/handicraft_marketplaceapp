import 'package:artisan_marketplace/features/buyer/rotating_product_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget banner(
  List<String> images, {
  bool reduced = false,
  bool slide = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: SizedBox(
      height: 178,
      child: RotatingProductBanner(
        imageKeys: images,
        slide: slide,
        imageBuilder: (_, i) => Text(images[i]),
      ),
    ),
  ),
);

void main() {
  testWidgets('Card photos slide left and finish on the next image', (
    tester,
  ) async {
    await tester.pumpWidget(banner(['front', 'back'], slide: true));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 325));
    final translations = tester.widgetList<FractionalTranslation>(
      find.byType(FractionalTranslation),
    );
    expect(translations.any((w) => w.translation.dx < 0), isTrue);
    expect(translations.any((w) => w.translation.dx > 0), isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('front'), findsNothing);
    expect(find.text('back'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Rotates, fades and wraps without leaving timers on disposal', (
    tester,
  ) async {
    await tester.pumpWidget(banner(['mug', 'vase']));
    expect(find.text('mug'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('vase'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('mug'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('mug'), findsOneWidget);
    expect(find.text('vase'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Handles product removal, empty catalogue and reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(banner(['mug', 'vase']));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpWidget(banner(['mug']));
    await tester.pumpAndSettle();
    expect(find.text('mug'), findsOneWidget);
    await tester.pumpWidget(banner([]));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(banner(['mug', 'vase'], reduced: true));
    await tester.pump(const Duration(seconds: 15));
    expect(find.text('mug'), findsOneWidget);
    expect(find.text('vase'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
