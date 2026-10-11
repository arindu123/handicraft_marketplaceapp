import 'shared/data/marketplace_repository.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final initialization =
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .then<void>((_) {
            MarketplaceBackend.enabled = true;
          });
  // Welcome paints immediately while Firebase initializes in the background.
  runApp(MyApp(initialization: initialization));
}
