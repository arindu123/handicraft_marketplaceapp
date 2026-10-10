import 'package:artisan_marketplace/features/delivery/models/delivery_history_filter.dart';
import 'package:artisan_marketplace/features/delivery/models/delivery_order.dart';
import 'package:artisan_marketplace/features/delivery/screens/delivery_home_screen.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DeliveryOrder order({
    DeliveryStatus status = DeliveryStatus.accepted,
    DateTime? completed,
  }) => DeliveryOrder(
    id: 'order',
    title: 'Parcel',
    pickup: 'Studio',
    destination: 'Colombo',
    service: 'Fragile',
    status: status,
    createdAt: DateTime(2026, 10, 1),
    completedAt: completed,
  );
  test('Status scopes combine with exact stages', () {
    final delivered = order(
      status: DeliveryStatus.delivered,
      completed: DateTime(2026, 10, 10),
    );
    expect(DeliveryHistoryFilter.matches(delivered, scope: 'Active'), isFalse);
    expect(
      DeliveryHistoryFilter.matches(delivered, scope: 'Completed'),
      isTrue,
    );
    expect(
      DeliveryHistoryFilter.matches(order(), status: DeliveryStatus.accepted),
      isTrue,
    );
    expect(
      DeliveryHistoryFilter.matches(order(), status: DeliveryStatus.onTheWay),
      isFalse,
    );
  });
  test('Date range is inclusive and completed orders use completion date', () {
    final from = DateTime(2026, 10, 10), through = DateTime(2026, 10, 11);
    for (final date in [from, DateTime(2026, 10, 11, 23, 59, 59)]) {
      expect(
        DeliveryHistoryFilter.matches(
          order(status: DeliveryStatus.delivered, completed: date),
          from: from,
          through: through,
        ),
        isTrue,
      );
    }
    expect(
      DeliveryHistoryFilter.matches(
        order(
          status: DeliveryStatus.delivered,
          completed: DateTime(2026, 10, 12),
        ),
        from: from,
        through: through,
      ),
      isFalse,
    );
    expect(
      DeliveryHistoryFilter.matches(order(), from: from, through: through),
      isFalse,
    );
    expect(
      DeliveryHistoryFilter.matches(
        order(status: DeliveryStatus.delivered),
        from: from,
        through: through,
      ),
      isFalse,
    );
    expect(
      DeliveryHistoryFilter.matches(order(status: DeliveryStatus.delivered)),
      isTrue,
    );
  });
  testWidgets('Courier can select a stage and clear history filters', (
    tester,
  ) async {
    MarketplaceBackend.enabled = false;
    await tester.pumpWidget(const MaterialApp(home: DeliveryHomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delivery-history-status')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accepted').last);
    await tester.pumpAndSettle();
    expect(find.text('No deliveries in this view.'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear history filters'));
    await tester.pumpAndSettle();
    expect(find.text('No deliveries in this view.'), findsNothing);
    expect(find.text('All dates'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
