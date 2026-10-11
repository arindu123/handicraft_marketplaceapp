import 'package:artisan_marketplace/features/admin/models/admin_demo_store.dart';
import 'package:artisan_marketplace/features/admin/services/admin_operations_repository.dart';
import 'package:artisan_marketplace/features/auth/services/auth_session.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MarketplaceRepository admin;
  MarketplaceRepository repo(String id, UserRole role) => MarketplaceRepository(
    firestore: db,
    auth: MockFirebaseAuth(mockUser: MockUser(uid: id), signedIn: true),
    loadRole: () async => role,
  );
  setUp(() async {
    db = FakeFirebaseFirestore();
    admin = repo('admin', UserRole.admin);
    await db.doc('users/courier').set({
      'role': 'courier',
      'displayName': 'New Courier',
      'email': 'courier@example.com',
      'courierApproval': 'pending',
    });
  });
  test(
    'Pending courier becomes approved with one audit and one email queued',
    () async {
      final operations = AdminOperationsRepository(admin);
      await operations.reviewCourier('courier', true);
      final profile = (await db.doc('users/courier').get()).data()!;
      expect(profile['courierApproval'], 'approved');
      expect(profile['courierReviewedBy'], 'admin');
      expect(() => AuthSession.ensureCourierApproved(profile), returnsNormally);
      final email = (await db.doc('courierApprovalEmails/courier').get())
          .data()!;
      expect(email['to'], 'courier@example.com');
      expect((email['message'] as Map)['subject'], contains('verified'));
      expect(email.containsKey('delivery'), false);
      await expectLater(
        operations.reviewCourier('courier', true),
        throwsA(isA<MarketplaceFailure>()),
      );
      expect((await db.collection('adminActivity').get()).docs, hasLength(1));
      expect(
        (await db.collection('courierApprovalEmails').get()).docs,
        hasLength(1),
      );
    },
  );
  test(
    'Rejection denies login and queues the rejection message to signup email',
    () async {
      await AdminOperationsRepository(admin).reviewCourier('courier', false);
      final profile = (await db.doc('users/courier').get()).data()!;
      expect(
        () => AuthSession.ensureCourierApproved(profile),
        throwsA(isA<CourierApprovalException>()),
      );
      final email = (await db.doc('courierApprovalEmails/courier').get())
          .data()!;
      expect(email['to'], 'courier@example.com');
      expect((email['message'] as Map)['subject'], contains('not approved'));
      expect((email['message'] as Map)['text'], contains('rejected'));
    },
  );
  test('Legacy, pending and paused couriers are denied', () {
    for (final profile in [
      <String, dynamic>{},
      {'courierApproval': 'pending'},
      {'courierApproval': 'approved', 'active': false},
    ]) {
      expect(
        () => AuthSession.ensureCourierApproved(profile),
        throwsA(isA<CourierApprovalException>()),
      );
    }
  });
  test('Courier cannot approve their own application', () async {
    await expectLater(
      AdminOperationsRepository(repo('courier', UserRole.courier))
          .reviewCourier('courier', true),
      throwsA(isA<MarketplaceFailure>()),
    );
    expect(
      (await db.doc('users/courier').get()).data()?['courierApproval'],
      'pending',
    );
  });
  test('Pending courier applications remain visible alongside artisan applications', () async {
    await db.doc('users/courier').update({
      'phone': '0771234567',
      'area': 'Colombo',
      'vehicleType': 'Van',
    });
    final store = AdminDemoStore(backend: admin);
    addTearDown(store.dispose);
    await Future<void>.delayed(Duration.zero);
    final application = store.approvals.singleWhere(
      (item) => item.type == 'Courier',
    );
    expect(application.description, contains('0771234567'));
    expect(application.description, contains('Colombo'));
    expect(application.description, contains('Van'));
    expect(
      store.approvals.any(
        (item) => item.type == 'Courier' && item.status == 'Pending',
      ),
      true,
    );
    await db.doc('artisanProfiles/artisan').set({
      'studioName': 'Clay Studio',
      'verificationStatus': 'pending',
    });
    await Future<void>.delayed(Duration.zero);
    expect(
      store.approvals.map((item) => item.type),
      containsAll(['Courier', 'Artisan']),
    );
    expect(
      store.notifications.any(
        (notice) =>
            notice.category == 'applications' && notice.targetId == 'courier',
      ),
      true,
    );
    await AdminOperationsRepository(admin).reviewCourier('courier', true);
    await Future<void>.delayed(Duration.zero);
    expect(store.couriers.single.verification, 'Approved');
  });
}
