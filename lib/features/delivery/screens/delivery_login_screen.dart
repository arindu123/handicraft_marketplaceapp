import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/domain_models.dart' show UserRole;
import '../../auth/models/marketplace_role.dart';
import '../../auth/services/auth_session.dart';
import '../widgets/delivery_widgets.dart';
import '../widgets/delivery_banner.dart';
import '../services/courier_google_sign_in.dart';

class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key, this.googleSignIn});
  final Future<UserRole?> Function()? googleSignIn;
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
                'courierApproval': 'pending',
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
          await FirebaseFirestore.instance
              .collection('courierPublicProfiles')
              .doc(user.uid)
              .set({
                'displayName': name,
                'area': '',
                'photoUrl': '',
                'phone': user.phoneNumber ?? '',
              });
        } catch (_) {
          _incompleteSignup = user;
          await _cleanUpSignup();
          throw const ProfileException(
            'We could not save your profile. Your new account was removed. Please try signing up again.',
          );
        }
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() => _register = false);
          _password.clear();
          showDeliveryNotice(
            context,
            'Application sent',
            'Your courier details have been sent to admin. You can log in after your account is approved.',
          );
        }
        return;
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

  Future<void> _googleSignIn() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      if (_incompleteSignup != null) await _cleanUpSignup();
      final role =
          await (widget.googleSignIn?.call() ?? CourierGoogleSignIn().signIn());
      if (role == null ||
          !mounted ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
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
          'Unable to sign in with Google',
          AuthSession.message(error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                    Column(
                      children: [
                        _social('Google'),
                        const SizedBox(height: 10),
                        _social('Apple'),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _social(String name) => OutlinedButton(
    onPressed: _submitting
        ? null
        : name == 'Google'
        ? _googleSignIn
        : () => showDeliveryNotice(
            context,
            '$name sign-in',
            '$name sign-in is not connected yet. Please use email or Google to sign in.',
          ),
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1F1F1F),
      side: const BorderSide(color: Color(0xFFDADCE0)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Row(
      children: [
        ExcludeSemantics(
          child: name == 'Google'
              ? Image.asset(
                  'lib/features/auth/widgets/google_logo.png',
                  width: 22,
                  height: 22,
                )
              : const Icon(Icons.apple, color: Colors.black, size: 25),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Continue with $name',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 22),
      ],
    ),
  );
}
