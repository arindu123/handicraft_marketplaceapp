import 'shared/data/marketplace_repository.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'features/auth/services/auth_session.dart';
import 'shared/models/domain_models.dart' show UserRole;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  MarketplaceBackend.enabled = true;
  UserRole? role;
  String? error;
  try {
    role = await AuthSession.restore();
  } catch (failure) {
    error = AuthSession.message(failure);
  }
  runApp(MyApp(initialRole: role, sessionError: error));
}
