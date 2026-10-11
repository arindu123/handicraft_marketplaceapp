import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../auth/services/auth_session.dart';
import '../../../shared/models/domain_models.dart' show UserRole;

class CourierGoogleSignIn {
  CourierGoogleSignIn({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    this.authenticate,
    this.requestApplicationDetails,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final Future<UserCredential?> Function()? authenticate;
  final Future<Map<String, dynamic>?> Function()? requestApplicationDetails;
  static Future<void>? _initialization;

  Future<UserCredential?> _google() async {
    if (kIsWeb) return _auth.signInWithPopup(GoogleAuthProvider());
    final google = GoogleSignIn.instance;
    await (_initialization ??= google.initialize());
    final account = await google.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw const ProfileException(
        'Google could not verify this account. Please try again.',
      );
    }
    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  }

  Future<UserRole?> signIn() async {
    try {
      final credential = await (authenticate?.call() ?? _google());
      if (credential == null) return null;
      final user = credential.user;
      if (user == null || _auth.currentUser?.uid != user.uid) {
        throw const ProfileException(
          'Your session changed. Please sign in again.',
        );
      }
      final ref = _db.collection('users').doc(user.uid);
      Map<String, dynamic>? details;
      if (requestApplicationDetails != null &&
          !(await ref.get(const GetOptions(source: Source.server))).exists) {
        details = await requestApplicationDetails!();
        if (details == null) {
          await _auth.signOut();
          return null;
        }
      }
      final role = await _db.runTransaction<UserRole>((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (data != null) {
          return switch (data['role']) {
            'courier' => UserRole.courier,
            'buyer' => UserRole.buyer,
            'artisan' => UserRole.artisan,
            'admin' => UserRole.admin,
            _ => throw const ProfileException(
              'This account profile is invalid. Please contact support.',
            ),
          };
        }
        final email = user.email;
        if (email == null || email.isEmpty) {
          throw const ProfileException(
            'Google did not provide an email address.',
          );
        }
        transaction.set(ref, {
          'uid': user.uid,
          'email': email,
          'displayName': _name(user),
          'role': 'courier',
          'courierApproval': 'pending',
          if (details != null) ...{
            'phone': details['phone'],
            'area': details['area'],
            'vehicleType': details['vehicleType'],
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return UserRole.courier;
      });
      if (role == UserRole.courier) {
        final publicRef = _db.collection('courierPublicProfiles').doc(user.uid);
        await _db.runTransaction((transaction) async {
          final profile = await transaction.get(ref);
          final publicProfile = await transaction.get(publicRef);
          if (profile.data()?['role'] != 'courier') {
            throw const ProfileException(
              'Your account role changed. Please sign in again.',
            );
          }
          if (!publicProfile.exists) {
            transaction.set(publicRef, {
              'displayName': profile.data()?['displayName'] ?? _name(user),
              'area': profile.data()?['area'] ?? '',
              'photoUrl': '',
              'phone': profile.data()?['phone'] ?? user.phoneNumber ?? '',
            });
          }
        });
      }
      if (_auth.currentUser?.uid != user.uid) {
        throw const ProfileException(
          'Your session changed. Please sign in again.',
        );
      }
      if (role == UserRole.courier) {
        final profile = await ref.get(const GetOptions(source: Source.server));
        AuthSession.ensureCourierApproved(profile.data() ?? {});
      }
      return role;
    } on CourierApprovalException {
      await _auth.signOut();
      rethrow;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const ProfileException(
          'Google sign-in setup is incomplete. Enable Google in Firebase and configure this Android app’s signing fingerprint.',
        );
      }
      throw const ProfileException(
        'Google sign-in could not complete. Check your connection and try again.',
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'operation-not-allowed') {
        throw const ProfileException(
          'Google sign-in is not enabled in Firebase Authentication yet.',
        );
      }
      if (error.code == 'account-exists-with-different-credential') {
        throw const ProfileException(
          'This email uses another sign-in method. Sign in using that method first.',
        );
      }
      rethrow;
    }
  }

  static String _name(User user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name.length > 100 ? name.substring(0, 100) : name;
    }
    return 'Courier';
  }
}
