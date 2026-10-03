import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_session.dart';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../widgets/craftisan_mark.dart';

class _ResetFrame extends StatelessWidget {
  const _ResetFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class _ResetHeader extends StatelessWidget {
  const _ResetHeader({required this.step, this.backToSignIn = false});
  final String step;
  final bool backToSignIn;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          IconButton(
            tooltip: backToSignIn ? 'Back to Sign In' : 'Back',
            onPressed: () => backToSignIn
                ? Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.signIn,
                    (route) => route.isFirst,
                  )
                : Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const Spacer(),
          const Text(
            'CRAFTISAN GUILD',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.sage,
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      const CircleAvatar(
        radius: 32,
        backgroundColor: AppColors.surface,
        child: CraftisanMark(size: 38),
      ),
      const SizedBox(height: 18),
      Text(
        step,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.1,
          color: AppColors.terracotta,
          fontWeight: FontWeight.w600,
        ),
      ),
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
      borderRadius: BorderRadius.circular(18),
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
        const _ResetHeader(step: 'SECURITY PROTOCOL', backToSignIn: true),
        Text(
          'Recover Your Passcode',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        const Text(
          'Enter your Craftisan email address. We will send a link to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            Chip(label: Text('Collector Vault')),
            Chip(label: Text('Artisan Studio')),
          ],
        ),
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
                    style: const TextStyle(color: AppColors.terracotta),
                  ),
                CustomButton(label: 'Send Reset Email', onPressed: _next),
              ],
            ),
          ),
        ),
        TextButton(
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

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});
  String _email(BuildContext context) =>
      ModalRoute.of(context)?.settings.arguments as String? ??
      'your registered email';
  @override
  Widget build(BuildContext context) => _ResetFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ResetHeader(step: 'CHECK YOUR EMAIL', backToSignIn: true),
        const Icon(Icons.verified, color: AppColors.sage, size: 72),
        const SizedBox(height: 18),
        Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        const Text(
          'If an account exists for this email, you will receive a reset link. Follow it to change your password, then return to sign in.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        _ResetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PASSWORD RESET REQUEST',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: AppColors.terracotta,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Email address',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _email(context),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your password changes only after completing the emailed reset link.',
                style: TextStyle(color: AppColors.sage),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CustomButton(
          label: 'Back to Sign In',
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.signIn,
            (route) => route.isFirst,
          ),
        ),
      ],
    ),
  );
}
