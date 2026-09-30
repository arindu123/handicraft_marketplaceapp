import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'craftisan_mark.dart';
import '../models/marketplace_role.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key, required this.isSignUp});
  final bool isSignUp;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  MarketplaceRole _role = MarketplaceRole.artisan;
  bool get _artisan => _role == MarketplaceRole.artisan;
  bool get _admin => _role == MarketplaceRole.admin;
  bool _remember = false;
  bool _roleInitialized = false;
  String? _message;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_roleInitialized) {
      final role = ModalRoute.of(context)?.settings.arguments;
      if (role is MarketplaceRole) _role = role;
      _roleInitialized = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _message = null);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Validation does not authenticate. Connect an auth service here later.
    setState(
      () => _message = widget.isSignUp
          ? 'Account creation is not available yet. Please try again later.'
          : 'Sign in is not available yet. Please try again later.',
    );
  }

  void _unavailable(String feature) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature is not available yet. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final signUp = widget.isSignUp;
    final buttonLabel = signUp ? _role.signUpLabel : _role.signInLabel;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(
                              context,
                              RouteNames.welcome,
                            );
                          }
                        },
                        icon: const Icon(Icons.arrow_back, size: 21),
                      ),
                      const Spacer(),
                      const Flexible(
                        child: Text(
                          'CRAFTISAN GUILD',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            color: AppColors.sage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: const CraftisanMark(size: 38),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _admin
                                  ? 'MARKETPLACE CURATOR · GUILD EDITION'
                                  : _artisan
                                  ? 'ARTISAN POTTER · GUILD EDITION'
                                  : 'THOUGHTFUL COLLECTOR · GUILD EDITION',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF91620E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              signUp
                                  ? 'Begin your Craftisan story'
                                  : 'Welcome back to Craftisan',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.6,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _admin
                                  ? (signUp
                                        ? 'Create your curator profile. Administrative access requires approval.'
                                        : 'Sign in to your approved marketplace administration account.')
                                  : signUp
                                  ? (_artisan
                                        ? 'Create your studio account and share your craft with thoughtful collectors.'
                                        : 'Find pieces with a story. Create an account and begin your collection.')
                                  : (_artisan
                                        ? 'Continue your studio journey, manage creations, or discover handcrafted pieces.'
                                        : 'Return to your collection and discover the makers behind your favourite pieces.'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFEEEB),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _admin
                                        ? Icons.workspace_premium_outlined
                                        : _artisan
                                        ? Icons.palette_outlined
                                        : Icons.diamond_outlined,
                                    size: 19,
                                    color: AppColors.terracotta,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _role.label,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.terracotta,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (signUp) ...[
                                    CustomTextField(
                                      label: 'Full name',
                                      controller: _name,
                                      icon: Icons.person_outline,
                                      keyboardType: TextInputType.name,
                                      autofillHints: const [AutofillHints.name],
                                      validator: (value) =>
                                          (value?.trim().isEmpty ?? true)
                                          ? 'Enter your full name.'
                                          : null,
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  CustomTextField(
                                    label: _artisan
                                        ? 'Studio Email'
                                        : 'Email address',
                                    controller: _email,
                                    icon: Icons.mail_outline,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 18),
                                  CustomTextField(
                                    label: 'Password',
                                    controller: _password,
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    autofillHints: [
                                      signUp
                                          ? AutofillHints.newPassword
                                          : AutofillHints.password,
                                    ],
                                    textInputAction: signUp
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    onFieldSubmitted: signUp
                                        ? null
                                        : (_) => _submit(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter your password.';
                                      }
                                      if (signUp && value.length < 8) {
                                        return 'Use at least 8 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (signUp) ...[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8, left: 4),
                                      child: Text(
                                        'Use at least 8 characters.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    CustomTextField(
                                      label: 'Confirm password',
                                      controller: _confirmation,
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Confirm your password.';
                                        }
                                        return value != _password.text
                                            ? 'Passwords do not match.'
                                            : null;
                                      },
                                    ),
                                  ] else ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () =>
                                            _unavailable('Password reset'),
                                        child: const Text(
                                          'Forgot password?',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    Material(
                                      color: Colors.white,
                                      child: CheckboxListTile(
                                        value: _remember,
                                        onChanged: (value) => setState(
                                          () => _remember = value ?? false,
                                        ),
                                        title: Text(
                                          _artisan
                                              ? 'Remember this studio device'
                                              : 'Remember this device',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        activeColor: AppColors.terracotta,
                                        checkboxShape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (_message != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Semantics(
                                        liveRegion: true,
                                        child: Text(
                                          _message!,
                                          style: const TextStyle(
                                            color: AppColors.terracotta,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  CustomButton(
                                    label: buttonLabel,
                                    onPressed: _submit,
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      Navigator.pushNamed(
                                        context,
                                        _admin
                                            ? RouteNames.adminDashboard
                                            : RouteNames.marketplace,
                                        arguments: _role,
                                      );
                                    },
                                    child: Text(
                                      _admin
                                          ? 'Preview Admin Dashboard'
                                          : 'Continue without an account',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Color(0xFFE5DCD4)),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'OR CONTINUE WITH',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Color(0xFFE5DCD4)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _socialButton('Apple', Icons.apple),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: _socialButton('Google', null)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.spa_outlined,
                                    color: AppColors.sage,
                                    size: 23,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _admin
                                              ? 'Care for the Craftisan community'
                                              : _artisan
                                              ? 'A home for your craft'
                                              : 'A collection with meaning',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _admin
                                              ? 'Curator permissions are granted only to approved accounts.'
                                              : _artisan
                                              ? 'Connect your studio with people who value the art of making.'
                                              : 'Meet independent makers and find handcrafted pieces to cherish.',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  signUp
                                      ? 'Already have an account?'
                                      : 'New to Craftisan?',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(
                                        context,
                                        signUp
                                            ? RouteNames.signIn
                                            : RouteNames.signUp,
                                        arguments: _role,
                                      ),
                                  child: Text(
                                    signUp ? 'Sign In' : 'Sign Up',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String provider, IconData? icon) => OutlinedButton(
    onPressed: () => _unavailable('$provider sign in'),
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      side: const BorderSide(color: AppColors.surface),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null)
          Icon(icon, size: 21)
        else
          const Text(
            'G',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4285F4),
            ),
          ),
        const SizedBox(width: 8),
        Flexible(child: Text(provider)),
      ],
    ),
  );
}
