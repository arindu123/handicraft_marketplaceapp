import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../routes/route_names.dart';
import '../../../shared/models/domain_models.dart' show UserRole;
import '../models/marketplace_role.dart';

class ProfileException implements Exception {
  const ProfileException(this.message);
  final String message;
}

class CourierApprovalException extends ProfileException {
  const CourierApprovalException(super.message);
}

class AuthSession {
  static Future<void>? _googleInitialization;

  static Future<UserRole?> signInWithGoogle({
    required UserRole newAccountRole,
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    Future<UserCredential> Function()? authenticate,
  }) async {
    final session = auth ?? FirebaseAuth.instance;
    final store = db ?? FirebaseFirestore.instance;
    String? authenticatedUid;
    try {
      final credential =
          await (authenticate?.call() ?? _googleCredential(session));
      final user = credential.user;
      authenticatedUid = user?.uid;
      if (user == null ||
          user.isAnonymous ||
          session.currentUser?.uid != user.uid) {
        throw const ProfileException('Please sign in again.');
      }
      final reference = store.collection('users').doc(user.uid);
      await store.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        if (session.currentUser?.uid != user.uid) {
          throw const ProfileException(
            'Your session changed. Please sign in again.',
          );
        }
        // Existing roles are authoritative; Google must never replace them.
        if (snapshot.exists) return;
        if (newAccountRole == UserRole.admin) {
          throw const ProfileException(
            'Administrator accounts must be created by an administrator.',
          );
        }
        final email = user.email;
        if (email == null || email.isEmpty) {
          throw const ProfileException(
            'Google did not provide an email address.',
          );
        }
        final name = user.displayName?.trim();
        transaction.set(reference, {
          'uid': user.uid,
          'email': email,
          'displayName': name == null || name.isEmpty
              ? email.split('@').first
              : name,
          'role': newAccountRole.name,
          if (newAccountRole == UserRole.courier) 'courierApproval': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return await loadRole(auth: session, db: store);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw const ProfileException(
          'Google sign-in is not configured yet. Please use email sign-in.',
        );
      }
      throw const ProfileException(
        'Google sign-in could not finish. Please try again.',
      );
    } catch (_) {
      // A failed profile setup must not become a restored signed-in session.
      if (authenticatedUid != null &&
          session.currentUser?.uid == authenticatedUid) {
        await session.signOut();
      }
      rethrow;
    }
  }

  static Future<UserCredential> _googleCredential(FirebaseAuth auth) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const ProfileException(
        'Google sign-in is currently available on Android.',
      );
    }
    final google = GoogleSignIn.instance;
    await (_googleInitialization ??= google.initialize().catchError((
      Object error,
    ) {
      _googleInitialization = null;
      throw error;
    }));
    final account = await google.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw const ProfileException(
        'Google did not return a sign-in token. Please try again.',
      );
    }
    return auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  }

  static Future<UserRole> signIn(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      return await loadRole();
    } on CourierApprovalException {
      await FirebaseAuth.instance.signOut();
      rethrow;
    }
  }

  static Future<UserRole?> restore() async {
    if (FirebaseAuth.instance.currentUser == null) return null;
    return loadRole();
  }

  static Future<UserRole> loadRole({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  }) async {
    final session = auth ?? FirebaseAuth.instance;
    final user = session.currentUser;
    if (user == null) {
      throw const ProfileException('Please sign in again.');
    }
    final snapshot = await (db ?? FirebaseFirestore.instance)
        .collection('users')
        .doc(user.uid)
        // Role changes made by administrators must be checked on the server.
        .get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    if (data == null) {
      throw const ProfileException(
        'Your account profile is missing. Please contact support.',
      );
    }
    if (session.currentUser?.uid != user.uid) {
      throw const ProfileException(
        'Your session changed. Please sign in again.',
      );
    }
    if (data['role'] == 'courier') ensureCourierApproved(data);
    return switch (data['role']) {
      'admin' => UserRole.admin,
      'buyer' => UserRole.buyer,
      'artisan' => UserRole.artisan,
      'courier' => UserRole.courier,
      _ => throw const ProfileException(
        'This account cannot access the app here. Please contact support.',
      ),
    };
  }

  static void ensureCourierApproved(Map<String, dynamic> profile) {
    if (profile['courierApproval'] != 'approved') {
      throw CourierApprovalException(
        profile['courierApproval'] == 'rejected'
            ? 'Your courier application was not approved. Please contact admin.'
            : 'Your courier account is awaiting admin approval. You can log in after approval.',
      );
    }
    if (profile['active'] == false) {
      throw const CourierApprovalException(
        'Your courier account is paused. Please contact admin.',
      );
    }
  }

  static String route(UserRole role) => role == UserRole.admin
      ? RouteNames.adminDashboard
      : role == UserRole.courier
      ? RouteNames.deliveryHome
      : RouteNames.marketplace;

  static MarketplaceRole selection(UserRole role) => switch (role) {
    UserRole.buyer => MarketplaceRole.buyer,
    UserRole.artisan => MarketplaceRole.artisan,
    UserRole.courier => MarketplaceRole.courier,
    UserRole.admin => MarketplaceRole.admin,
  };

  static Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.welcome,
          (_) => false,
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message(error))));
      }
    }
  }

  static String message(Object error) {
    if (error is ProfileException) return error.message;
    if (error is FirebaseException) {
      return switch (error.code) {
        'invalid-credential' || 'user-not-found' || 'wrong-password' =>
          'The email or password is incorrect. Please try again.',
        'network-request-failed' ||
        'unavailable' => 'Check your internet connection and try again.',
        'permission-denied' =>
          'Your account profile could not be accessed. Please contact support.',
        'invalid-email' => 'Enter a valid email address.',
        'email-already-in-use' =>
          'An account already exists with this email. Please sign in.',
        'weak-password' => 'Please choose a stronger password.',
        'operation-not-allowed' =>
          'This sign-in method is not enabled. Please try another method.',
        'account-exists-with-different-credential' =>
          'Use your existing sign-in method for this email first.',
        'too-many-requests' =>
          'Too many attempts. Please wait a moment and try again.',
        _ => 'Unable to complete this request. Please try again later.',
      };
    }
    return 'Unable to complete this request. Please try again later.';
  }
}
