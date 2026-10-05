import 'package:artisan_marketplace/shared/data/delivery_workflow_repository.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/features/delivery/screens/delivery_home_screen.dart';

void main() {
  test('Customer code is stable; other users cannot obtain it', () async {
    final db = FakeFirebaseFirestore();
    await db.doc('orders/o1').set({'buyerId': 'buyer', 'status': 'onTheWay'});
    DeliveryWorkflowRepository repository(String uid) =>
        DeliveryWorkflowRepository(
          MarketplaceRepository(
            firestore: db,
            auth: MockFirebaseAuth(
              mockUser: MockUser(uid: uid),
              signedIn: true,
            ),
          ),
        );
    final code = await repository('buyer').confirmationCode('o1');
    expect(code, matches(RegExp(r'^\d{6}$')));
    expect(await repository('buyer').confirmationCode('o1'), code);
    await expectLater(
      repository('courier').confirmationCode('o1'),
      throwsA(isA<MarketplaceFailure>()),
    );
  });

  test(
    'Issues persist for active assigned orders and reject invalid reports',
    () async {
      final db = FakeFirebaseFirestore();
      await db.doc('orders/o1').set({
        'courierId': 'rider',
        'status': 'onTheWay',
      });
      DeliveryWorkflowRepository repository(String uid) =>
          DeliveryWorkflowRepository(
            MarketplaceRepository(
              firestore: db,
              auth: MockFirebaseAuth(
                mockUser: MockUser(uid: uid),
                signedIn: true,
              ),
            ),
          );
      final rider = repository('rider');
      await rider.reportIssue(
        'o1',
        'Wrong address',
        'Building number is missing.',
      );
      final reports = await db.collection('orders/o1/deliveryIssues').get();
      expect(reports.docs.single.data()['reason'], 'Wrong address');
      expect(
        reports.docs.single.data()['notes'],
        'Building number is missing.',
      );
      for (final action in [
        () => repository('other').reportIssue('o1', 'Wrong address', ''),
        () => rider.reportIssue('o1', 'Other', ''),
        () => rider.reportIssue('o1', 'Unknown', ''),
      ]) {
        await expectLater(action(), throwsA(isA<MarketplaceFailure>()));
      }
      await db.doc('orders/o1').update({'status': 'delivered'});
      await expectLater(
        rider.reportIssue('o1', 'Damaged parcel', ''),
        throwsA(isA<MarketplaceFailure>()),
      );
      expect(
        (await db.collection('orders/o1/deliveryIssues').get()).docs,
        hasLength(1),
      );
    },
  );

  testWidgets('Alert opens a delivery and issue stays after reopening it', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DeliveryHomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('New deliveries'), findsOneWidget);
    await tester.tap(find.text('Handcrafted ceramic vase').last);
    await tester.pumpAndSettle();
    final report = find.text('Report delivery issue');
    await tester.ensureVisible(report);
    await tester.tap(report);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Details'),
      'Customer did not answer.',
    );
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(
      find.text('Customer unavailable: Customer did not answer.'),
      findsOneWidget,
    );
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Handcrafted ceramic vase').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Customer unavailable: Customer did not answer.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
