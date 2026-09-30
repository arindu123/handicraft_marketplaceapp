import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/custom_button.dart';
import '../widgets/craftisan_mark.dart';
import '../models/marketplace_role.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 18),
                      child: Column(
                        children: [
                          const Spacer(flex: 3),
                          const _WelcomeEmblem(),
                          Text(
                            'Craftisan',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(fontSize: 46),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Artisan Potter Marketplace',
                            style: TextStyle(
                              fontFamily: 'CormorantGaramond',
                              fontStyle: FontStyle.italic,
                              color: AppColors.terracotta,
                              fontSize: 17,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 1,
                            margin: const EdgeInsets.symmetric(vertical: 24),
                            color: Color(0xFFE2C7BA),
                          ),
                          const Text(
                            'Where handmade mastery meets\nthoughtful collectors.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted,
                              height: 1.5,
                            ),
                          ),
                          const Spacer(flex: 2),
                          const SizedBox(height: 40),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _WelcomeDot(active: true),
                              _WelcomeDot(),
                              _WelcomeDot(),
                            ],
                          ),
                          const SizedBox(height: 28),
                          CustomButton(
                            label: 'Get Started',
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RouteNames.onboarding,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Already have a collection?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  RouteNames.roleSelection,
                                  arguments: AuthEntry.signIn,
                                ),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeDot extends StatelessWidget {
  const _WelcomeDot({this.active = false});
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    width: active ? 20 : 6,
    height: 6,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: active ? AppColors.terracotta : const Color(0xFFE2C7BA),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class _WelcomeEmblem extends StatelessWidget {
  const _WelcomeEmblem();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5EEE8),
              border: Border.all(color: const Color(0xFFF0E3D9)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFF5EEE8),
                  blurRadius: 38,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),
          Container(
            width: 186,
            height: 186,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEAD9CD)),
            ),
          ),
          Container(
            width: 114,
            height: 114,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: const CraftisanMark(),
          ),
        ],
      ),
    );
  }
}
