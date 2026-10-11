import 'package:flutter/material.dart';

import '../../routes/route_names.dart';
import '../auth/models/marketplace_role.dart';

const _ink = Color(0xFF0B4545);
const _paper = Color(0xFFF8F5F1);
const _rust = Color(0xFFB44A2C);
const _muted = Color(0xFF687571);

/// Buyer presentation; authentication and validation stay in AuthForm.
class BuyerLoginView extends StatefulWidget {
  const BuyerLoginView({
    super.key,
    required this.formKey,
    required this.email,
    required this.password,
    required this.validateEmail,
    required this.submitting,
    required this.message,
    required this.onSubmit,
    required this.onSocialSignIn,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final FormFieldValidator<String> validateEmail;
  final bool submitting;
  final String? message;
  final VoidCallback onSubmit;
  final ValueChanged<String> onSocialSignIn;

  @override
  State<BuyerLoginView> createState() => _BuyerLoginViewState();
}

class _BuyerLoginViewState extends State<BuyerLoginView> {
  bool _hidden = true;

  void _back() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, RouteNames.buyerLanding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _ink,
          primary: _ink,
          surface: _paper,
        ),
      ),
      child: Scaffold(
        backgroundColor: _paper,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final wide = viewport.maxWidth >= 850;
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Padding(
                        padding: EdgeInsets.all(wide ? 32 : 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Back',
                                  onPressed: _back,
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Artisan',
                                        style: TextStyle(
                                          fontFamily: 'CormorantGaramond',
                                          fontSize: 29,
                                          height: 1,
                                          fontWeight: FontWeight.w700,
                                          color: _ink,
                                        ),
                                      ),
                                      Text(
                                        'M A R K E T P L A C E',
                                        style: TextStyle(
                                          fontSize: 7,
                                          color: _rust,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Image.asset(
                                  'assets/images/branding/craftisan_bag_icon.png',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'Craftisan shopping bag logo',
                                ),
                              ],
                            ),
                            SizedBox(height: wide ? 28 : 12),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: reducedMotion ? 1 : .85,
                                end: 1,
                              ),
                              duration: Duration(
                                milliseconds: reducedMotion ? 0 : 380,
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 12 * (1 - value)),
                                  child: child,
                                ),
                              ),
                              child: wide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Expanded(
                                          child: _CraftStory(wide: true),
                                        ),
                                        const SizedBox(width: 56),
                                        Expanded(child: _form()),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        const _CraftStory(wide: false),
                                        const SizedBox(height: 18),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: _form(),
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'THOUGHTFULLY MADE. MEANINGFULLY YOURS.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.4,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _form() => AutofillGroup(
    child: Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome to Craftisan',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 36,
              height: 1.08,
              letterSpacing: -.8,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Discover unique handmade products and support local artisans.',
            style: TextStyle(fontSize: 13, height: 1.5, color: _muted),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: widget.email,
            enabled: !widget.submitting,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: widget.validateEmail,
            decoration: _decoration(
              'Email address',
              'you@example.com',
              Icons.mail_outline,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: widget.password,
            enabled: !widget.submitting,
            obscureText: _hidden,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!widget.submitting) widget.onSubmit();
            },
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter your password.' : null,
            decoration:
                _decoration(
                  'Password',
                  'Enter your password',
                  Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    onPressed: widget.submitting
                        ? null
                        : () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: _muted,
                    ),
                  ),
                ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.submitting
                  ? null
                  : () => Navigator.pushNamed(
                      context,
                      RouteNames.passwordResetRequest,
                    ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 13, color: _rust),
              ),
            ),
          ),
          if (widget.message != null) ...[
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.message!,
                  style: const TextStyle(color: Color(0xFF963C25), height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          FilledButton(
            onPressed: widget.submitting ? null : widget.onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: _rust,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _rust.withValues(alpha: .7),
              minimumSize: const Size(48, 54),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.submitting) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    widget.submitting ? 'Signing in…' : 'Sign In',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (!widget.submitting) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE1DFD5))),
              Flexible(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'OR CONTINUE WITH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      color: _muted,
                    ),
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE1DFD5))),
            ],
          ),
          const SizedBox(height: 16),
          _socialButton('Google'),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'New here?',
                style: TextStyle(fontSize: 12, color: _muted),
              ),
              TextButton(
                onPressed: widget.submitting
                    ? null
                    : () => Navigator.pushReplacementNamed(
                        context,
                        RouteNames.signUp,
                        arguments: MarketplaceRole.buyer,
                      ),
                child: const Text(
                  'Create an account',
                  style: TextStyle(color: _rust, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: widget.submitting
                ? null
                : () => Navigator.pushNamed(
                    context,
                    RouteNames.marketplace,
                    arguments: MarketplaceRole.buyer,
                  ),
            icon: const Icon(Icons.explore_outlined, size: 18, color: _ink),
            label: const Text(
              'Continue without an account',
              style: TextStyle(color: _ink, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _socialButton(String provider) => OutlinedButton(
    onPressed: widget.submitting ? null : () => widget.onSocialSignIn(provider),
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1F1F1F),
      side: const BorderSide(color: Color(0xFFDADCE0)),
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Row(
      children: [
        ExcludeSemantics(
          child: provider == 'Google'
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
            'Continue with $provider',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 22),
      ],
    ),
  );

  InputDecoration _decoration(String label, String hint, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontSize: 14),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _muted),
        prefixIcon: Icon(icon, size: 19, color: _muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        errorMaxLines: 3,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDDCD2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _ink, width: 1.5),
        ),
      );
}

class _CraftStory extends StatelessWidget {
  const _CraftStory({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(wide ? 32 : 24),
    child: SizedBox(
      height: wide ? 460 : 132,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/onboarding/discover.jpeg',
            fit: BoxFit.cover,
            alignment: const Alignment(0, .65),
            semanticLabel:
                'Handcrafted ceramics, woven baskets and handmade decorations',
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x660B4545)],
                stops: [.3, 1],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 18,
            right: 18,
            child: Text(
              wide
                  ? 'Bring handmade\nhappiness home.'
                  : 'HANDCRAFTED MARKETPLACE',
              style: TextStyle(
                fontFamily: wide ? 'CormorantGaramond' : null,
                fontSize: wide ? 40 : 10,
                letterSpacing: wide ? -.6 : 1.5,
                height: 1.1,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
