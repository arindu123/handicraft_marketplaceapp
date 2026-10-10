import 'shared/data/marketplace_repository.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'shared/widgets/brand_splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BrandSplashScreen(),
    ),
  );
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Future<void>.delayed(const Duration(milliseconds: 1000)),
  ]);
  MarketplaceBackend.enabled = true;
  runApp(const MyApp());
}
