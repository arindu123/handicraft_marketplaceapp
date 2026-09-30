import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/features/delivery/models/delivery_order.dart';
import 'package:artisan_marketplace/features/delivery/screens/delivery_home_screen.dart';
import 'package:artisan_marketplace/features/delivery/widgets/delivery_status_widgets.dart';

void main() {
  test('Delivery advances one stage at a time and completion is terminal', () {
    final order = DeliveryOrder.demoOrders().first;
    for (final expected in DeliveryStatus.values) {
      expect(order.status, expected);
      expect(order.delivered, expected == DeliveryStatus.delivered);
      order.advance();
    }
    order.advance();
    expect(order.status, DeliveryStatus.delivered);
    expect(order.status.action, isNull);
  });

  testWidgets('Courier accepts and progresses a delivery on a small screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: DeliveryHomeScreen()));
    await tester.pumpAndSettle();
    Future<void> tap(String label) async {
      final finder = find.text(label);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tap('Orders');
    expect(find.text('Pending'), findsNWidgets(2));
    await tap('Handcrafted ceramic vase');
    final sheet = find.byType(BottomSheet);
    final pickup = find.descendant(
      of: sheet,
      matching: find.text('Oread Pottery Studio, Colombo 07'),
    );
    final destination = find.descendant(
      of: sheet,
      matching: find.text('42 Flower Road, Colombo 03'),
    );
    expect(
      tester.getTopLeft(pickup).dy,
      lessThan(tester.getTopLeft(find.text('Accept Delivery')).dy),
    );
    expect(
      tester.getTopLeft(destination).dy,
      lessThan(tester.getTopLeft(find.text('Accept Delivery')).dy),
    );
    await tap('Accept Delivery');
    expect(find.text('Delivery Accepted'), findsOneWidget);
    final tracker = find.byType(DeliveryStatusTracker);
    for (final stage in DeliveryStatus.values.skip(1)) {
      expect(
        find.descendant(of: tracker, matching: find.text(stage.label)),
        findsOneWidget,
      );
    }
    expect(find.text('Mark as Delivered'), findsNothing);
    await tap('Mark as Picked Up');
    expect(
      tester.widget<DeliveryStatusTracker>(tracker).status,
      DeliveryStatus.pickedUp,
    );
    expect(find.text('Mark as Delivered'), findsNothing);
    await tap('Start Delivery');
    expect(
      tester.widget<DeliveryStatusTracker>(tracker).status,
      DeliveryStatus.onTheWay,
    );
    await tap('Mark as Delivered');
    expect(
      tester.widget<DeliveryStatusTracker>(tracker).status,
      DeliveryStatus.delivered,
    );
    expect(find.text('Delivery completed in this demo.'), findsOneWidget);
    expect(find.text('Accept Delivery'), findsNothing);
    await tap('Back to My Orders');
    await tester.pumpAndSettle();
    await tap('Completed');
    await tap('Handcrafted ceramic vase');
    expect(
      tester.widget<DeliveryStatusTracker>(tracker).status,
      DeliveryStatus.delivered,
    );
    expect(find.text('Mark as Delivered'), findsNothing);
  });
}
