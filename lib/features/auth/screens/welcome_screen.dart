import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/custom_button.dart';
import '../models/marketplace_role.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _openOnboarding() =>
      Navigator.of(context).pushNamed(RouteNames.onboarding);

  void _openSignIn() =>
      Navigator.of(context)
          .pushNamed(RouteNames.roleSelection, arguments: AuthEntry.signIn);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFCF8),
              AppColors.background,
              Color(0xFFF3E9DF),
            ],
            stops: [0, 0.68, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 700;
                  final logoSize = (constraints.maxHeight * 0.31).clamp(
                    180.0,
                    270.0,
                  );
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      26,
                      compact ? 12 : 24,
                      26,
                      compact ? 12 : 22,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (compact ? 24 : 46),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _openSignIn,
                              icon: const Icon(Icons.login_rounded, size: 17),
                              label: const Text('Sign in'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.ink,
                              ),
                            ),
                          ),
                          FadeTransition(
                            opacity: reduceMotion
                                ? const AlwaysStoppedAnimation(1)
                                : CurvedAnimation(
                                    parent: _entrance,
                                    curve: const Interval(
                                      0,
                                      0.72,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                            child: SlideTransition(
                              position: reduceMotion
                                  ? const AlwaysStoppedAnimation(Offset.zero)
                                  : Tween<Offset>(
                                      begin: const Offset(0, 0.08),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _entrance,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: logoSize + 22,
                                    width: logoSize + 22,
                                    child: Center(
                                      child: Image.asset(
                                        'assets/images/branding/craftisan_marketplace_logo.png',
                                        width: logoSize,
                                        height: logoSize,
                                        fit: BoxFit.contain,
                                        semanticLabel:
                                            'Craftisan Marketplace logo',
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 4 : 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: .72,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: const Color(0xFFE9D8CB),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 14,
                                          color: AppColors.terracotta,
                                        ),
                                        SizedBox(width: 7),
                                        Text(
                                          'MADE SLOWLY. TREASURED ALWAYS.',
                                          style: TextStyle(
                                            color: AppColors.ink,
                                            fontSize: 9,
                                            letterSpacing: 1.15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: compact ? 15 : 22),
                                  Text(
                                    'Find something\nbeautifully handmade.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                          color: AppColors.ink,
                                          fontSize: compact ? 34 : 39,
                                          height: 1.08,
                                          letterSpacing: -0.9,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Discover one-of-a-kind pottery and meet the\nindependent makers behind every piece.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 14,
                                      height: 1.55,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          FadeTransition(
                            opacity: reduceMotion
                                ? const AlwaysStoppedAnimation(1)
                                : CurvedAnimation(
                                    parent: _entrance,
                                    curve: const Interval(
                                      0.25,
                                      1,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                            child: Column(
                              children: [
                                CustomButton(
                                  label: 'Explore the marketplace',
                                  onPressed: _openOnboarding,
                                ),
                                const SizedBox(height: 13),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.local_florist_outlined,
                                      size: 15,
                                      color: AppColors.sage,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'Thoughtfully made by independent artisans',
                                      style: TextStyle(
                                        color: AppColors.muted.withValues(
                                          alpha: .9,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: compact ? 4 : 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
