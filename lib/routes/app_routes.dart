import 'package:flutter/material.dart';

import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/delivery/screens/delivery_splash_screen.dart';
import '../features/delivery/screens/delivery_login_screen.dart';
import '../features/delivery/screens/delivery_home_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import 'route_names.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    RouteNames.welcome: (_) => const WelcomeScreen(),
    RouteNames.onboarding: (_) => const OnboardingScreen(),
    RouteNames.signIn: (_) => const SignInScreen(),
    RouteNames.signUp: (_) => const SignUpScreen(),
    RouteNames.roleSelection: (_) => const RoleSelectionScreen(),
    RouteNames.deliverySplash: (_) => const DeliverySplashScreen(),
    RouteNames.deliveryLogin: (_) => const DeliveryLoginScreen(),
    RouteNames.deliveryHome: (_) => const DeliveryHomeScreen(),
    RouteNames.adminDashboard: (_) => const AdminDashboardScreen(),
    RouteNames.marketplace: (_) => const Scaffold(
      body: Center(
        child: Text('Artisan Marketplace', style: TextStyle(fontSize: 24)),
      ),
    ),
  };
}
