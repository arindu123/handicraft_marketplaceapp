import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';
import 'shared/widgets/brand_splash_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialization});

  final Future<void>? initialization;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _routes = _EntryRouteObserver();
  Timer? _resumeTimer;
  bool _backgrounded = false;
  bool _resumeSplash = false;
  int _resumeGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgrounded = true;
      _resumeGeneration++;
      _resumeTimer?.cancel();
    } else if (state == AppLifecycleState.resumed && _backgrounded) {
      _backgrounded = false;
      final signedIn =
          Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;
      // Always cover a warm return; only reset signed-out entry routes.
      const entryRoutes = {
        RouteNames.welcome,
        RouteNames.onboarding,
        RouteNames.roleSelection,
        RouteNames.buyerLanding,
        RouteNames.deliverySplash,
      };
      if (_routes.current == '/startup') return;
      final openRoles = !signedIn && entryRoutes.contains(_routes.current);
      setState(() => _resumeSplash = true);
      final generation = ++_resumeGeneration;
      _resumeTimer = Timer(
        const Duration(seconds: 3),
        () => _finishResume(generation, openRoles: openRoles),
      );
    }
  }

  @override
  Future<bool> didPopRoute() async => _resumeSplash;

  Future<void> _finishResume(int generation, {required bool openRoles}) async {
    try {
      if (!openRoles) return;
      await widget.initialization;
      if (!mounted || _backgrounded || generation != _resumeGeneration) return;
      if (Firebase.apps.isNotEmpty &&
          FirebaseAuth.instance.currentUser != null) {
        return;
      }
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        RouteNames.roleSelection,
        (_) => false,
      );
    } catch (_) {
      // Preserve welcome's initialization-error handling and retry behavior.
    } finally {
      if (mounted && !_backgrounded && generation == _resumeGeneration) {
        setState(() => _resumeSplash = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artisan Marketplace',
      theme: AppTheme.light,
      navigatorKey: _navigatorKey,
      navigatorObservers: [_routes],
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            excluding: _resumeSplash,
            child: IgnorePointer(ignoring: _resumeSplash, child: child!),
          ),
          if (_resumeSplash) const BrandSplashScreen(),
        ],
      ),
      initialRoute: '/startup',
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/startup'),
          builder: (_) => _StartupScreen(initialization: widget.initialization),
        ),
      ],
      routes: {
        ...AppRoutes.routes,
        '/startup': (_) =>
            _StartupScreen(initialization: widget.initialization),
        RouteNames.welcome: (_) =>
            WelcomeScreen(initialization: widget.initialization),
      },
    );
  }
}

/// Display branding once per app launch; welcome remains the return route.
class _StartupScreen extends StatefulWidget {
  const _StartupScreen({this.initialization});
  final Future<void>? initialization;

  @override
  State<_StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<_StartupScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Welcome handles errors when a user navigates. Listen immediately so an
    // initialization failure during the splash never goes unhandled.
    widget.initialization?.catchError((Object _) {});
    _timer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(RouteNames.welcome);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const BrandSplashScreen();
}

class _EntryRouteObserver extends NavigatorObserver {
  String? current;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    current = route.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    current = newRoute?.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    current = previousRoute?.settings.name;
  }
}
