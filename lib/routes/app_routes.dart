import 'package:flutter/material.dart';

import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import 'route_names.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    RouteNames.welcome: (_) => const WelcomeScreen(),
    RouteNames.onboarding: (_) => const OnboardingScreen(),
    RouteNames.signIn: (_) => const SignInScreen(),
    RouteNames.signUp: (_) => const SignUpScreen(),
    RouteNames.marketplace: (_) => const Scaffold(
      body: Center(
        child: Text('Artisan Marketplace', style: TextStyle(fontSize: 24)),
      ),
    ),
  };
}
