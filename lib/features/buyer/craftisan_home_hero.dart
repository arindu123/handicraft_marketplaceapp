import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A connected header, search, swipeable editorial carousel and benefits area.
class CraftisanHomeHero extends StatefulWidget {
  const CraftisanHomeHero({
    super.key,
    required this.onExplore,
    this.onSearch,
    this.header,
    this.preview = false,
    this.productImageBuilder,
  });
  final VoidCallback onExplore;
  final ValueChanged<String>? onSearch;
  final Widget? header;
  final bool preview;
  final Widget Function(BuildContext, int)? productImageBuilder;
  @override
  State<CraftisanHomeHero> createState() => _CraftisanHomeHeroState();
}

class _CraftisanHomeHeroState extends State<CraftisanHomeHero>
    with WidgetsBindingObserver {
  final _pages = PageController();
  final _query = TextEditingController();
  Timer? _timer;
  int _index = 0;
  bool _foreground = true;
  bool _reduceMotion = false;
  bool _dragging = false;
  bool _editing = false;

  static const _ink = AppColors.ink;
  static const _brown = AppColors.warmBrown;
  static const _titleStyle = TextStyle(
    fontSize: 26,
    height: 1.08,
    letterSpacing: -.7,
    fontWeight: FontWeight.w700,
    color: _ink,
  );
  static const _bodyStyle = TextStyle(
    fontSize: 12,
    height: 1.45,
    color: AppColors.muted,
  );
  static const _tagStyle = TextStyle(
    fontSize: 9,
    height: 1.2,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w700,
    color: _brown,
  );
  static const _buttonStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  static const _originalStories = [
    (
      tag: 'THE HANDMADE EDIT',
      title: 'Made slowly.\nLoved daily.',
      description: 'Find beauty in the little things, made by hand.',
      background: AppColors.heroCream,
      accent: AppColors.warmBrown,
      asset: 'lib/features/auth/widgets/pottery_vase.png',
    ),
    (
      tag: 'EVERYDAY RITUALS',
      title: 'A little craft.\nA lot of comfort.',
      description: 'Thoughtful pieces for your everyday moments.',
      background: AppColors.surface,
      accent: AppColors.sage,
      asset: 'lib/features/auth/widgets/pottery_mug.png',
    ),
    (
      tag: 'MEANINGFUL FINDS',
      title: 'One of a kind.\nJust like you.',
      description: 'Discover a piece that feels like you.',
      background: AppColors.surface,
      accent: AppColors.warmBrown,
      asset: 'lib/features/auth/widgets/pottery_vase.png',
    ),
  ];

  List<
    ({
      String tag,
      String title,
      String description,
      Color background,
      Color accent,
      String asset,
    })
  >
  get _stories => widget.preview
      ? [
          _originalStories[1],
          (
            tag: 'FESTIVAL PREVIEW',
            title: 'A celebration.\nOf handmade.',
            description: 'Discover the makers? festival. Sample offers, made for this preview.',
            background: AppColors.heroCream,
            accent: AppColors.warmBrown,
            asset: 'lib/features/auth/widgets/pottery_vase.png',
          ),
          (
            tag: 'NEW ARRIVALS',
            title: 'Fresh from\nthe studio.',
            description: 'Small-batch pieces with stories to tell.',
            background: AppColors.surface,
            accent: AppColors.warmBrown,
            asset: 'lib/features/auth/widgets/pottery_mug.png',
          ),
          (
            tag: 'DELIVERY PREVIEW',
            title: 'A little joy.\nDelivered.',
            description: 'Explore our sample free-shipping collection.',
            background: AppColors.heroCream,
            accent: AppColors.warmBrown,
            asset: 'lib/features/auth/widgets/pottery_vase.png',
          ),
          (
            tag: 'ARTISAN PICKS',
            title: 'Thoughtfully\nhandpicked.',
            description: 'Discover a piece that feels like you.',
            background: AppColors.surface,
            accent: AppColors.warmBrown,
            asset: 'lib/features/auth/widgets/pottery_mug.png',
          ),
        ]
      : _originalStories;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_foreground || _reduceMotion) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||
          !_pages.hasClients ||
          _dragging ||
          _editing ||
          !TickerMode.valuesOf(context).enabled ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      _pages.animateToPage(
        (_index + 1) % _stories.length,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    _query.dispose();
    super.dispose();
  }

  void _search() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.onSearch case final search?) {
      search(_query.text.trim());
    } else {
      widget.onExplore();
    }
  }

  double _textHeight(
    BuildContext context,
    String text,
    TextStyle style,
    double width,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
    color: _stories[_index].background,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.header != null) widget.header!,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _brown, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Focus(
                    onFocusChange: (focused) => _editing = focused,
                    child: TextField(
                      controller: _query,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search handmade pieces',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 21,
                          color: _brown,
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 34),
                        hintStyle: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.preview)
                  IconButton(
                    tooltip: 'Image search preview',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Image search is a preview feature and is not connected yet.',
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      size: 20,
                      color: AppColors.muted,
                    ),
                  ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _brown,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _search,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
        ),
        if (widget.preview)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 5, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'LOCAL PREVIEW ? SAMPLE OFFERS',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: .7,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(Icons.front_hand_outlined, size: 13),
                  label: Text('Handmade', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final showPhoto = MediaQuery.textScalerOf(context).scale(14) <= 20;
            final contentWidth = constraints.maxWidth - 36;
            final textWidth = showPhoto
                ? (contentWidth - 8) * .52
                : contentWidth;
            var height = constraints.maxWidth / 1.65;
            for (final story in _stories) {
              final copyHeight =
                  _textHeight(context, story.tag, _tagStyle, textWidth) +
                  _textHeight(context, story.title, _titleStyle, textWidth) +
                  _textHeight(
                    context,
                    story.description,
                    _bodyStyle,
                    textWidth,
                  ) +
                  math.max(
                    44,
                    _textHeight(
                          context,
                          'Explore pieces',
                          _buttonStyle,
                          textWidth - 28,
                        ) +
                        24,
                  ) +
                  82;
              height = math.max(height, copyHeight);
            }
            return SizedBox(
              height: height,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _dragging = true;
                  }
                  if (notification is ScrollEndNotification) {
                    _dragging = false;
                    _schedule();
                  }
                  return false;
                },
                child: PageView.builder(
                  key: const ValueKey('craftisan-hero-pages'),
                  controller: _pages,
                  itemCount: _stories.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    final story = _stories[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
                      child: Row(
                        children: [
                          SizedBox(
                            width: textWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(story.tag, style: _tagStyle),
                                const SizedBox(height: 10),
                                Text(story.title, style: _titleStyle),
                                const SizedBox(height: 10),
                                Text(story.description, style: _bodyStyle),
                                const SizedBox(height: 14),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _brown,
                                    foregroundColor: Colors.white,
                                    textStyle: _buttonStyle,
                                    minimumSize: const Size(0, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: widget.onExplore,
                                  child: const Text('Explore pieces'),
                                ),
                              ],
                            ),
                          ),
                          if (showPhoto) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .35),
                                  border: Border.all(
                                    color: AppColors.heroCream,
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.surface,
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: ExcludeSemantics(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child:
                                        widget.productImageBuilder?.call(
                                          context,
                                          index,
                                        ) ??
                                        Image.asset(
                                          story.asset,
                                          fit: BoxFit.contain,
                                          cacheWidth: 600,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: _brown),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'THE CRAFTISAN COLLECTION ? MADE WITH CARE',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1,
                    color: _brown,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              for (var dot = 0; dot < _stories.length; dot++)
                Semantics(
                  selected: dot == _index,
                  child: IconButton(
                    tooltip: 'Show story ${dot + 1}',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (_reduceMotion) {
                        _pages.jumpToPage(dot);
                      } else {
                        _pages.animateToPage(
                          dot,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    icon: Container(
                      width: dot == _index ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _brown.withValues(
                          alpha: dot == _index ? 1 : .25,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '${_index + 1} / ${_stories.length}',
                style: const TextStyle(fontSize: 11, color: _brown),
              ),
            ],
          ),
        ),
        ColoredBox(
          color: AppColors.trustBrown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: _CraftNote(
                    widget.preview
                        ? Icons.verified_user_outlined
                        : Icons.front_hand_outlined,
                    widget.preview ? 'Safe Payment' : 'Made by Hand',
                  ),
                ),
                SizedBox(
                  height: 22,
                  child: VerticalDivider(color: AppColors.muted, width: 10),
                ),
                Expanded(
                  child: _CraftNote(
                    widget.preview
                        ? Icons.local_shipping_outlined
                        : Icons.auto_awesome_outlined,
                    widget.preview ? 'Fast Delivery' : 'Thoughtful Finds',
                  ),
                ),
                SizedBox(
                  height: 22,
                  child: VerticalDivider(color: AppColors.muted, width: 10),
                ),
                Expanded(
                  child: _CraftNote(
                    widget.preview
                        ? Icons.assignment_return_outlined
                        : Icons.favorite_border,
                    widget.preview ? 'Free Return' : 'Chosen with Love',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CraftNote extends StatelessWidget {
  const _CraftNote(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 15, color: AppColors.heroCream),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            height: 1.3,
            color: AppColors.heroCream,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}
