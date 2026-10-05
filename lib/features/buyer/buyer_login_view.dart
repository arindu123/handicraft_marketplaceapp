import 'package:flutter/material.dart';

import '../../routes/route_names.dart';
import '../auth/models/marketplace_role.dart';

const _ink = Color(0xFF10494D);
const _paper = Color(0xFFFCF9F2);
const _rust = Color(0xFFB8512B);
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
                                const Icon(
                                  Icons.spa_outlined,
                                  size: 20,
                                  color: _rust,
                                ),
                              ],
                            ),
                            SizedBox(height: wide ? 28 : 18),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: reducedMotion ? 1 : 0,
                                end: 1,
                              ),
                              duration: Duration(
                                milliseconds: reducedMotion ? 0 : 850,
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
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
                                        const SizedBox(height: 26),
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
          const Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: _rust, shape: BoxShape.circle),
                child: SizedBox(width: 6, height: 6),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'YOUR NEXT FAVOURITE AWAITS',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.8,
                    color: _rust,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Good to see\nyou again.',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 48,
              height: .98,
              letterSpacing: -1.4,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sign in for lovely finds and the makers behind them.',
            style: TextStyle(fontSize: 13, height: 1.6, color: _muted),
          ),
          const SizedBox(height: 24),
          const Text(
            'Email address',
            style: TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.email,
            enabled: !widget.submitting,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: widget.validateEmail,
            decoration: _decoration('you@example.com', Icons.alternate_email),
          ),
          const SizedBox(height: 18),
          const Text(
            'Password',
            style: TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.password,
            enabled: !widget.submitting,
            obscureText: _hidden,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => widget.onSubmit(),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter your password.' : null,
            decoration: _decoration('Enter your password', Icons.lock_outline)
                .copyWith(
                  suffixIcon: IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _hidden = !_hidden),
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
                style: TextStyle(fontSize: 12, color: _ink),
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
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _ink.withValues(alpha: .7),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                    widget.submitting
                        ? 'Signing you in…'
                        : 'Sign In to Collection',
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
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE1DFD5))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR CONTINUE WITH',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    color: _muted,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE1DFD5))),
            ],
          ),
          const SizedBox(height: 16),
          _socialButton('Google'),
          const SizedBox(height: 12),
          _socialButton('Apple'),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'New to Artisan?',
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
                  'Sign Up',
                  style: TextStyle(color: _rust, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE1DFD5))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'JUST LOOKING?',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.3,
                    color: _muted,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE1DFD5))),
            ],
          ),
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: _muted),
    prefixIcon: Icon(icon, size: 19, color: _muted),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
      height: wide ? 650 : 205,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/features/auth/widgets/pottery_vase.png',
            fit: BoxFit.cover,
            alignment: wide ? Alignment.center : const Alignment(0, .28),
            excludeFromSemantics: true,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .05),
                  _ink.withValues(alpha: .82),
                ],
                stops: const [.25, 1],
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'THE ART OF EVERYDAY',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.3,
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: wide ? 36 : 20,
            left: wide ? 32 : 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wide
                      ? 'Not just a piece.\nA little piece\nof someone’s heart.'
                      : 'Objects with soul.\nStories worth keeping.',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: wide ? 45 : 29,
                    height: 1.04,
                    color: _paper,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (wide) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Meet independent makers. Discover the beauty\nin things made slowly, thoughtfully, by hand.',
                    style: TextStyle(
                      color: Color(0xFFE2E6DD),
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(height: 1, color: Colors.white24),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        size: 17,
                        color: Color(0xFFE9BD79),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Small studios. Beautiful possibilities.',
                          style: TextStyle(color: _paper, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
