import 'dart:convert';

import 'package:artisan_marketplace/features/delivery/models/delivery_order.dart';
import 'package:artisan_marketplace/features/delivery/widgets/delivery_extras.dart';
import 'package:artisan_marketplace/shared/data/delivery_workflow_repository.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  DeliveryWorkflowRepository repository(String uid) =>
      DeliveryWorkflowRepository(
        MarketplaceRepository(
          firestore: db,
          auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid)),
        ),
      );
  setUp(() async {
    db = FakeFirebaseFirestore();
    await db.doc('orders/o1').set({'courierId': 'rider', 'status': 'onTheWay'});
  });

  test(
    'failed attempts persist, hold a delivery and can be resumed by its rider',
    () async {
      final rider = repository('rider');
      await rider.saveAttempt(
        'o1',
        'failed',
        'Customer unavailable',
        'No answer',
      );
      expect((await rider.plan('o1').get()).data()!['outcome'], 'failed');
      await expectLater(
        repository('other').resumeDelivery('o1'),
        throwsA(isA<MarketplaceFailure>()),
      );
      await rider.resumeDelivery('o1');
      expect((await rider.plan('o1').get()).data()!['outcome'], 'active');
      final attempts = await db.collection('orders/o1/deliveryAttempts').get();
      expect(attempts.docs.single.data()['notes'], 'No answer');
    },
  );

  test('reschedules reject past dates and cannot resume early', () async {
    final rider = repository('rider');
    await expectLater(
      rider.saveAttempt(
        'o1',
        'rescheduled',
        'Wrong address',
        '',
        retryAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      throwsA(isA<MarketplaceFailure>()),
    );
    await rider.saveAttempt(
      'o1',
      'rescheduled',
      'Wrong address',
      '',
      retryAt: DateTime.now().add(const Duration(days: 1)),
    );
    await expectLater(
      rider.resumeDelivery('o1'),
      throwsA(isA<MarketplaceFailure>()),
    );
    await rider.plan('o1').update({
      'retryAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    });
    await rider.resumeDelivery('o1');
  });

  test(
    'returns cannot be resumed and completed orders reject attempts',
    () async {
      final rider = repository('rider');
      await rider.saveAttempt(
        'o1',
        'returnRequested',
        'Damaged parcel',
        'Broken',
      );
      await expectLater(
        rider.resumeDelivery('o1'),
        throwsA(isA<MarketplaceFailure>()),
      );
      await expectLater(
        rider.saveAttempt('o1', 'failed', 'Wrong address', ''),
        throwsA(isA<MarketplaceFailure>()),
      );
      await db.doc('orders/o1').update({'status': 'delivered'});
      await expectLater(
        rider.saveAttempt('o1', 'failed', 'Wrong address', ''),
        throwsA(isA<MarketplaceFailure>()),
      );
    },
  );

  test('proof metadata restricts stage and assignment', () async {
    final rider = repository('rider');
    await rider.saveProof('o1', 'dropoff');
    expect(
      (await db.doc('orders/o1/deliveryProofs/dropoff').get()).data()!['path'],
      'delivery_proofs/o1/rider/dropoff.jpg',
    );
    await expectLater(
      repository('other').saveProof('o1', 'pickup'),
      throwsA(isA<MarketplaceFailure>()),
    );
    await db.doc('orders/o1').update({'status': 'courierAssigned'});
    await expectLater(
      rider.saveProof('o1', 'dropoff'),
      throwsA(isA<MarketplaceFailure>()),
    );
    await expectLater(
      rider.saveProof('o1', 'invalid'),
      throwsA(isA<MarketplaceFailure>()),
    );
  });

  test('held deliveries cannot advance until resumed', () async {
    await db.doc('orders/o1').set({
      'id': 'o1',
      'buyerId': 'buyer',
      'artisanId': 'artisan',
      'courierId': 'rider',
      'status': 'pickedUp',
      'items': [],
      'deliveryAddress': 'Home',
      'paymentMethod': 'Cash on delivery',
      'subtotal': 50,
      'deliveryFee': 14,
      'total': 64,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': null,
    });
    final rider = repository('rider');
    await rider.saveAttempt('o1', 'failed', 'Customer unavailable', '');
    await expectLater(
      rider.marketplace.advanceOrder('o1'),
      throwsA(isA<MarketplaceFailure>()),
    );
    expect((await db.doc('orders/o1').get()).data()!['status'], 'pickedUp');
    await rider.resumeDelivery('o1');
    await rider.marketplace.advanceOrder('o1');
    expect((await db.doc('orders/o1').get()).data()!['status'], 'onTheWay');
  });

  testWidgets(
    'demo photo picker saves proof, displays it on reopen and supports cancellation',
    (tester) async {
      final data = DeliveryExtrasData();
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1kAAAAASUVORK5CYII=',
      );
      final order = DeliveryOrder(
        id: 'demo',
        title: 'Vase',
        pickup: 'Studio',
        destination: 'Home',
        service: 'Fragile',
        status: DeliveryStatus.accepted,
      );
      var cancelled = false;
      Widget screen() => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryExtras(
              order: order,
              demoData: data,
              onHoldChanged: (_) {},
              pickPhoto: (_) async => cancelled ? null : bytes,
            ),
          ),
        ),
      );
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('Add delivery photo'), findsNothing);
      await tester.tap(find.text('Add pickup photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      expect(data.photos['pickup'], bytes);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      cancelled = true;
      await tester.tap(find.text('Add pickup photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(data.photos['pickup'], bytes);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('demo failure persists on reopen and resume removes the hold', (
    tester,
  ) async {
    final data = DeliveryExtrasData();
    final order = DeliveryOrder(
      id: 'demo',
      title: 'Vase',
      pickup: 'Studio',
      destination: 'Home',
      service: 'Fragile',
      status: DeliveryStatus.onTheWay,
    );
    bool held = false;
    Widget screen() => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DeliveryExtras(
            order: order,
            demoData: data,
            onHoldChanged: (value) => held = value,
          ),
        ),
      ),
    );
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Failed delivery / reschedule'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Nobody home');
    await tester.tap(find.text('Save delivery attempt'));
    await tester.pumpAndSettle();
    expect(held, isTrue);
    expect(data.plan!['outcome'], 'failed');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('Resume delivery'), findsOneWidget);
    await tester.tap(find.text('Resume delivery'));
    await tester.pumpAndSettle();
    expect(held, isFalse);
    expect(data.attempts, hasLength(1));
  });
}
