import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'marketplace_repository.dart';

const deliveryIssueReasons = [
  'Customer unavailable',
  'Wrong address',
  'Damaged parcel',
  'Unable to accept delivery',
  'Other',
];

class DeliveryWorkflowRepository {
  DeliveryWorkflowRepository(this.marketplace);
  final MarketplaceRepository marketplace;

  DocumentReference<Map<String, dynamic>> plan(String orderId) => marketplace.db
      .collection('orders')
      .doc(orderId)
      .collection('deliveryPlan')
      .doc('current');

  Future<void> saveAttempt(
    String orderId,
    String outcome,
    String reason,
    String notes, {
    DateTime? retryAt,
  }) async {
    if (!['failed', 'rescheduled', 'returnRequested'].contains(outcome) ||
        !deliveryIssueReasons.contains(reason) ||
        notes.trim().length > 1000 ||
        (reason == 'Other' && notes.trim().isEmpty) ||
        (outcome == 'rescheduled' &&
            (retryAt == null || !retryAt.isAfter(DateTime.now())))) {
      throw const MarketplaceFailure(
        'Choose a reason and a future retry time.',
      );
    }
    final orderRef = marketplace.db.collection('orders').doc(orderId);
    final historyRef = orderRef.collection('deliveryAttempts').doc();
    await marketplace.db.runTransaction((tx) async {
      final order = await tx.get(orderRef);
      final current = await tx.get(plan(orderId));
      _requireAssignedActive(order.data());
      if (current.data()?['outcome'] == 'returnRequested') {
        throw const MarketplaceFailure(
          'A return has already been requested. Contact support.',
        );
      }
      final data = <String, dynamic>{
        'courierId': marketplace.uid,
        'outcome': outcome,
        'reason': reason,
        'notes': notes.trim(),
        'retryAt': outcome == 'rescheduled'
            ? Timestamp.fromDate(retryAt!)
            : null,
        'createdAt': FieldValue.serverTimestamp(),
      };
      tx.set(historyRef, data);
      tx.set(plan(orderId), data);
    });
  }

  Future<void> resumeDelivery(String orderId) async {
    await marketplace.db.runTransaction((tx) async {
      final order = await tx.get(
        marketplace.db.collection('orders').doc(orderId),
      );
      final current = await tx.get(plan(orderId));
      _requireAssignedActive(order.data());
      final data = current.data();
      final retry = data?['retryAt'] as Timestamp?;
      if (data == null ||
          !['failed', 'rescheduled'].contains(data['outcome']) ||
          (retry != null && retry.toDate().isAfter(DateTime.now()))) {
        throw const MarketplaceFailure('This delivery cannot be resumed yet.');
      }
      tx.update(plan(orderId), {
        'outcome': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  void _requireAssignedActive(Map<String, dynamic>? order) {
    if (order == null ||
        order['courierId'] != marketplace.uid ||
        ![
          'courierAssigned',
          'pickedUp',
          'onTheWay',
        ].contains(order['status'])) {
      throw const MarketplaceFailure(
        'Only your active deliveries can be changed.',
      );
    }
  }

  Future<void> uploadProof(
    String orderId,
    String stage,
    Uint8List bytes, {
    FirebaseStorage? storage,
  }) async {
    if (!['pickup', 'dropoff'].contains(stage) ||
        bytes.isEmpty ||
        bytes.length > 10 * 1024 * 1024 ||
        bytes.length < 3 ||
        bytes[0] != 0xff ||
        bytes[1] != 0xd8 ||
        bytes[2] != 0xff) {
      throw const MarketplaceFailure('Choose a JPEG photo smaller than 10 MB.');
    }
    final order = await marketplace.db.collection('orders').doc(orderId).get();
    _requireProofStage(order.data(), stage);
    final path = 'delivery_proofs/$orderId/${marketplace.uid}/$stage.jpg';
    await (storage ?? FirebaseStorage.instance)
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    await saveProof(orderId, stage);
  }

  void _requireProofStage(Map<String, dynamic>? order, String stage) {
    final statuses = stage == 'pickup'
        ? ['courierAssigned', 'pickedUp', 'onTheWay']
        : ['onTheWay', 'delivered'];
    if (!['pickup', 'dropoff'].contains(stage) ||
        order == null ||
        order['courierId'] != marketplace.uid ||
        !statuses.contains(order['status'])) {
      throw const MarketplaceFailure(
        'This photo cannot be added at the current delivery stage.',
      );
    }
  }

  Future<void> saveProof(String orderId, String stage) async {
    final orderRef = marketplace.db.collection('orders').doc(orderId);
    await marketplace.db.runTransaction((tx) async {
      final order = await tx.get(orderRef);
      _requireProofStage(order.data(), stage);
      tx.set(orderRef.collection('deliveryProofs').doc(stage), {
        'courierId': marketplace.uid,
        'stage': stage,
        'path': 'delivery_proofs/$orderId/${marketplace.uid}/$stage.jpg',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<String> confirmationCode(String orderId) async {
    final ref = marketplace.db.collection('deliveryConfirmations').doc(orderId);
    return marketplace.db.runTransaction((tx) async {
      final order = await tx.get(
        marketplace.db.collection('orders').doc(orderId),
      );
      if (!order.exists || order.data()!['buyerId'] != marketplace.uid) {
        throw const MarketplaceFailure('Only the customer can view this code.');
      }
      final existing = await tx.get(ref);
      if (existing.exists) return existing.data()!['code'] as String;
      if (['delivered', 'cancelled'].contains(order.data()!['status'])) {
        throw const MarketplaceFailure('This order is already closed.');
      }
      final code = (100000 + Random.secure().nextInt(900000)).toString();
      tx.set(ref, {'code': code, 'createdAt': FieldValue.serverTimestamp()});
      return code;
    });
  }

  Future<void> reportIssue(String orderId, String reason, String notes) async {
    if (!deliveryIssueReasons.contains(reason) ||
        notes.trim().length > 1000 ||
        (reason == 'Other' && notes.trim().isEmpty)) {
      throw const MarketplaceFailure('Choose a reason and add valid details.');
    }
    final orderRef = marketplace.db.collection('orders').doc(orderId);
    final reportRef = orderRef.collection('deliveryIssues').doc();
    await marketplace.db.runTransaction((tx) async {
      final order = await tx.get(orderRef);
      if (!order.exists ||
          order.data()!['courierId'] != marketplace.uid ||
          ![
            'courierAssigned',
            'pickedUp',
            'onTheWay',
          ].contains(order.data()!['status'])) {
        throw const MarketplaceFailure(
          'You can only report issues on your active deliveries.',
        );
      }
      tx.set(reportRef, {
        'courierId': marketplace.uid,
        'reason': reason,
        'notes': notes.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
