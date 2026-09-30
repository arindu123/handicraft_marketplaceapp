import 'dart:async';

import 'package:flutter/material.dart';

import 'delivery_widgets.dart';

/// The account header's three illustrations, sliding back and forth.
class DeliveryBanner extends StatefulWidget {
  const DeliveryBanner({super.key});

  @override
  State<DeliveryBanner> createState() => _DeliveryBannerState();
}

class _DeliveryBannerState extends State<DeliveryBanner>
    with WidgetsBindingObserver {
  final _pages = PageController();
  Timer? _timer;
  int _index = 0;
  int _direction = 1;
  bool _resumed = true;

  static const _images = [
    ('courier_hero.png', 'Delivery courier holding parcels'),
    ('moving_truck.png', 'Courier loading parcels into a delivery truck'),
    ('delivery_scooter.png', 'Orange delivery scooter on its route'),
  ];

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_resumed || MediaQuery.disableAnimationsOf(context)) return;
    _timer = Timer(const Duration(seconds: 4), () async {
      if (!mounted) return;
      if (_pages.hasClients && (ModalRoute.of(context)?.isCurrent ?? true)) {
        if (_index == _images.length - 1) _direction = -1;
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
    height: 215,
    width: double.infinity,
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
            itemCount: _images.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => Image.asset(
              '${DeliveryStyle.assets}${_images[index].$1}',
              fit: BoxFit.cover,
              semanticLabel: _images[index].$2,
            ),
          ),
        ),
        Positioned(
          bottom: 13,
          right: 20,
          child: IgnorePointer(
            child: Semantics(
              label: 'Delivery picture ${_index + 1} of ${_images.length}',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  _images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _index
                          ? DeliveryStyle.orange
                          : Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
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
