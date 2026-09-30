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
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _next() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.pushNamed(
      context,
      RouteNames.passwordResetCode,
      arguments: _email.text.trim(),
    );
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
          'Enter the verified email linked to your Craftisan atelier or collector archive. We’ll prepare a demo 6-digit code to restore access.',
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
                  'Demo preview only — no email or code will be sent.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                CustomButton(label: 'Send Verification Code', onPressed: _next),
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

class PasswordResetCodeScreen extends StatefulWidget {
  const PasswordResetCodeScreen({super.key});
  @override
  State<PasswordResetCodeScreen> createState() =>
      _PasswordResetCodeScreenState();
}

class _PasswordResetCodeScreenState extends State<PasswordResetCodeScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  String? _error;
  String get _email =>
      ModalRoute.of(context)?.settings.arguments as String? ??
      'your registered email';
  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _next() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _error = 'Enter all 6 code digits.');
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.pushNamed(
      context,
      RouteNames.passwordResetNew,
      arguments: _email,
    );
  }

  @override
  Widget build(BuildContext context) => _ResetFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ResetHeader(step: 'STEP 02 / 03 · AUTHENTICATION'),
        Text(
          'Verify Your Identity',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          'We’ve prepared a demo 6-digit authentication code for $_email. Enter any six digits to continue.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        _ResetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SECURITY PASSCODE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: AppColors.terracotta,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(
                  6,
                  (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 5 ? 0 : 7),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _nodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        onChanged: (value) {
                          if (value.isNotEmpty && i < 5) {
                            _nodes[i + 1].requestFocus();
                          }
                          setState(() => _error = null);
                        },
                        decoration: const InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.terracotta),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'End-to-end encrypted demo flow',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              CustomButton(label: 'Verify & Proceed', onPressed: _next),
              TextButton(
                onPressed: () => setState(() {
                  for (final c in _controllers) {
                    c.clear();
                  }
                  _error = 'A new demo code is ready to enter.';
                }),
                child: const Text('Request new code'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Try another email'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PasswordResetNewPasswordScreen extends StatefulWidget {
  const PasswordResetNewPasswordScreen({super.key});
  @override
  State<PasswordResetNewPasswordScreen> createState() =>
      _PasswordResetNewPasswordScreenState();
}

class _PasswordResetNewPasswordScreenState
    extends State<PasswordResetNewPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String get _email =>
      ModalRoute.of(context)?.settings.arguments as String? ??
      'your registered email';
  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _next() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.pushNamed(
      context,
      RouteNames.passwordResetSuccess,
      arguments: _email,
    );
  }

  @override
  Widget build(BuildContext context) => _ResetFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ResetHeader(step: 'STEP 3 OF 3 · CREDENTIAL UPDATE'),
        Text(
          'Create New Password',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        const Text(
          'Choose a new passcode for this demo flow. No account credentials will be changed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        _ResetCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'New Password',
                  controller: _password,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Enter a new password.' : null,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Use at least 8 characters, including a number and symbol.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Confirm New Password',
                  controller: _confirmation,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _next(),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Confirm your new password.';
                    return v == _password.text
                        ? null
                        : 'Passwords do not match.';
                  },
                ),
                const SizedBox(height: 18),
                CustomButton(
                  label: 'Reset Password & Continue',
                  onPressed: _next,
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.signIn,
                    (route) => route.isFirst,
                  ),
                  child: const Text('Cancel and return to Sign In'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
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
        const _ResetHeader(step: 'STEP 4 OF 4 · VERIFIED', backToSignIn: true),
        const Icon(Icons.verified, color: AppColors.sage, size: 72),
        const SizedBox(height: 18),
        Text(
          'Password Reset Successful!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your demo credentials have been updated. Your Craftisan workspace is ready for your next session.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        _ResetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WORKSPACE SYNCHRONIZED',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: AppColors.terracotta,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Account Updated',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _email(context),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              const Text(
                'Secured with demo 2FA',
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
