import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_session.dart';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/custom_text_field.dart';

class _ResetFrame extends StatelessWidget {
  const _ResetFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _resetIvory,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: child,
                    ),
                  ),
                ),
                const ExcludeSemantics(
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: CustomPaint(painter: _ResetFooterPainter()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ResetHeader extends StatelessWidget {
  const _ResetHeader();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Back',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              RouteNames.signIn,
              (route) => route.isFirst,
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3E9E1),
              foregroundColor: _resetClay,
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'CRAFTISAN',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 29,
                    letterSpacing: 1.5,
                    color: _resetTeal,
                  ),
                ),
                Text(
                  'MARKETPLACE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 3.5,
                    color: _resetClay,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
      const SizedBox(height: 32),
      const ExcludeSemantics(
        child: SizedBox(
          height: 155,
          width: double.infinity,
          child: CustomPaint(painter: _ResetEnvelopePainter(sent: false)),
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'RESET YOUR PASSWORD',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 2.2,
          color: _resetClay,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
    ],
  );
}

class _ResetCard extends StatelessWidget {
  const _ResetCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 24),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFEEDFD5)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06634B3A),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class PasswordResetRequestScreen extends StatefulWidget {
  const PasswordResetRequestScreen({super.key});
  @override
  State<PasswordResetRequestScreen> createState() =>
      _PasswordResetRequestScreenState();
}

class _PasswordResetRequestScreenState
    extends State<PasswordResetRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_sending || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    final email = _email.text.trim();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        RouteNames.passwordResetSuccess,
        arguments: email,
      );
    } catch (error) {
      if (mounted) setState(() => _error = AuthSession.message(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ResetFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ResetHeader(),
        Text(
          'Recover Your Passcode',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 38,
            height: 1.1,
            color: _resetTeal,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Enter your Craftisan email address. We will send a link to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        _ResetCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Registered Email Address',
                  controller: _email,
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Enter your email address.';
                    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)
                        ? null
                        : 'Enter a valid email address.';
                  },
                  onFieldSubmitted: (_) => _next(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Open the reset link in your email to choose a new password.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                if (_error != null)
                  Text(
                    _error!,
                    semanticsLabel: _error,
                    style: const TextStyle(color: AppColors.terracotta),
                  ),
                FilledButton(
                  onPressed: _sending ? null : _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: _resetClay,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: _sending
                      ? Semantics(
                          label: 'Sending reset email',
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _resetClay,
                            ),
                          ),
                        )
                      : const Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          children: [
                            Text(
                              'Send Reset Email',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Icon(Icons.arrow_forward_rounded, size: 21),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: _resetClay,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.signIn,
            (route) => route.isFirst,
          ),
          child: const Text('Remembered your passcode? Sign In'),
        ),
      ],
    ),
  );
}

class PasswordResetCodeScreen extends StatelessWidget {
  const PasswordResetCodeScreen({super.key});
  @override
  Widget build(BuildContext context) => const PasswordResetRequestScreen();
}

class PasswordResetNewPasswordScreen extends StatelessWidget {
  const PasswordResetNewPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => const PasswordResetRequestScreen();
}

const _resetTeal = Color(0xFF0B4545);
const _resetClay = Color(0xFFA44126);
const _resetIvory = Color(0xFFF8F5F1);

class PasswordResetSuccessScreen extends StatefulWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  State<PasswordResetSuccessScreen> createState() =>
      _PasswordResetSuccessScreenState();
}

class _PasswordResetSuccessScreenState
    extends State<PasswordResetSuccessScreen> {
  bool _sending = false;
  int _cooldown = 30;
  Timer? _timer;
  String? _feedback;
  bool _failed = false;

  String? get _email => ModalRoute.of(context)?.settings.arguments as String?;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    _cooldown = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _signIn() => Navigator.pushNamedAndRemoveUntil(
    context,
    RouteNames.signIn,
    (route) => route.isFirst,
  );

  Future<void> _resend() async {
    final email = _email;
    if (_sending || _cooldown > 0 || email == null || email.isEmpty) return;
    setState(() {
      _sending = true;
      _feedback = null;
      _failed = false;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        _feedback = 'Request accepted. If an account exists, a new reset link will arrive shortly.';
        _startCooldown();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _feedback = AuthSession.message(error);
        _startCooldown();
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _resetIvory,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton.filledTonal(
                                tooltip: 'Back',
                                onPressed: _signIn,
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3E9E1),
                                  foregroundColor: _resetClay,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                ),
                              ),
                              const Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'CRAFTISAN',
                                      style: TextStyle(
                                        fontFamily: 'CormorantGaramond',
                                        fontSize: 29,
                                        letterSpacing: 1.5,
                                        color: _resetTeal,
                                      ),
                                    ),
                                    Text(
                                      'MARKETPLACE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 3.5,
                                        color: _resetClay,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                          SizedBox(height: compact ? 18 : 30),
                          Semantics(
                            label: 'An envelope with a success checkmark',
                            image: true,
                            child: SizedBox(
                              height: compact ? 170 : 210,
                              child: const CustomPaint(
                                painter: _ResetEnvelopePainter(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'CHECK YOUR EMAIL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _resetClay,
                              letterSpacing: 2.5,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text.rich(
                            const TextSpan(
                              children: [
                                TextSpan(text: "We've sent a\n"),
                                TextSpan(
                                  text: 'password reset',
                                  style: TextStyle(color: _resetClay),
                                ),
                                TextSpan(text: ' link'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'CormorantGaramond',
                              color: _resetTeal,
                              fontSize: compact ? 36 : 42,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'If an account exists for this email, you will receive a reset link. Follow it to change your password, then return to sign in.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF625E59),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .8),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFEEDFD5),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x06634B3A),
                                  blurRadius: 20,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _ResetIcon(
                                      Icons.mail_outline_rounded,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'PASSWORD RESET REQUEST',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.muted,
                                              letterSpacing: 1.2,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Email address',
                                            style: TextStyle(
                                              color: Color(0xFF625E59),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _email ?? 'Return to sign in to request a reset link.',
                                            style: const TextStyle(
                                              color: _resetTeal,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Divider(
                                    height: 1,
                                    color: Color(0xFFEEDFD5),
                                  ),
                                ),
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ResetIcon(
                                      Icons.info_outline_rounded,
                                      sage: true,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your password will only change after you complete the reset process using the email link.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF625E59),
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _signIn,
                            style: FilledButton.styleFrom(
                              backgroundColor: _resetClay,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 17,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: const Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              children: [
                                Text(
                                  'Back to Sign In',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(Icons.arrow_forward_rounded, size: 22),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          const Row(
                            children: [
                              Expanded(
                                child: Divider(color: Color(0xFFDED6CC)),
                              ),
                              SizedBox(width: 12),
                              Flexible(
                                flex: 3,
                                child: Text(
                                  "Didn't receive the email?",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                    letterSpacing: .6,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Divider(color: Color(0xFFDED6CC)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: _ResetHelp(
                                  icon: Icons.mail_outline_rounded,
                                  label: 'Check your\nspam folder',
                                ),
                              ),
                              const Expanded(
                                child: _ResetHelp(
                                  icon: Icons.schedule_rounded,
                                  label: 'Wait a few\nminutes',
                                  sage: true,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const _ResetIcon(Icons.refresh_rounded),
                                    TextButton(
                                      onPressed:
                                          _sending ||
                                              _cooldown > 0 ||
                                              _email == null
                                          ? null
                                          : _resend,
                                      style: TextButton.styleFrom(
                                        foregroundColor: _resetClay,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 10,
                                        ),
                                      ),
                                      child: _sending
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: _resetClay,
                                              ),
                                            )
                                          : Text(
                                              _cooldown > 0
                                                  ? 'Try Again in ${_cooldown}s'
                                                  : 'Try Again',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_feedback != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  _feedback!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _failed
                                        ? _resetClay
                                        : AppColors.sage,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ExcludeSemantics(
                  child: SizedBox(
                    width: double.infinity,
                    height: compact ? 110 : 140,
                    child: const CustomPaint(painter: _ResetFooterPainter()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _ResetIcon extends StatelessWidget {
  const _ResetIcon(this.icon, {this.sage = false});
  final IconData icon;
  final bool sage;
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: sage ? const Color(0xFFE9ECE5) : const Color(0xFFF5EBE3),
    ),
    child: Icon(icon, size: 23, color: sage ? _resetTeal : _resetClay),
  );
}

class _ResetHelp extends StatelessWidget {
  const _ResetHelp({
    required this.icon,
    required this.label,
    this.sage = false,
  });
  final IconData icon;
  final String label;
  final bool sage;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ResetIcon(icon, sage: sage),
      const SizedBox(height: 10),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF625E59),
          height: 1.5,
        ),
      ),
    ],
  );
}

class _ResetFooterPainter extends CustomPainter {
  const _ResetFooterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..isAntiAlias = true;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      Path()
        ..moveTo(0, h * .36)
        ..cubicTo(w * .12, h * .3, w * .16, h * .68, w * .25, h * .71)
        ..cubicTo(w * .34, h * .72, w * .35, h * .9, w * .37, h)
        ..lineTo(0, h)
        ..close(),
      paint..color = const Color(0xFFDCDCCB),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * .64, h)
        ..cubicTo(w * .69, h * .56, w * .82, h * .8, w * .86, h * .38)
        ..cubicTo(w * .9, h * .06, w * .96, h * .08, w, 0)
        ..lineTo(w, h)
        ..close(),
      paint..color = const Color(0xFFCB7957),
    );
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFD59062);
    canvas.drawPath(
      Path()
        ..moveTo(-5, h * .24)
        ..cubicTo(w * .09, h * .3, w * .03, h * .78, w * .2, h * .64)
        ..cubicTo(w * .35, h * .48, w * .35, h * .75, w * .4, h * 1.04),
      paint,
    );
    paint.color = const Color(0xFFEBC1A2);
    canvas.drawPath(
      Path()
        ..moveTo(w * .73, h)
        ..cubicTo(w * .8, h * .7, w * .89, h * .88, w * .92, h * .42)
        ..quadraticBezierTo(w * .94, h * .2, w * 1.02, h * .16),
      paint,
    );
    // Fine botanical outlines on both edges, matching the reference footer.
    for (final right in [false, true]) {
      canvas.save();
      if (right) {
        canvas.translate(w, 0);
        canvas.scale(-1, 1);
      }
      paint.color = right ? const Color(0xFFECC7AA) : const Color(0xFF6E8065);
      final stem = Path()
        ..moveTo(-4, h * 1.02)
        ..quadraticBezierTo(32, h * .65, 24, h * .12);
      canvas.drawPath(stem, paint);
      for (var i = 0; i < 5; i++) {
        final y = h * (.26 + i * .14);
        final x = 22.0 - i * 3;
        final tipX = i.isEven ? x + 24 : x - 22;
        canvas.drawPath(
          Path()
            ..moveTo(x, y + 16)
            ..quadraticBezierTo(tipX - 5, y + 14, tipX, y - 10)
            ..quadraticBezierTo(x - 8, y - 8, x, y + 16),
          paint,
        );
        canvas.drawLine(Offset(x, y + 16), Offset(tipX, y - 10), paint);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ResetFooterPainter oldDelegate) => false;
}

class _ResetEnvelopePainter extends CustomPainter {
  const _ResetEnvelopePainter({this.sent = true});
  final bool sent;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate((size.width - size.height * 1.6) / 2, 0);
    canvas.scale(size.height / 200);
    final paint = Paint();
    canvas.drawOval(
      const Rect.fromLTWH(45, 20, 235, 170),
      paint..color = const Color(0xFFF2E5D9),
    );
    // Botanical stems and leaves flank the envelope.
    for (final right in [false, true]) {
      canvas.save();
      if (right) {
        canvas.translate(320, 0);
        canvas.scale(-1, 1);
      }
      paint
        ..color = right ? const Color(0xFFC87B56) : const Color(0xFF839575)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(
        Path()
          ..moveTo(92, 177)
          ..quadraticBezierTo(56, 140, 50, 84),
        paint,
      );
      paint.style = PaintingStyle.fill;
      for (var i = 0; i < 4; i++) {
        final y = 98.0 + i * 21;
        canvas.drawPath(
          Path()
            ..moveTo(61 + i * 6, y + 13)
            ..quadraticBezierTo(27, y, 30, y - 12)
            ..quadraticBezierTo(58, y - 12, 61 + i * 6, y + 13),
          paint,
        );
      }
      canvas.restore();
    }
    canvas.drawPath(
      Path()
        ..moveTo(89, 92)
        ..lineTo(160, 39)
        ..lineTo(231, 92)
        ..close(),
      paint..color = const Color(0xFFB9683D),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(102, 49, 116, 115),
        const Radius.circular(5),
      ),
      paint..color = const Color(0xFFFFFCF8),
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(114, 70.0 + i * 18, 92, 1.5),
        paint..color = const Color(0xFFEFE4DA),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(89, 92, 142, 89),
        const Radius.circular(4),
      ),
      paint..color = const Color(0xFFDDA065),
    );
    canvas.drawPath(
      Path()
        ..moveTo(89, 92)
        ..lineTo(160, 140)
        ..lineTo(231, 92)
        ..lineTo(231, 181)
        ..lineTo(89, 181)
        ..close(),
      paint..color = const Color(0xFFE8AF79),
    );
    canvas.drawPath(
      Path()
        ..moveTo(89, 181)
        ..lineTo(151, 136)
        ..quadraticBezierTo(160, 130, 169, 136)
        ..lineTo(231, 181)
        ..close(),
      paint..color = const Color(0xFFD98750),
    );
    if (sent) {
      canvas.drawCircle(
        const Offset(160, 88),
        24,
        paint..color = const Color(0xFF718765),
      );
      canvas.drawPath(
        Path()
          ..moveTo(149, 88)
          ..lineTo(157, 96)
          ..lineTo(173, 79),
        paint
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(146, 82, 28, 24),
          const Radius.circular(5),
        ),
        paint
          ..color = _resetClay
          ..style = PaintingStyle.fill,
      );
      canvas.drawArc(
        const Rect.fromLTWH(151, 68, 18, 25),
        3.14,
        3.14,
        false,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        const Offset(160, 93),
        2,
        paint
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }
    paint
      ..color = const Color(0xFFB96540)
      ..strokeWidth = 3;
    for (var i = 0; i < 3; i++) {
      final x = 146.0 + i * 14;
      canvas.drawLine(
        Offset(x, i == 1 ? 10 : 17),
        Offset(x + (i - 1) * 5, 28),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ResetEnvelopePainter oldDelegate) =>
      oldDelegate.sent != sent;
}
