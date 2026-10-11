import 'package:artisan_marketplace/features/admin/widgets/admin_image_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    bool active = true,
    bool reducedMotion = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reducedMotion),
          child: Scaffold(body: AdminImageCarousel(active: active)),
        ),
      ),
    );
    await tester.pump();
  }

  double page(WidgetTester tester) =>
      tester.widget<PageView>(find.byType(PageView)).controller!.page!;
  Future<void> advance(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets(
    'Three photos auto-scroll forward and back without leaving the carousel',
    (tester) async {
      await open(tester);
      expect(page(tester), 0);
      await advance(tester);
      expect(page(tester), 1);
      await advance(tester);
      expect(page(tester), 2);
      await advance(tester);
      expect(page(tester), 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Manual swipes work in both directions and inactive tab pauses scrolling',
    (tester) async {
      await open(tester);
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(page(tester), 1);
      await tester.drag(find.byType(PageView), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(page(tester), 0);
      await open(tester, active: false);
      await tester.pump(const Duration(seconds: 10));
      expect(page(tester), 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Reduced motion disables automatic movement', (tester) async {
    await open(tester, reducedMotion: true);
    await tester.pump(const Duration(seconds: 10));
    expect(page(tester), 0);
    await tester.pumpWidget(const SizedBox());
  });
}
