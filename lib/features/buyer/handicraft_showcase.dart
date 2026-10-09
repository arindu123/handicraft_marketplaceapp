import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Two products, then a short parcel delivery animation, repeated for six crafts.
class HandicraftShowcase extends StatefulWidget {
  const HandicraftShowcase({super.key, required this.imageBuilder});
  final Widget Function(BuildContext, int) imageBuilder;
  @override
  State<HandicraftShowcase> createState() => _HandicraftShowcaseState();
}

class _HandicraftShowcaseState extends State<HandicraftShowcase>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const names = [
    'vase',
    'basket',
    'elephant',
    'teapot',
    'lamp',
    'macrame',
  ];
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  Timer? _timer;
  int _step = 0;
  bool _foreground = true;
  bool _reduced = false;
  bool get _promo => _step % 3 == 2;
  bool get _visible =>
      _foreground &&
      TickerMode.valuesOf(context).enabled &&
      ModalRoute.of(context)?.isCurrent != false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (_reduced || !_visible) {
      _animation.stop();
      return;
    }
    if (_promo) _animation.forward(from: 0);
    _timer = Timer(Duration(milliseconds: _promo ? 3200 : 1800), () {
      if (!mounted) return;
      if (_visible) setState(() => _step = (_step + 1) % 9);
      _schedule();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animation.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = (_step ~/ 3) * 2 + _step % 3;
    return AnimatedSwitcher(
      duration: Duration(milliseconds: _reduced ? 0 : 360),
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (_, child) => FractionalTranslation(
          translation: Offset(
            (animation.status == AnimationStatus.reverse ? -1 : 1) *
                (1 - Curves.easeInOutCubic.transform(animation.value)),
            0,
          ),
          child: child,
        ),
      ),
      child: _promo && !_reduced
          ? CustomPaint(
              key: ValueKey('parcel-$_step'),
              painter: _ParcelPainter(_animation),
            )
          : SizedBox.expand(
              key: ValueKey(names[index.clamp(0, 5)]),
              child: widget.imageBuilder(context, index.clamp(0, 5)),
            ),
    );
  }
}

class _ParcelPainter extends CustomPainter {
  _ParcelPainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = animation.value * 3.2;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 60);
    final paint = Paint();
    void rect(Rect r, Color c, [double radius = 0]) {
      paint.color = c;
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(radius)),
        paint,
      );
    }

    void poly(List<Offset> points, Color color) {
      paint.color = color;
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(path, paint);
    }

    void label(String value, Offset center, double fontSize, Color color) {
      final text = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: 'sans-serif',
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
      text.dispose();
    }

    void box(double open) {
      rect(const Rect.fromLTWH(32, 17, 30, 28), const Color(0xFFF2BE78), 1);
      poly([
        const Offset(62, 17),
        const Offset(75, 12),
        const Offset(75, 40),
        const Offset(62, 45),
      ], const Color(0xFFB97438));
      poly([
        const Offset(32, 17),
        const Offset(62, 17),
        Offset(75 + open * 6, 12 - open * 8),
        Offset(45 - open * 12, 12 - open * 8),
      ], const Color(0xFFD49A58));
      rect(Rect.fromLTWH(65, 15, 5, 12 * (1 - open)), const Color(0xFFEAC68E));
      label('Craft', const Offset(47, 33), 7, const Color(0xFF704322));
    }

    void rocket(double scale, double x, bool reverse, {bool parcel = true}) {
      canvas.save();
      canvas.translate(x, math.sin(seconds * 18) * .8);
      canvas.translate(50, 30);
      canvas.scale(reverse ? -scale : scale, scale);
      canvas.translate(-50, -30);
      // Fast travelling trails make flight visible even at navigation size.
      for (var i = 0; i < 3; i++) {
        final offset = (seconds * 130 + i * 21) % 60;
        rect(
          Rect.fromLTWH(5 - offset, 22 + i * 12, 18, 1.2),
          const Color(0x88FFFFFF),
          1,
        );
      }
      poly([
        const Offset(28, 37),
        Offset(8 + math.sin(seconds * 65) * 3, 44),
        const Offset(28, 48),
      ], const Color(0xFFE5A625));
      poly([
        const Offset(27, 40),
        const Offset(16, 44),
        const Offset(27, 46),
      ], const Color(0xFFFFEB83));
      poly([
        const Offset(32, 32),
        const Offset(22, 25),
        const Offset(39, 25),
        const Offset(45, 34),
      ], const Color(0xFFBD2630));
      rect(const Rect.fromLTWH(26, 32, 43, 19), const Color(0xFFF6FAF9), 10);
      poly([
        const Offset(65, 32),
        const Offset(77, 42),
        const Offset(65, 51),
      ], const Color(0xFFC52832));
      poly([
        const Offset(37, 46),
        const Offset(25, 56),
        const Offset(44, 54),
        const Offset(49, 46),
      ], const Color(0xFFBD2630));
      paint.color = const Color(0xFF2C6776);
      canvas.drawCircle(const Offset(57, 41), 4.5, paint);
      paint.color = const Color(0xFFC5E6E8);
      canvas.drawCircle(const Offset(57, 41), 2.8, paint);
      if (parcel) {
        canvas.translate(8, -4);
        canvas.scale(.78);
        box(0);
      }
      canvas.restore();
    }

    if (seconds < .95) {
      final exit = ((seconds - .65) / .22).clamp(0.0, 1.0);
      rocket(.86, exit * exit * 115, false);
    } else if (seconds < 1.5) {
      // Larger return pass: the aircraft crosses right-to-left and drops its parcel.
      final p = ((seconds - .95) / .55).clamp(0.0, 1.0);
      rocket(1.25, 105 - p * 210, true, parcel: false);
      canvas.save();
      canvas.translate(
        (1 - Curves.easeOutCubic.transform((p * 2).clamp(0.0, 1.0))) * 100,
        0,
      );
      box(0);
      canvas.restore();
    } else if (seconds < 2.08) {
      paint.color = const Color(0x44916436);
      canvas.drawOval(const Rect.fromLTWH(28, 44, 52, 5), paint);
      final open = ((seconds - 1.87) / .17).clamp(0.0, 1.0);
      box(open);
    } else if (seconds < 2.3) {
      label('Craft', const Offset(50, 30), 24, const Color(0xFF24231E));
      for (var i = 0; i < 4; i++) {
        rect(
          Rect.fromLTWH(14 + i * 23, i.isEven ? 13 : 43, 5, 2),
          const Color(0xFFE2A64E),
          1,
        );
      }
    } else {
      // Hold BUY, then let the index finger arrive, press and release.
      final press = ((seconds - 2.86) / .12).clamp(0.0, 1.0);
      final release = ((seconds - 3.04) / .12).clamp(0.0, 1.0);
      final down = press * (1 - release);
      canvas.save();
      canvas.translate(50, 29);
      canvas.scale(1 - down * .07);
      rect(const Rect.fromLTWH(-34, -15, 68, 30), const Color(0xFF20211D), 15);
      label('BUY', Offset.zero, 21, Colors.white);
      canvas.restore();
      if (seconds > 2.58) {
        final enter = Curves.easeOutCubic.transform(
          ((seconds - 2.58) / .24).clamp(0.0, 1.0),
        );
        canvas.save();
        canvas.translate(0, (1 - enter) * 40 + down * 2);
        final hand = Path()
          ..moveTo(61, 60)
          ..lineTo(54, 47)
          ..quadraticBezierTo(51, 42, 55, 40)
          ..quadraticBezierTo(58, 39, 61, 45)
          ..lineTo(53, 27)
          ..quadraticBezierTo(51, 22, 55, 21)
          ..quadraticBezierTo(59, 20, 61, 25)
          ..lineTo(66, 37)
          ..quadraticBezierTo(70, 31, 74, 36)
          ..quadraticBezierTo(79, 31, 82, 37)
          ..quadraticBezierTo(87, 34, 90, 41)
          ..lineTo(97, 60)
          ..close();
        paint.color = const Color(0xFFF2A48A);
        canvas.drawPath(hand, paint);
        paint
          ..color = const Color(0xFFC67864)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8;
        canvas.drawPath(hand, paint);
        canvas.drawLine(const Offset(67, 38), const Offset(71, 47), paint);
        canvas.drawLine(const Offset(75, 38), const Offset(79, 47), paint);
        paint.style = PaintingStyle.fill;
        canvas.restore();
        if (down > .05) {
          paint
            ..color = Colors.white.withValues(alpha: .8 * (1 - release))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3;
          canvas.drawCircle(const Offset(55, 23), 4 + press * 5, paint);
          paint.style = PaintingStyle.fill;
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ParcelPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
