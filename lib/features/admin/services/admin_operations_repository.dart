import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/data/marketplace_repository.dart';
import '../../../shared/models/domain_models.dart' as domain;
import '../../../shared/models/delivery_fee_policy.dart';
import '../models/admin_operations.dart';

class AdminOperationsRepository {
  AdminOperationsRepository(this.marketplace);
  final MarketplaceRepository marketplace;

  Future<void> assignCourier(
    String orderId,
    String courierId, {
    required String expectedStatus,
    required String? expectedCourierId,
  }) async {
    await marketplace.requireRole(domain.UserRole.admin);
    final actor = marketplace.uid;
    final orderRef = marketplace.db.collection('orders').doc(orderId);
    final courierRef = marketplace.db.collection('users').doc(courierId);
    final activity = marketplace.db.collection('adminActivity').doc();
    await marketplace.db.runTransaction((transaction) async {
      final order = await transaction.get(orderRef);
      final courier = await transaction.get(courierRef);
      final plan = await transaction.get(
        orderRef.collection('deliveryPlan').doc('current'),
      );
      final before = order.data();
      if (before == null ||
          !['confirmed', 'courierAssigned'].contains(before['status'])) {
        throw const MarketplaceFailure(
          'Assign couriers after packing and before pickup.',
        );
      }
      if (before['status'] != expectedStatus ||
          before['courierId'] != expectedCourierId) {
        throw const MarketplaceFailure(
          'This assignment changed. Review the order and try again.',
        );
      }
      if (plan.exists && plan.data()?['outcome'] != 'active') {
        throw const MarketplaceFailure(
          'Resolve the delivery hold before reassigning this order.',
        );
      }
      if (!courier.exists ||
          courier.data()?['role'] != 'courier' ||
          courier.data()?['active'] == false ||
          courier.data()?['courierApproval'] != 'approved') {
        throw const MarketplaceFailure('Choose an active courier account.');
      }
      if (before['courierId'] == courierId) return;
      final after = {
        ...before,
        'courierId': courierId,
        'status': 'courierAssigned',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      transaction.set(orderRef, after);
      transaction.set(activity, {
        'actorId': actor,
        'action': 'Courier assigned',
        'collection': 'orders',
        'targetId': orderId,
        'before': before,
        'after': after,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> reviewCourier(String uid, bool approved) async {
    await marketplace.requireRole(domain.UserRole.admin);
    final ref = marketplace.db.collection('users').doc(uid);
    final emailRef = marketplace.db
        .collection('courierApprovalEmails')
        .doc(uid);
    final activity = marketplace.db.collection('adminActivity').doc();
    await marketplace.db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final queued = await transaction.get(emailRef);
      final before = snapshot.data();
      if (before == null || before['role'] != 'courier') {
        throw const MarketplaceFailure(
          'This courier application no longer exists.',
        );
      }
      if ((before['courierApproval'] ?? 'pending') != 'pending') {
        throw const MarketplaceFailure(
          'This application has already been reviewed.',
        );
      }
      final after = {
        ...before,
        'courierApproval': approved ? 'approved' : 'rejected',
        'courierReviewedBy': marketplace.uid,
        'courierReviewedAt': FieldValue.serverTimestamp(),
      };
      transaction.set(ref, after);
      transaction.set(activity, {
        'actorId': marketplace.uid,
        'action': approved ? 'Courier approved' : 'Courier rejected',
        'collection': 'users',
        'targetId': uid,
        'before': before,
        'after': after,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!queued.exists) {
        transaction.set(emailRef, {
          'to': before['email'],
          'message': {
            'subject': approved
                ? 'Your Craftisan courier account is verified'
                : 'Your Craftisan courier application was not approved',
            'text': approved
                ? 'Your courier account has been verified and approved by admin. You can now log in to Craftisan Delivery.'
                : 'Your courier application was reviewed and rejected by admin. Delivery access is not enabled. Please contact the Craftisan admin team for more information.',
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> change(
    String collection,
    String id,
    String action,
    Map<String, dynamic> changes, {
    bool create = false,
  }) async {
    await marketplace.requireRole(domain.UserRole.admin);
    final actor = marketplace.uid;
    final ref = marketplace.db.collection(collection).doc(id);
    final activity = marketplace.db.collection('adminActivity').doc();
    await marketplace.db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists && !create) {
        throw const MarketplaceFailure('This record no longer exists.');
      }
      final before = snapshot.data() ?? <String, dynamic>{};
      final after = {...before, ...changes};
      if (changes.entries.every((entry) => before[entry.key] == entry.value)) {
        return;
      }
      transaction.set(ref, after);
      transaction.set(activity, {
        'actorId': actor,
        'action': action,
        'collection': collection,
        'targetId': id,
        'before': before,
        'after': after,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> saveDeliveryPolicy(DeliveryFeePolicy policy) async {
    if (!policy.isValid) {
      throw const MarketplaceFailure(
        'Enter non-negative amounts with up to two decimal places.',
      );
    }
    await change(
      'marketplaceSettings',
      'deliveryLkr',
      'Delivery fees updated',
      {
        'currency': 'LKR',
        'fee': policy.fee,
        'freeDeliveryThreshold': policy.freeDeliveryThreshold,
        'updatedBy': marketplace.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      create: true,
    );
  }

  Future<void> createReport({
    required String kind,
    required String targetId,
    required String reporterId,
    required String reason,
    required String notes,
  }) async {
    if (!['Product', 'Delivery', 'Order'].contains(kind) ||
        targetId.trim().isEmpty ||
        targetId.contains('/') ||
        reporterId.trim().isEmpty ||
        reason.trim().isEmpty ||
        reason.length > 200 ||
        notes.length > 2000) {
      throw const MarketplaceFailure(
        'Enter a valid reference, reporter and complaint.',
      );
    }
    final id = marketplace.db.collection('marketplaceReports').doc().id;
    await change('marketplaceReports', id, 'Complaint recorded', {
      'kind': kind,
      'targetId': targetId.trim(),
      'reporterId': reporterId.trim(),
      'reason': reason.trim(),
      'notes': notes.trim(),
      'submittedBy': marketplace.uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, create: true);
  }

  Future<void> resolveReport(AdminReport report, String notes) async {
    if (notes.trim().isEmpty || notes.length > 2000) {
      throw const MarketplaceFailure(
        'Enter a resolution note (up to 2,000 characters).',
      );
    }
    await change(
      'reportResolutions',
      report.resolutionId,
      'Complaint resolved',
      {
        'sourcePath': report.sourcePath,
        'status': 'Resolved',
        'notes': notes.trim(),
        'resolvedBy': marketplace.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      create: true,
    );
  }
}
