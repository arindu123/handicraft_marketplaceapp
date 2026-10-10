import 'package:flutter/material.dart';

import '../../routes/route_names.dart';
import '../auth/models/marketplace_role.dart';

const _teal = Color(0xFF10494D);
const _clay = Color(0xFFB8512B);
const _cream = Color(0xFFFCF9F2);

class BuyerLandingScreen extends StatefulWidget {
  const BuyerLandingScreen({super.key});

  @override
  State<BuyerLandingScreen> createState() => _BuyerLandingScreenState();
}

class _BuyerLandingScreenState extends State<BuyerLandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _opening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else if (!_reveal.isAnimating && _reveal.value == 0) {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _login() {
    if (_opening) return;
    _opening = true;
    Navigator.pushReplacementNamed(
      context,
      RouteNames.signIn,
      arguments: MarketplaceRole.buyer,
    );
  }

  Widget _enter(double start, Widget child) {
    final progress = CurvedAnimation(
      parent: _reveal,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(progress),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _cream,
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.4),
          radius: 1.1,
          colors: [Color(0xFFFFFDF8), Color(0xFFF2EBDD)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back to roles',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: _teal),
                  ),
                  const Expanded(
                    child: Text(
                      'MADE BY HAND. CHOSEN BY YOU.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.4,
                        color: _teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, bounds) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (bounds.maxHeight - 48).clamp(
                          0,
                          double.infinity,
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _enter(0, const _ArtisanBrand()),
                              const SizedBox(height: 32),
                              _enter(
                                .18,
                                Column(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 2,
                                      color: const Color(0xFFD49A43),
                                    ),
                                    const SizedBox(height: 22),
                                    const Text(
                                      'Find something\nbeautifully handmade.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'CormorantGaramond',
                                        fontSize: 38,
                                        height: 1.05,
                                        fontWeight: FontWeight.w600,
                                        color: _teal,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Discover thoughtful pieces, meet their makers,\nand bring a little craft into your everyday.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.7,
                                        color: Color(0xFF77776C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 26),
                              _enter(
                                .35,
                                const Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 18,
                                  runSpacing: 12,
                                  children: [
                                    _Detail(Icons.spa_outlined, 'Unique finds'),
                                    _Detail(
                                      Icons.favorite_border,
                                      'Made with care',
                                    ),
                                    _Detail(
                                      Icons.handshake_outlined,
                                      'Meet the makers',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              _enter(
                                .48,
                                FilledButton(
                                  onPressed: _login,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _teal,
                                    foregroundColor: _cream,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 19,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text('Continue to login'),
                                      ),
                                      SizedBox(width: 14),
                                      Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _enter(
                                .6,
                                const Text(
                                  'A little more meaning in every purchase.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF77776C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: _clay),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 10, color: _teal)),
    ],
  );
}

class _ArtisanBrand extends StatelessWidget {
  const _ArtisanBrand();

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Artisan Marketplace',
    child: ExcludeSemantics(
      child: Column(
        children: [
          Image.asset(
            'assets/images/branding/craftisan_bag_icon.png',
            width: 172,
            height: 172,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          const FittedBox(
            child: Text(
              'Artisan',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 68,
                height: 1,
                fontWeight: FontWeight.w700,
                color: _teal,
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            '—  M A R K E T P L A C E  —',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _clay,
            ),
          ),
        ],
      ),
    ),
  );
}
