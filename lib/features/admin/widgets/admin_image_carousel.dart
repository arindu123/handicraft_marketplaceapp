import 'dart:async';

import 'package:flutter/material.dart';

import 'admin_widgets.dart';

class AdminImageCarousel extends StatefulWidget {
  const AdminImageCarousel({super.key, required this.active});
  final bool active;

  static const images = [
    (
      'assets/images/admin/craft_collection.png',
      'Handmade ceramics and woven crafts',
    ),
    (
      'assets/images/admin/pottery_studio.png',
      'An artisan shaping a clay bowl',
    ),
    (
      'assets/images/admin/parcel_packing.png',
      'Carefully packing a handmade ceramic order',
    ),
  ];

  @override
  State<AdminImageCarousel> createState() => _AdminImageCarouselState();
}

class _AdminImageCarouselState extends State<AdminImageCarousel>
    with WidgetsBindingObserver {
  final _pages = PageController();
  Timer? _timer;
  int _index = 0;
  int _direction = 1;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant AdminImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!widget.active || !_resumed || MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    _timer = Timer(const Duration(seconds: 4), () async {
      if (!mounted) return;
      if (_pages.hasClients && (ModalRoute.of(context)?.isCurrent ?? true)) {
        if (_index == AdminImageCarousel.images.length - 1) _direction = -1;
        if (_index == 0) _direction = 1;
        await _pages.animateToPage(
          _index + _direction,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
      if (mounted) _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 144,
    child: Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              _timer?.cancel();
            } else if (notification is ScrollEndNotification) {
              _schedule();
            }
            return false;
          },
          child: PageView.builder(
            controller: _pages,
            itemCount: AdminImageCarousel.images.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => Image.asset(
              AdminImageCarousel.images[index].$1,
              fit: BoxFit.cover,
              semanticLabel: AdminImageCarousel.images[index].$2,
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 14,
          child: IgnorePointer(
            child: Semantics(
              label:
                  'Marketplace picture ${_index + 1} of ${AdminImageCarousel.images.length}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    AdminImageCarousel.images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: index == _index ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == _index
                            ? AdminStyle.clay
                            : AdminStyle.clay.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
