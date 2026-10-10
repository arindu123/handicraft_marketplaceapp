import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/domain_models.dart' as model;
import 'marketplace_repository.dart';

class CommunityRepository {
  CommunityRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : db = firestore ?? FirebaseFirestore.instance,
      auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  String get uid =>
      auth.currentUser?.uid ??
      (throw const MarketplaceFailure('Please sign in to continue.'));
  Future<String> conversation(String artisanId) async {
    final buyer = uid;
    final id = '${buyer}_$artisanId';
    final ref = db.collection('conversations').doc(id);
    await db.runTransaction((tx) async {
      final current = await tx.get(ref);
      if (!current.exists) {
        tx.set(ref, {
          'participantIds': [buyer, artisanId],
          'buyerId': buyer,
          'artisanId': artisanId,
          'lastMessage': '',
          'lastMessageAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
    return id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> inbox() => db
      .collection('conversations')
      .where('participantIds', arrayContains: uid)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String id) => db
      .collection('conversations')
      .doc(id)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots();
  Future<void> send(String id, String text) async {
    final clean = text.trim();
    if (clean.isEmpty || clean.length > 4000) {
      throw const MarketplaceFailure(
        'Enter a message of 1 to 4000 characters.',
      );
    }
    final ref = db.collection('conversations').doc(id);
    final batch = db.batch();
    batch.set(ref.collection('messages').doc(), {
      'senderId': uid,
      'text': clean,
      'createdAt': FieldValue.serverTimestamp(),
      'readAt': null,
    });
    batch.update(ref, {
      'lastMessage': clean,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> reviews(String artisanId) => db
      .collection('reviews')
      .where('artisanId', isEqualTo: artisanId)
      .snapshots();
  Future<void> review(
    String orderId,
    String productId,
    double rating,
    String comment,
  ) async {
    if (!rating.isFinite ||
        rating < 1 ||
        rating > 5 ||
        comment.trim().isEmpty ||
        comment.length > 2000) {
      throw const MarketplaceFailure(
        'Enter a rating from 1 to 5 and a review of up to 2000 characters.',
      );
    }
    final buyer = uid;
    final ref = db.collection('reviews').doc('${buyer}_${orderId}_$productId');
    await db.runTransaction((tx) async {
      final profile = await tx.get(db.collection('users').doc(buyer));
      final order = await tx.get(db.collection('orders').doc(orderId));
      final prior = await tx.get(ref);
      if (profile.data()?['role'] != 'buyer' || !order.exists) {
        throw const MarketplaceFailure(
          'Only the buyer of a delivered order may review it.',
        );
      }
      final value = model.Order.fromMap(order.data()!);
      if (prior.exists ||
          value.buyerId != buyer ||
          value.status != model.OrderStatus.delivered ||
          !value.items.any((i) => i.productId == productId)) {
        throw const MarketplaceFailure(
          'This order is not eligible or has already been reviewed.',
        );
      }
      tx.set(ref, {
        'buyerId': buyer,
        'artisanId': value.artisanId,
        'productId': productId,
        'orderId': orderId,
        'rating': rating,
        'comment': comment.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profile(String id) =>
      db.collection('artisanProfiles').doc(id).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfile(String id) =>
      db.collection('users').doc(id).snapshots();

  static String readName(Map<String, dynamic> data) {
    for (final key in ['displayName', 'fullName', 'name']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  Future<void> ensureArtisanProfile() async {
    final id = uid;
    final ref = db.collection('artisanProfiles').doc(id);
    await db.runTransaction((tx) async {
      final user = await tx.get(db.collection('users').doc(id));
      final existing = await tx.get(ref);
      if (!existing.exists && user.data()?['role'] == 'artisan') {
        tx.set(ref, {
          'userId': id,
          'studioName': user.data()?['displayName'] ?? '',
          'location': '',
          'bio': '',
          'kilnSpecifications': '',
          'verificationStatus': model.VerificationStatus.pending.name,
        });
      }
    });
  }

  Future<void> saveProfile({
    required String studioName,
    required String location,
    required String bio,
    String kilnSpecifications = '',
  }) async {
    final ref = db.collection('artisanProfiles').doc(uid);
    await db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      final fields = {
        'userId': uid,
        'studioName': studioName.trim(),
        'location': location.trim(),
        'bio': bio.trim(),
        'kilnSpecifications': kilnSpecifications.trim(),
      };
      if (existing.exists) {
        tx.update(ref, fields);
      } else {
        tx.set(ref, {
          ...fields,
          'verificationStatus': model.VerificationStatus.pending.name,
        });
      }
    });
  }

  Future<void> verify(String id, model.VerificationStatus status) => db
      .collection('artisanProfiles')
      .doc(id)
      .update({'verificationStatus': status.name});
}
