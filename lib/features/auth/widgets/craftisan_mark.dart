import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CraftisanMark extends StatelessWidget {
  const CraftisanMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Craftisan pottery emblem',
      image: true,
      child: CustomPaint(size: Size.square(size), painter: _VasePainter()),
    );
  }
}

class _VasePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    final paint = Paint()
      ..color = AppColors.terracotta
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final vase = Path()
      ..moveTo(25, 20)
      ..cubicTo(25, 29, 16, 34, 17, 46)
      ..cubicTo(18, 64, 46, 64, 47, 46)
      ..cubicTo(48, 34, 39, 29, 39, 20);
    canvas.drawPath(vase, paint);
    canvas.drawLine(const Offset(23, 20), const Offset(41, 20), paint);
    canvas.drawPath(
      Path()
        ..moveTo(19, 43)
        ..quadraticBezierTo(32, 52, 45, 43),
      paint,
    );
    canvas.drawLine(const Offset(32, 18), const Offset(32, 9), paint);
    paint.style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(32, 12)
        ..quadraticBezierTo(30, 4, 40, 4)
        ..quadraticBezierTo(40, 12, 32, 12),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
