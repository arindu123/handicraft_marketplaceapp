import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cloudinary_upload.dart';
import 'marketplace_repository.dart';

class ProfileRepository {
  ProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    CloudinaryUpload? uploader,
  }) : db = firestore ?? FirebaseFirestore.instance,
       auth = auth ?? FirebaseAuth.instance,
       uploader = uploader ?? CloudinaryUpload();

  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final CloudinaryUpload uploader;
  String get uid =>
      auth.currentUser?.uid ??
      (throw const MarketplaceFailure('Please sign in to edit your profile.'));

  Stream<Map<String, dynamic>> watch() =>
      db.collection('users').doc(uid).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (data == null) {
          throw const MarketplaceFailure(
            'Your account profile is missing. Please contact support.',
          );
        }
        return data;
      });

  Future<void> setDeliveryAvailability(bool online) async {
    final ref = db.collection('users').doc(uid);
    await db.runTransaction((tx) async {
      final profile = await tx.get(ref);
      if (profile.data()?['role'] != 'courier') {
        throw const MarketplaceFailure(
          'Only couriers can change availability.',
        );
      }
      tx.update(ref, {
        'deliveryOnline': online,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> save({
    required String displayName,
    required String area,
    Uint8List? photo,
  }) async {
    final owner = uid;
    final name = displayName.trim();
    final location = area.trim();
    if (name.isEmpty || name.length > 100 || location.length > 100) {
      throw const MarketplaceFailure(
        'Enter a name and use at most 100 characters per field.',
      );
    }
    final changes = <String, dynamic>{
      'displayName': name,
      'area': location,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photo != null) {
      if (photo.isEmpty || photo.length > 5 * 1024 * 1024) {
        throw const MarketplaceFailure('Choose a photo smaller than 5 MB.');
      }
      try {
        changes['photoUrl'] = await uploader.upload(photo);
      } catch (_) {
        throw const MarketplaceFailure(
          'Photo upload failed. Check your connection and try again.',
        );
      }
    }
    if (auth.currentUser?.uid != owner) {
      throw const MarketplaceFailure(
        'Your session changed. Please sign in again.',
      );
    }
    final userRef = db.collection('users').doc(owner);
    final currentProfile = await userRef.get();
    await userRef.update(changes);
    if (currentProfile.data()?['role'] == 'courier') {
      await db.collection('courierPublicProfiles').doc(owner).set({
        'displayName': name,
        'area': location,
        'photoUrl':
            changes['photoUrl'] ??
            currentProfile.data()?['photoUrl'] as String? ??
            '',
        'phone':
            auth.currentUser?.phoneNumber ??
            currentProfile.data()?['phone'] as String? ??
            '',
      });
    }
  }
}
