import 'package:artisan_marketplace/features/buyer/buyer_order_problems.dart';
import 'package:artisan_marketplace/features/admin/models/admin_operations.dart';
import 'package:artisan_marketplace/features/admin/services/admin_operations_repository.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late BuyerProblemsRepository buyer;
  MarketplaceRepository repo(String uid, UserRole role) =>
      MarketplaceRepository(
        firestore: db,
        auth: MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true),
        loadRole: () async => role,
      );
  setUp(() async {
    db = FakeFirebaseFirestore();
    buyer = BuyerProblemsRepository(repo('buyer', UserRole.buyer));
    await db.doc('orders/own').set({'buyerId': 'buyer'});
    await db.doc('orders/other').set({'buyerId': 'other'});
  });
  test('Own-order complaint reaches admin format, resolves and retries without duplicate', () async {
    await buyer.submit('own', 'report', 'Damaged item', 'Cracked mug');
    await buyer.submit('own', 'report', 'Damaged item', 'Cracked mug');
    final docs = (await db.collection('marketplaceReports').get()).docs;
    expect(docs, hasLength(1));
    final report = AdminReport.fromMap(
      docs.single.reference.path,
      docs.single.data(),
    );
    expect(report.reporterId, 'buyer');
    expect(report.status, 'Open');
    await AdminOperationsRepository(repo('admin', UserRole.admin))
        .resolveReport(report, 'Replacement arranged.');
    final resolution = await buyer.resolution(report).firstWhere((snapshot) => snapshot.exists);
    expect(resolution.data()?['status'], 'Resolved');
    expect(resolution.data()?['notes'], 'Replacement arranged.');
    expect(
      (await db.doc(report.sourcePath).get()).data()?['notes'],
      'Cracked mug',
    );
  });
  test('Other orders, missing orders, unsupported reasons and blank notes are rejected', () async {
    for (final args in [
      ['other', 'Wrong item', 'Wrong mug'],
      ['missing', 'Wrong item', 'Wrong mug'],
      ['own', 'Unknown', 'Wrong mug'],
      ['own', 'Delivery delay', '   '],
      ['own', 'Wrong item', 'x' * 2001],
    ]) {
      await expectLater(
        buyer.submit(args[0], 'invalid', args[1], args[2]),
        throwsA(isA<MarketplaceFailure>()),
      );
    }
    expect((await db.collection('marketplaceReports').get()).docs, isEmpty);
  });
  testWidgets('Buyer submits notes and sees live admin resolution', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BuyerOrderProblems(repository: buyer, orderId: 'own'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(find.text('Describe the problem.'), findsOneWidget);
    await tester.tap(find.text('Wrong item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delivery delay').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Still waiting for my order.',
    );
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(find.text('Status: Open'), findsOneWidget);
    final doc = (await db.collection('marketplaceReports').get()).docs.single;
    final report = AdminReport.fromMap(doc.reference.path, doc.data());
    await AdminOperationsRepository(repo('admin', UserRole.admin))
        .resolveReport(report, 'Courier will arrive tomorrow.');
    await tester.pumpAndSettle();
    expect(find.text('Status: Resolved'), findsOneWidget);
    expect(
      find.text('Resolution: Courier will arrive tomorrow.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
