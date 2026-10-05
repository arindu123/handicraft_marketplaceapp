import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artisan Marketplace',
      theme: AppTheme.light,
      initialRoute: RouteNames.welcome,
      routes: AppRoutes.routes,
    );
  }
}
