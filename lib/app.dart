import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';
import 'features/auth/services/auth_session.dart';
import 'shared/models/domain_models.dart' show UserRole;

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRole, this.sessionError});
  final UserRole? initialRole;
  final String? sessionError;

  @override
  Widget build(BuildContext context) {
    final messenger = GlobalKey<ScaffoldMessengerState>();
    if (sessionError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messenger.currentState?.showSnackBar(
          SnackBar(content: Text(sessionError!)),
        );
      });
    }
    return MaterialApp(
      scaffoldMessengerKey: messenger,
      debugShowCheckedModeBanner: false,
      title: 'Artisan Marketplace',
      theme: AppTheme.light,
      initialRoute: RouteNames.welcome,
      routes: AppRoutes.routes,
      onGenerateInitialRoutes: (_) {
        final role = initialRole;
        final route = role == null
            ? RouteNames.welcome
            : AuthSession.route(role);
        return [
          MaterialPageRoute<void>(
            settings: RouteSettings(
              name: route,
              arguments: role == null ? null : AuthSession.selection(role),
            ),
            builder: AppRoutes.routes[route]!,
          ),
        ];
      },
    );
  }
}
