import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/custom_button.dart';
import '../widgets/onboarding_story.dart';

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
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
      return;
    }
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

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
          constraints: const BoxConstraints(maxWidth: 560),
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
                      child: Image.asset(
                        'assets/images/branding/craftisan_bag_icon.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        semanticLabel: 'Craftisan shopping bag logo',
                      ),
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
                  onPageChanged: (value) {
                    setState(() => _page = value);
                  },
                  children: const [
                    OnboardingStory(index: 0),
                    OnboardingStory(index: 1),
                    OnboardingStory(index: 2),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 144,
                          child: Row(
                            children: List.generate(
                              3,
                              (index) => Semantics(
                                label: 'Page ${index + 1} of 3',
                                selected: _page == index,
                                button: true,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () => _goTo(index),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Center(
                                      child: AnimatedContainer(
                                        duration:
                                            MediaQuery.disableAnimationsOf(
                                              context,
                                            )
                                            ? Duration.zero
                                            : const Duration(milliseconds: 250),
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
                            onPressed: () =>
                                _page == 2 ? _finish() : _goTo(_page + 1),
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
