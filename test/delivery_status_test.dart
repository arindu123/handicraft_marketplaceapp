import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/features/delivery/models/delivery_order.dart';
import 'package:artisan_marketplace/features/delivery/screens/delivery_home_screen.dart';
import 'package:artisan_marketplace/features/delivery/widgets/delivery_status_widgets.dart';

void main() {
  test('Earnings use completion dates and exclude unconfirmed amounts', () {
    DeliveryOrder completed(
      DateTime date,
      double amount, {
      bool confirmed = true,
    }) => DeliveryOrder(
      id: 'test',
      title: 'Parcel',
      pickup: 'Studio',
      destination: 'Customer',
      service: 'Fragile parcel',
      createdAt: DateTime(2026, 9, 30),
      completedAt: date,
      earnings: amount,
      earningsConfirmed: confirmed,
      status: DeliveryStatus.delivered,
    );
    final orders = [
      completed(DateTime(2026, 10, 7), 20),
      completed(DateTime(2026, 10, 6), 30),
      completed(DateTime(2026, 10, 4), 40),
      completed(DateTime(2026, 10, 7), 99, confirmed: false),
      completed(DateTime(2026, 10, 8), 50),
    ];
    expect(
      DeliveryOrder.earningsBetween(
        orders,
        DateTime(2026, 10, 7),
        DateTime(2026, 10, 8),
      ),
      20,
    );
    expect(
      DeliveryOrder.earningsBetween(
        orders,
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 8),
      ),
      50,
    );
    expect(orders.first.createdOn(DateTime(2026, 10, 7)), isFalse);
    expect(orders.first.createdOn(DateTime(2026, 9, 30, 23)), isTrue);
  });

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
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Delivery code'),
      '000000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm delivery'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect code. Try 123456.'), findsOneWidget);
    expect(
      tester.widget<DeliveryStatusTracker>(tracker).status,
      DeliveryStatus.onTheWay,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Delivery code'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm delivery'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<DeliveryStatusTracker>(tracker).status,
      DeliveryStatus.delivered,
    );
    expect(find.text('Delivery completed in this demo.'), findsOneWidget);
    expect(find.text('Accept Delivery'), findsNothing);
    await tap('Back to My Orders');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Completed'),
      -200,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('delivery-orders')),
        matching: find.byType(Scrollable),
      ),
    );
    await tap('Completed');
    await tap('Handcrafted ceramic vase');
    expect(
      tester.widget<DeliveryStatusTracker>(tracker).status,
      DeliveryStatus.delivered,
    );
    expect(find.text('Mark as Delivered'), findsNothing);
  });
}
