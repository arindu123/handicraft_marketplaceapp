import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/features/delivery/models/delivery_order.dart';
import 'package:artisan_marketplace/features/delivery/widgets/delivery_contact_details.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart' as domain;

void main() {
  test(
    'Maps encodes addresses and dialer rejects invalid or special numbers',
    () {
      expect(
        directionsUri('42 Flower Road, Colombo & Galle')
            .queryParameters['destination'],
        '42 Flower Road, Colombo & Galle',
      );
      expect(directionsUri('Colombo').queryParameters['api'], '1');
      expect(phoneUri('+94 (77) 123-4567').toString(), 'tel:+94771234567');
      expect(phoneUri('*123#'), isNull);
      expect(phoneUri(''), isNull);
    },
  );

  test('Legacy recipient details are separated from the Maps address', () {
    final order = domain.Order(
      id: 'o1',
      buyerId: 'buyer',
      artisanId: 'secret-id',
      items: [],
      status: domain.OrderStatus.courierAssigned,
      deliveryAddress:
          'Pasindu\n42 Flower Road\nColombo, 00300\nSri Lanka\n0771234567',
      paymentMethod: 'Cash on delivery',
      subtotal: 10,
      deliveryFee: 14,
      total: 24,
      createdAt: DateTime.utc(2026),
    );
    final delivery = DeliveryOrder.fromOrder(order);
    expect(delivery.recipientName, 'Pasindu');
    expect(delivery.recipientPhone, '0771234567');
    expect(delivery.destination, '42 Flower Road\nColombo, 00300\nSri Lanka');
    expect(delivery.pickup, isEmpty);
    expect(delivery.deliveryFee, 14);
    expect(delivery.currency, 'USD');
    expect(delivery.earningsConfirmed, isFalse);
    // Customer delivery fees must not silently become courier earnings.
    final paidOrder = domain.Order.fromMap({
      ...order.toMap(),
      'status': 'delivered',
      'updatedAt': '2026-10-07T10:00:00.000Z',
      'courierEarnings': 9.5,
    });
    final paidDelivery = DeliveryOrder.fromOrder(paidOrder);
    expect(paidDelivery.earningsConfirmed, isTrue);
    expect(paidDelivery.earnings, 9.5);
    expect(paidDelivery.completedAt, DateTime.utc(2026, 10, 7, 10));
    expect(paidOrder.toMap()['courierEarnings'], 9.5);
    final lkrDelivery = DeliveryOrder.fromOrder(domain.Order.fromMap({
      ...paidOrder.toMap(), 'currency': 'LKR', 'courierEarnings': 950,
    }));
    expect(lkrDelivery.currency, 'LKR');
    expect(lkrDelivery.earnings, 950);
  });

  testWidgets('Directions and call buttons launch the correct destinations', (
    tester,
  ) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeliveryContactDetails(
            order: DeliveryOrder(
              id: 'o1',
              title: 'Vase',
              pickup: 'Studio, Colombo',
              destination: '42 Flower Road',
              service: 'Fragile parcel',
              recipientName: 'Pasindu',
              recipientPhone: '0771234567',
              deliveryFee: 14,
            ),
            openUrl: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      ),
    );
    for (final label in [
      'Pickup directions',
      'Drop-off directions',
      'Call customer',
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(opened[0].queryParameters['destination'], 'Studio, Colombo');
    expect(opened[1].queryParameters['destination'], '42 Flower Road');
    expect(opened[2].toString(), 'tel:0771234567');
  });

  testWidgets(
    'Missing data disables unavailable actions and launch errors are visible',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryContactDetails(
              order: DeliveryOrder(
                id: 'old',
                title: 'Vase',
                pickup: '',
                destination: 'Colombo',
                service: 'Fragile',
              ),
              openUrl: (_) async => false,
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Call customer'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Pickup directions'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Drop-off directions'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not open Maps. Use the address shown above.'),
        findsOneWidget,
      );
    },
  );
}
