import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/features/delivery/widgets/delivery_banner.dart';

void main() {
  testWidgets(
    'Banner advances, reverses, allows swipes and disposes its timer',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DeliveryBanner())),
      );
      final pages = tester.widget<PageView>(find.byType(PageView)).controller!;
      expect(pages.page, 0);
      for (final expected in [1, 2, 1, 0]) {
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(pages.page, expected);
      }
      await tester.drag(find.byType(PageView), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(pages.page, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    },
  );
}
