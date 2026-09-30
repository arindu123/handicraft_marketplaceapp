import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/shared/models/craftisan_demo_messages.dart';
import 'package:artisan_marketplace/shared/widgets/craftisan_messaging.dart';

void main() {
  testWidgets('Buyer search combines location and artisan filters', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final demo = BuyerDemo();
    addTearDown(demo.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BuyerSearch(demo: demo),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Colombo'));
    await tester.pumpAndSettle();
    expect(find.text('Filter Artifacts · 1 active'), findsOneWidget);
    expect(find.text('1 pieces found'), findsOneWidget);

    await tester.tap(find.text('Elena Rostova'));
    await tester.pumpAndSettle();
    expect(find.text('Filter Artifacts · 2 active'), findsOneWidget);
    expect(find.text('1 pieces found'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Filter Artifacts · 0 active'), findsOneWidget);
    expect(find.text('3 pieces found'), findsOneWidget);
  });

  testWidgets(
    'Buyer message is immediately visible in the shared conversation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const CraftisanConversationScreen(
            viewer: DemoMessageAuthor.buyer,
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextField),
        'Can you share care advice?',
      );
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();

      expect(find.text('Can you share care advice?'), findsOneWidget);
      expect(
        craftisanDemoMessages.messages.last.text,
        'Can you share care advice?',
      );
    },
  );
}
