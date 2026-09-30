import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/custom_button.dart';
import '../widgets/craftisan_mark.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _finish() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.roleSelection,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                        ),
                        child: const CraftisanMark(size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CRAFTISAN',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'GUILD EDITION',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 0.6,
                                color: AppColors.terracotta,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _finish,
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (value) => setState(() => _page = value),
                    children: const [
                      _StoryPage(index: 0),
                      _StoryPage(index: 1),
                      _StoryPage(index: 2),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Semantics(
                            label: 'Page ${index + 1} of 3',
                            selected: _page == index,
                            button: true,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _goTo(index),
                              child: SizedBox(
                                width: 44,
                                height: 36,
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: _page == index ? 28 : 8,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _page == index
                                          ? AppColors.terracotta
                                          : const Color(0xFFE5E2DE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (_page > 0) ...[
                            IconButton.filledTonal(
                              onPressed: () => _goTo(_page - 1),
                              tooltip: 'Previous page',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.ink,
                                minimumSize: const Size(48, 48),
                              ),
                              icon: const Icon(Icons.arrow_back, size: 20),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: CustomButton(
                              label: [
                                'Next: Kiln Provenance',
                                'Next: Direct Patronage',
                                'Choose Your Role',
                              ][_page],
                              onPressed: () => _page == 2
                                  ? Navigator.pushNamed(
                                      context,
                                      RouteNames.roleSelection,
                                    )
                                  : _goTo(_page + 1),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _StoryPage extends StatelessWidget {
  const _StoryPage({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final photoHeight = (constraints.maxHeight * (index == 0 ? 0.53 : 0.40))
            .clamp(190.0, index == 0 ? 400.0 : 290.0);
        return SingleChildScrollView(
          key: PageStorageKey('onboarding-$index'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PotteryCard(index: index, height: photoHeight),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    [
                      Icons.circle,
                      Icons.workspace_premium_outlined,
                      Icons.favorite_border,
                    ][index],
                    size: index == 0 ? 6 : 15,
                    color: AppColors.terracotta,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      [
                        'WELCOME TO CRAFTISAN',
                        'PROVENANCE & INTEGRITY',
                        'DIRECT PATRONAGE',
                      ][index],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  'Discover Handcrafted\nPottery & Ceramic Artistry',
                  'Verified Kiln Batches &\nTransparent Lineage',
                  'Support the Hands\nBehind Every Creation',
                ][index],
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 14),
              Text(
                [
                  'Connect directly with independent ceramicists and master potters worldwide. Collect rare, slow-crafted vessels shaped by human hands.',
                  'Every creation includes a physical Certificate of Provenance detailing raw clay geology, firing timeline, and the master hands who shaped it.',
                  'Build a connection with the makers you love. Discover their stories, support independent studios, and collect pieces with a personal meaning.',
                ][index],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              if (index == 0)
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pill(
                      icon: Icons.cottage_outlined,
                      text: 'Direct from Studio',
                      color: AppColors.terracotta,
                    ),
                    SizedBox(height: 8),
                    _Pill(
                      icon: Icons.hourglass_empty,
                      text: 'Slow Craft Movement',
                      color: AppColors.sage,
                    ),
                    SizedBox(height: 8),
                    _Pill(
                      icon: Icons.local_fire_department_outlined,
                      text: 'Wood & Kiln Fired',
                      color: Color(0xFF98640D),
                    ),
                  ],
                ),
              if (index == 1)
                const Column(
                  children: [
                    _Feature(
                      icon: Icons.filter_vintage_outlined,
                      title: 'Numbered Editions & Maker Marks',
                      subtitle:
                          'Individual studio stamps pressed before curing',
                      color: AppColors.terracotta,
                    ),
                    SizedBox(height: 10),
                    _Feature(
                      icon: Icons.inventory_2_outlined,
                      title: 'Safe Fragile White-Glove Dispatch',
                      subtitle: 'Custom molded compostable wood-wool cradles',
                      color: AppColors.sage,
                    ),
                  ],
                ),
              if (index == 2)
                const Column(
                  children: [
                    _Feature(
                      icon: Icons.handshake_outlined,
                      title: 'A Direct Connection',
                      subtitle:
                          'Meet independent makers and their studio stories',
                      color: AppColors.terracotta,
                    ),
                    SizedBox(height: 10),
                    _Feature(
                      icon: Icons.favorite_border,
                      title: 'Collect with Intention',
                      subtitle: 'Thoughtful pieces. Lasting connections.',
                      color: AppColors.sage,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PotteryCard extends StatelessWidget {
  const _PotteryCard({required this.index, required this.height});
  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    final provenance = index == 1;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15493528),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: height,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      provenance
                          ? 'lib/features/auth/widgets/pottery_mug.png'
                          : 'lib/features/auth/widgets/pottery_vase.png',
                      fit: BoxFit.cover,
                      alignment: Alignment(0, provenance ? 0 : 0.4),
                      semanticLabel: provenance
                          ? 'Handmade speckled stoneware mug'
                          : 'Fluted terracotta vase with eucalyptus in a sunlit studio',
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      right: index == 0 ? 58 : 14,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _Pill(
                          icon: index == 2
                              ? Icons.favorite_border
                              : Icons.circle,
                          text: [
                            'Studio Fired · Cone 10',
                            'LIVE KILN RELEASE',
                            'DIRECT FROM THE MAKER',
                          ][index],
                          color: provenance
                              ? AppColors.sage
                              : AppColors.terracotta,
                          small: true,
                        ),
                      ),
                    ),
                    if (index == 0)
                      const Positioned(
                        top: 14,
                        right: 14,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.background,
                          child: Icon(
                            Icons.verified,
                            color: AppColors.terracotta,
                            size: 19,
                          ),
                        ),
                      ),
                    if (provenance)
                      const Positioned(
                        bottom: 12,
                        right: 12,
                        child: _Pill(
                          icon: Icons.local_fire_department_outlined,
                          text: 'Wood-Fired 1280°C',
                          color: Color(0xFF98640D),
                          small: true,
                        ),
                      ),
                    if (!provenance)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.palette_outlined,
                                size: 20,
                                color: AppColors.terracotta,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      index == 0 ? 'Fluted Terracotta Amphora' : 'Independent studios. Extraordinary stories.',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      index == 0
                                          ? 'Atelier Oread · Earthenware'
                                          : 'From their hands to your home',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (index == 0) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFF98640D),
                                  size: 14,
                                ),
                                const Flexible(
                                  child: Text(
                                    ' Masterwork',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (provenance)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 17,
                            backgroundColor: Color(0xFFFFDED1),
                            child: Icon(
                              Icons.verified,
                              size: 18,
                              color: AppColors.terracotta,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Guild Verified\nProvenance',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Archived in Guild Registry',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BATCH # KY–\n402',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          _Detail(
                            icon: Icons.landscape_outlined,
                            text: 'Kyoto Riverbed Sand',
                          ),
                          _Detail(
                            icon: Icons.draw_outlined,
                            text: 'Studio Stamp #14/25',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.color,
    this.small = false,
  });
  final IconData icon;
  final String text;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 11, vertical: small ? 5 : 6),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: icon == Icons.circle ? 7 : 15, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.terracotta),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ),
    ],
  );
}
