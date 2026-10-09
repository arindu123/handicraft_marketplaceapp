import 'dart:async';

import 'package:flutter/material.dart';

/// Keeps promotional copy still while product photography gently changes.
class RotatingProductBanner extends StatefulWidget {
  const RotatingProductBanner({
    super.key,
    required this.imageKeys,
    required this.imageBuilder,
    this.slide = false,
    this.expand = true,
  });
  final List<String> imageKeys;
  final bool slide;
  final bool expand;
  final Widget Function(BuildContext, int) imageBuilder;

  @override
  State<RotatingProductBanner> createState() => _RotatingProductBannerState();
}

class _RotatingProductBannerState extends State<RotatingProductBanner>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _index = 0;
  bool _foreground = true;
  bool _reduceMotion = false;

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

  @override
  void didUpdateWidget(covariant RotatingProductBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.imageKeys.elementAtOrNull(_index);
    final nextIndex = previous == null
        ? -1
        : widget.imageKeys.indexOf(previous);
    _index = nextIndex < 0 ? 0 : nextIndex;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_foreground || _reduceMotion || widget.imageKeys.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||
          !TickerMode.valuesOf(context).enabled ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      setState(() => _index = (_index + 1) % widget.imageKeys.length);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageKeys.isEmpty) return const SizedBox.shrink();
    return ClipRect(
      child: AnimatedSwitcher(
        duration: Duration(
          milliseconds: _reduceMotion ? 0 : (widget.slide ? 650 : 900),
        ),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        layoutBuilder: (current, previous) => Stack(
          fit: widget.expand ? StackFit.expand : StackFit.loose,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) => widget.slide
            ? _PhotoSlide(animation: animation, child: child)
            : FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.045, end: 1).animate(animation),
                  child: child,
                ),
              ),
        child: SizedBox(
          width: double.infinity,
          height: widget.expand ? double.infinity : null,
          key: ValueKey(widget.imageKeys[_index]),
          child: widget.imageBuilder(context, _index),
        ),
      ),
    );
  }
}

class _PhotoSlide extends StatelessWidget {
  const _PhotoSlide({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (_, child) => FractionalTranslation(
      translation: Offset(
        (animation.status == AnimationStatus.reverse ? -1 : 1) *
            (1 - animation.value),
        0,
      ),
      child: child,
    ),
  );
}
