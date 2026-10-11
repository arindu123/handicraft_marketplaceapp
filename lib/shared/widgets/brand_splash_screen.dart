import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// The full-screen brand treatment shown while the app starts.
class BrandSplashScreen extends StatelessWidget {
  const BrandSplashScreen({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.heroCream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: AppColors.heroCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _BrandPatternPainter()),
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = (constraints.maxWidth * .78)
                      .clamp(220.0, 340.0)
                      .clamp(0.0, constraints.biggest.shortestSide);
                  return Semantics(
                    label: 'Craftisan Marketplace is starting',
                    image: true,
                    child: Image.asset(
                      'assets/images/branding/craftisan_marketplace_logo.png',
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BrandPatternPainter extends CustomPainter {
  const _BrandPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 800);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 800),
      Paint()..color = AppColors.heroCream,
    );
    final top = Path()
      ..moveTo(0, 0)
      ..lineTo(230, 0)
      ..cubicTo(135, 85, 100, 165, 0, 190)
      ..close();
    canvas.drawPath(top, Paint()..color = AppColors.terracotta);
    final sweep = Path()
      ..moveTo(400, 0)
      ..lineTo(400, 270)
      ..cubicTo(330, 200, 320, 115, 205, 145)
      ..cubicTo(285, 55, 330, 25, 400, 0)
      ..close();
    canvas.drawPath(sweep, Paint()..color = const Color(0xFF145C60));
    final bottom = Path()
      ..moveTo(0, 590)
      ..cubicTo(115, 620, 140, 765, 260, 700)
      ..cubicTo(330, 660, 360, 605, 400, 565)
      ..lineTo(400, 800)
      ..lineTo(0, 800)
      ..close();
    canvas.drawPath(bottom, Paint()..color = AppColors.terracotta);
    final ribbon = Path()
      ..moveTo(0, 690)
      ..cubicTo(110, 680, 145, 830, 310, 740)
      ..cubicTo(355, 715, 385, 690, 400, 675)
      ..lineTo(400, 730)
      ..cubicTo(265, 860, 155, 815, 65, 755)
      ..lineTo(0, 745)
      ..close();
    canvas.drawPath(ribbon, Paint()..color = const Color(0xFF145C60));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandPatternPainter oldDelegate) => false;
}
