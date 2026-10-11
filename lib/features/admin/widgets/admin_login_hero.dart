import 'package:flutter/material.dart';

class AdminLoginHero extends StatelessWidget {
  const AdminLoginHero({super.key, required this.isSignUp});
  final bool isSignUp;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/admin/curator_workspace.png',
            fit: BoxFit.cover,
            semanticLabel:
                'A thoughtfully arranged marketplace curator workspace',
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x18493B30), Color(0xEF29231F)],
                stops: [0, .9],
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F1E8),
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/images/branding/craftisan_bag_icon.png'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MARKETPLACE CURATOR · GUILD EDITION',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF2D3AA),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSignUp
                    ? 'Begin your Craftisan story'
                    : 'Welcome back to Craftisan',
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 32,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isSignUp
                    ? 'Create your curator profile. Administrative access requires approval.'
                    : 'Sign in to your approved marketplace administration account.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFFFFF4E9),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
