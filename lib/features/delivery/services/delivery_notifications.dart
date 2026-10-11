import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/data/marketplace_repository.dart';
import '../../../shared/data/notification_token_lifecycle.dart';

/// Keeps token refresh registration alive when the delivery screen is closed.
class DeliveryNotifications {
  DeliveryNotifications._();
  static final instance = DeliveryNotifications._();
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  String? _uid;
  String? _token;
  StreamSubscription<String>? _refresh;
  StreamSubscription<User?>? _auth;
  Future<void> _tokenReset = Future.value();

  Future<void> enable() async {
    if (!supported) return;
    await _tokenReset;
    await NotificationTokenLifecycle.pendingReset;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _uid = uid;
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      throw const MarketplaceFailure(
        'Allow notifications in your device settings to receive delivery alerts.',
      );
    }
    _auth ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      if (_uid != null && user?.uid != _uid) {
        _uid = null;
        _token = null;
        _tokenReset = NotificationTokenLifecycle.reset();
        unawaited(_tokenReset);
      }
    });
    _refresh ??= messaging.onTokenRefresh.listen((token) {
      final owner = _uid;
      if (owner != null) {
        unawaited(_register(owner, token).catchError((Object _) {}));
      }
    });
    final token = await messaging.getToken();
    if (token == null) {
      throw const MarketplaceFailure(
        'Unable to register delivery alerts. Try again.',
      );
    }
    await _register(uid, token);
  }

  Future<void> _register(String uid, String token) async {
    if (_uid != uid || FirebaseAuth.instance.currentUser?.uid != uid) return;
    final db = FirebaseFirestore.instance;
    final old = _token;
    await db.collection('deliveryDevices').doc(token).set({
      'courierId': uid,
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _token = token;
    if (old != null && old != token) {
      await db.collection('deliveryDevices').doc(old).delete();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled) await enable();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'deliveryNotifications': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
