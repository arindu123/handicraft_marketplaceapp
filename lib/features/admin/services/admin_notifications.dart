import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../shared/data/marketplace_repository.dart';
import '../../../shared/data/notification_token_lifecycle.dart';
import '../../delivery/services/delivery_notifications.dart';

class AdminNotifications {
  AdminNotifications._();
  static final instance = AdminNotifications._();
  static bool get supported => DeliveryNotifications.supported;
  String? _uid, _token;
  StreamSubscription<User?>? _auth;
  StreamSubscription<String>? _refresh;

  Future<void> enable() async {
    if (!supported) return;
    await NotificationTokenLifecycle.pendingReset;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _uid = user.uid;
    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      throw const MarketplaceFailure(
        'Allow notifications in your device settings to receive admin push alerts.',
      );
    }
    _auth ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      if (_uid != null && user?.uid != _uid) {
        _uid = null;
        _token = null;
        unawaited(NotificationTokenLifecycle.reset());
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
        'Unable to register admin push alerts. Try again.',
      );
    }
    await _register(user.uid, token);
  }

  Future<void> _register(String uid, String token) async {
    if (_uid != uid || FirebaseAuth.instance.currentUser?.uid != uid) return;
    final db = FirebaseFirestore.instance;
    final old = _token;
    await db.collection('adminDevices').doc(token).set({
      'adminId': uid,
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _token = token;
    if (old != null && old != token) {
      await db.collection('adminDevices').doc(old).delete();
    }
  }
}
