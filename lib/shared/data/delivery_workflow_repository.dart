import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

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
