import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// Keep the stories and their bundled assets together, independent of auth state.
const _stories = [
  (
    eyebrow: 'THOUGHTFULLY FOUND',
    title: 'Discover Handmade Products',
    description: 'Find one-of-a-kind pieces with a story. Bring the warmth of handmade into your everyday.',
    image: 'assets/images/onboarding/discover.jpeg',
    imageLabel: 'A curated collection of woven baskets and handmade ceramics',
    badge: 'One of a kind',
    detail: 'Made with care',
    icon: Icons.auto_awesome_outlined,
  ),
  (
    eyebrow: 'BEHIND EVERY PIECE',
    title: 'Empower Artisans',
    description: 'Meet independent makers, celebrate their skills, and support the craft they love.',
    image: 'assets/images/onboarding/artisans.jpeg',
    imageLabel: 'An artisan shaping a clay pot on a pottery wheel',
    badge: 'Support local makers',
    detail: 'Crafted with purpose',
    icon: Icons.volunteer_activism_outlined,
  ),
  (
    eyebrow: 'FROM STUDIO TO DOORSTEP',
    title: 'Shop with Delivery',
    description: 'Discover something special and have it delivered. A little closer to the things you love.',
    image: 'assets/images/onboarding/delivery.jpeg',
    imageLabel: 'Hands carefully wrapping a ceramic bowl for delivery',
    badge: 'To your doorstep',
    detail: 'A little joy, delivered',
    icon: Icons.local_shipping_outlined,
  ),
];

/// A scrollable editorial story that accommodates short screens and large text.
class OnboardingStory extends StatelessWidget {
  const OnboardingStory({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final story = _stories[index];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520;
        final photoHeight = (constraints.maxHeight * .58).clamp(180.0, 420.0);
        return SingleChildScrollView(
          key: PageStorageKey('onboarding-$index'),
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StoryPhoto(index: index, height: photoHeight),
              SizedBox(height: compact ? 22 : 30),
              Text(
                story.eyebrow,
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                header: true,
                child: Text(
                  story.title,
                  style: const TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 42,
                    height: 1.02,
                    letterSpacing: -1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                story.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StoryPhoto extends StatelessWidget {
  const _StoryPhoto({required this.index, required this.height});

  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    final story = _stories[index];
    final accent = index == 1 ? AppColors.sage : AppColors.terracotta;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: SizedBox(
        height: height + 24,
        child: Stack(
          children: [
            Positioned.fill(
              left: 12,
              bottom: 20,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: accent.withValues(alpha: .25)),
                ),
              ),
            ),
            Positioned.fill(
              top: 8,
              right: 8,
              bottom: 12,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      story.image,
                      fit: BoxFit.cover,
                      semanticLabel: story.imageLabel,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x66000000)],
                          stops: [.55, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 34,
                      left: 20,
                      right: 20,
                      child: Text(
                        story.detail,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 16,
              right: 16,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accent.withValues(alpha: .15)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(story.icon, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          story.badge,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
