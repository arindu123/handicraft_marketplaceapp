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

  void _goTo(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeInOut,
  );

  void _finish() => Navigator.pushNamedAndRemoveUntil(
    context,
    RouteNames.roleSelection,
    (_) => false,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const CraftisanMark(size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'CRAFTISAN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _finish,
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
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
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
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
                                    height: 44,
                                    child: Center(
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: _page == index ? 26 : 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: _page == index
                                              ? AppColors.terracotta
                                              : AppColors.terracotta.withValues(
                                                  alpha: 0.18,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '0${_page + 1} / 03',
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (_page > 0) ...[
                          IconButton.outlined(
                            onPressed: () => _goTo(_page - 1),
                            tooltip: 'Previous page',
                            style: IconButton.styleFrom(
                              foregroundColor: AppColors.terracotta,
                              side: BorderSide(
                                color: AppColors.terracotta.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              minimumSize: const Size(54, 54),
                            ),
                            icon: const Icon(Icons.arrow_back, size: 20),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: CustomButton(
                            label: _page == 2 ? 'Choose Your Role' : 'Continue',
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

class _StoryPage extends StatelessWidget {
  const _StoryPage({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxHeight < 480;
      final photoHeight = (constraints.maxHeight * 0.57).clamp(170.0, 360.0);
      return SingleChildScrollView(
        key: PageStorageKey('onboarding-$index'),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          children: [
            _PotteryPortrait(index: index, height: photoHeight),
            SizedBox(height: compact ? 20 : 30),
            Text(
              [
                'THE ART OF HANDMADE',
                'MEET THE MAKERS',
                'MADE FOR YOUR HOME',
              ][index],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.terracotta,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              [
                'Handmade.\nMade for you.',
                'Meet the hands\nbehind the craft.',
                'Bring a little\nart home.',
              ][index],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: compact ? 34 : 40,
                height: 1.05,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                [
                  'Discover pottery with character, made by independent artisans.',
                  'Explore their studios, stories and signature pieces.',
                  'Find a piece you love. Support the maker who created it.',
                ][index],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PotteryPortrait extends StatelessWidget {
  const _PotteryPortrait({required this.index, required this.height});
  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maker = index == 1;
    final accent = maker ? AppColors.sage : AppColors.terracotta;
    const frame = BorderRadius.only(
      topLeft: Radius.circular(150),
      topRight: Radius.circular(150),
      bottomLeft: Radius.circular(28),
      bottomRight: Radius.circular(28),
    );
    return SizedBox(
      height: height + 18,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 18,
            left: 20,
            right: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: frame,
                border: Border.all(color: accent.withValues(alpha: 0.24)),
              ),
            ),
          ),
          Positioned(
            top: 10,
            bottom: 8,
            left: 8,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: frame,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: frame,
                child: Image.asset(
                  maker
                      ? 'lib/features/auth/widgets/pottery_mug.png'
                      : 'lib/features/auth/widgets/pottery_vase.png',
                  fit: BoxFit.cover,
                  alignment: Alignment(index == 2 ? 0.25 : 0, maker ? 0 : 0.4),
                  semanticLabel: maker
                      ? 'Handmade stoneware mug in a pottery studio'
                      : 'Terracotta vase with eucalyptus in a sunlit studio',
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 24,
            right: 24,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: accent.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      [
                        Icons.auto_awesome_outlined,
                        Icons.cottage_outlined,
                        Icons.favorite_border,
                      ][index],
                      size: 15,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        [
                          'Handmade finds',
                          'Studio stories',
                          'Direct from makers',
                        ][index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
