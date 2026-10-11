import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialization});

  final Future<void>? initialization;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artisan Marketplace',
      theme: AppTheme.light,
      initialRoute: RouteNames.welcome,
      routes: {
        ...AppRoutes.routes,
        RouteNames.welcome: (_) =>
            WelcomeScreen(initialization: initialization),
      },
    );
  }
}
