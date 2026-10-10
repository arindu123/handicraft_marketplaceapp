import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';
import '../models/marketplace_role.dart';

export '../models/marketplace_role.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  MarketplaceRole _selected = MarketplaceRole.artisan;
  bool get _signIn =>
      ModalRoute.of(context)?.settings.arguments == AuthEntry.signIn;

  void _openAuth({bool? signIn}) {
    if (_selected == MarketplaceRole.buyer) {
      Navigator.pushNamed(context, RouteNames.buyerLanding);
      return;
    }
    Navigator.pushNamed(
      context,
      _selected == MarketplaceRole.courier
          ? RouteNames.deliverySplash
          : (signIn ?? _signIn)
          ? RouteNames.signIn
          : RouteNames.signUp,
      arguments: _selected == MarketplaceRole.courier
          ? ((signIn ?? _signIn) ? AuthEntry.signIn : AuthEntry.signUp)
          : _selected,
    );
  }

  static const accent = Color(0xFFC35D3D);
  static const roles = [
    (
      role: MarketplaceRole.artisan,
      title: 'Artisan / Studio Maker',
      description: 'List handcrafted pieces, manage batches, track inventory, and connect directly with patrons.',
      icon: Icons.palette_outlined,
    ),
    (
      role: MarketplaceRole.buyer,
      title: 'Buyer / Patron',
      description: 'Explore curated ceramic studios, buy unique pieces, and commission custom works.',
      icon: Icons.shopping_bag_outlined,
    ),
    (
      role: MarketplaceRole.courier,
      title: 'Fragile Delivery Courier',
      description: 'Specialized courier handling verified fragile ceramic and stoneware consignments.',
      icon: Icons.local_shipping_outlined,
    ),
    (
      role: MarketplaceRole.admin,
      title: 'Marketplace Curator & Admin',
      description: 'Review studio submissions, oversee guild quality standards, and manage platform governance.',
      icon: Icons.workspace_premium_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 38).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF5F1EC),
                          border: Border.all(color: const Color(0xFFEADCD2)),
                        ),
                        child: Image.asset(
                          'assets/images/branding/craftisan_bag_icon.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          semanticLabel: 'Craftisan shopping bag logo',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'CRAFTISAN GUILD',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w500,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Roles Selection',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 31,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Select your role to get started with the marketplace and studio operations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 22),
                    for (final role in roles) ...[
                      _RoleCard(
                        title: role.title,
                        description: role.description,
                        icon: role.icon,
                        selected: _selected == role.role,
                        onTap: () {
                          setState(() => _selected = role.role);
                          if (role.role == MarketplaceRole.buyer) _openAuth();
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => _openAuth(),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        elevation: 2,
                        shadowColor: const Color(0x40C35D3D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _openAuth(signIn: !_signIn),
                      child: Text(
                        _signIn
                            ? 'New to Craftisan? Sign Up'
                            : 'Already have an account? Sign In',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Text(
                      'You can switch roles any time in account settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = _RoleSelectionScreenState.accent;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? const Color(0xFFFCF5F1) : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: BorderSide(
            color: selected ? accent : const Color(0xFFE9D9D0),
            width: selected ? 1.7 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? accent : const Color(0xFFEBE8E4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected ? Colors.white : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          if (selected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: Icon(
                    selected ? Icons.arrow_forward : Icons.chevron_right,
                    size: 19,
                    color: selected ? accent : const Color(0xFFDBBFB1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
