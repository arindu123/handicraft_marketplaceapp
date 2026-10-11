import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationTokenLifecycle {
  static Future<void> pendingReset = Future.value();
  static Future<void> reset() {
    pendingReset = pendingReset
        .then((_) => FirebaseMessaging.instance.deleteToken())
        .catchError((Object _) {});
    return pendingReset;
  }
}
