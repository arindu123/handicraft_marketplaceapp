import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../routes/route_names.dart';
import '../../../shared/models/domain_models.dart' show UserRole;
import '../models/marketplace_role.dart';

class ProfileException implements Exception {
  const ProfileException(this.message);
  final String message;
}

class AuthSession {
  static Future<UserRole> signIn(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return loadRole();
  }

  static Future<UserRole?> restore() async {
    if (FirebaseAuth.instance.currentUser == null) return null;
    return loadRole();
  }

  static Future<UserRole> loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ProfileException('Please sign in again.');
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snapshot.data();
    if (data == null) {
      throw const ProfileException(
        'Your account profile is missing. Please contact support.',
      );
    }
    if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
      throw const ProfileException(
        'Your session changed. Please sign in again.',
      );
    }
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
        'too-many-requests' =>
          'Too many attempts. Please wait a moment and try again.',
        _ => 'Unable to complete this request. Please try again later.',
      };
    }
    return 'Unable to complete this request. Please try again later.';
  }
}
