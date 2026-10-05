import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../routes/route_names.dart';
import '../../../shared/models/domain_models.dart' show UserRole;
import '../../auth/models/marketplace_role.dart';
import '../../auth/services/auth_session.dart';
import '../widgets/delivery_widgets.dart';
import '../widgets/delivery_banner.dart';

class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key});
  @override
  State<DeliveryLoginScreen> createState() => _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState extends State<DeliveryLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _hidden = true;
  bool _submitting = false;
  bool _remember = true;
  bool _register = false;
  bool _entryInitialized = false;
  User? _incompleteSignup;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_entryInitialized) {
      _register =
          ModalRoute.of(context)?.settings.arguments == AuthEntry.signUp;
      _entryInitialized = true;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final registering = _register;
    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();
    setState(() => _submitting = true);
    try {
      final UserRole role;
      if (registering) {
        if (_incompleteSignup != null) await _cleanUpSignup();
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final user = credential.user!;
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'uid': user.uid,
                'email': user.email ?? email,
                'displayName': name,
                'role': UserRole.courier.name,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
        } catch (_) {
          _incompleteSignup = user;
          await _cleanUpSignup();
          throw const ProfileException(
            'We could not save your profile. Your new account was removed. Please try signing up again.',
          );
        }
        role = UserRole.courier;
      } else {
        role = await AuthSession.signIn(email, password);
      }
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AuthSession.route(role),
        (_) => false,
        arguments: AuthSession.selection(role),
      );
    } catch (error) {
      if (mounted) {
        showDeliveryNotice(
          context,
          registering ? 'Unable to sign up' : 'Unable to sign in',
          AuthSession.message(error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cleanUpSignup() async {
    try {
      await _incompleteSignup!.delete();
      _incompleteSignup = null;
    } catch (_) {
      throw const ProfileException(
        'We could not finish account setup or remove the incomplete account. Check your connection and submit again to retry cleanup. If this continues, contact support.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => DeliveryFrame(
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              const DeliveryBanner(),
              const Positioned(
                top: 24,
                left: 20,
                child: ParcelWordmark(size: 19),
              ),
              Positioned(
                left: 12,
                bottom: 16,
                child: IconButton.filledTonal(
                  tooltip: 'Back to roles',
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _register
                          ? 'Create your courier account'
                          : 'Welcome Back',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: DeliveryStyle.ink,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          hintText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline, size: 19),
                        ),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter your name.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'Email address',
                        prefixIcon: Icon(Icons.mail_outline, size: 19),
                      ),
                      validator: (value) {
                        final input = value?.trim() ?? '';
                        if (input.isEmpty) {
                          return 'Enter your email address.';
                        }
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(input)) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidden,
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      autofillHints: [
                        _register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 19),
                        suffixIcon: IconButton(
                          tooltip: _hidden ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _hidden = !_hidden),
                          icon: Icon(
                            _hidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 19,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password.'
                          : _register && value.length < 8
                          ? 'Use at least 8 characters.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    if (!_register)
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _remember = !_remember),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _remember,
                                  onChanged: (value) => setState(
                                    () => _remember = value ?? false,
                                  ),
                                  activeColor: DeliveryStyle.orange,
                                  shape: const CircleBorder(),
                                ),
                                const Flexible(
                                  child: Text(
                                    'Keep me signed in',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: DeliveryStyle.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => showDeliveryNotice(
                              context,
                              'Password reset',
                              'Password reset will be available when delivery accounts launch.',
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 11,
                                color: DeliveryStyle.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    DeliveryButton(
                      label: _submitting
                          ? (_register
                                ? 'Creating account...'
                                : 'Signing in...')
                          : (_register ? 'Sign Up' : 'Log In'),
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                        Flexible(
                          flex: 3,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Or Continue With',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: DeliveryStyle.muted,
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _social('Google', Icons.g_mobiledata)),
                        const SizedBox(width: 12),
                        Expanded(child: _social('Apple', Icons.apple)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _register
                              ? 'Already have an account?'
                              : "Don't have any account?",
                          style: const TextStyle(
                            fontSize: 12,
                            color: DeliveryStyle.muted,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (_submitting) return;
                            _form.currentState?.reset();
                            setState(() => _register = !_register);
                          },
                          child: Text(
                            _register ? 'Log In' : 'Sign Up',
                            style: const TextStyle(
                              color: DeliveryStyle.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        RouteNames.deliveryHome,
                      ),
                      child: const Text(
                        'Quick Track as Guest  →',
                        style: TextStyle(
                          color: DeliveryStyle.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      'Explore sample deliveries. No account required.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: DeliveryStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _social(String name, IconData icon) => FilledButton.tonalIcon(
    onPressed: () => showDeliveryNotice(
      context,
      '$name sign-in',
      '$name sign-in is not connected yet. You can explore as a guest.',
    ),
    style: FilledButton.styleFrom(
      backgroundColor: DeliveryStyle.surface,
      foregroundColor: DeliveryStyle.ink,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    icon: Icon(
      icon,
      size: 23,
      color: name == 'Google' ? const Color(0xFF4285F4) : DeliveryStyle.ink,
    ),
    label: Text(name),
  );
}
