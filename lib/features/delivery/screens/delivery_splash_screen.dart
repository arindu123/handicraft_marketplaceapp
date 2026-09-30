import 'dart:async';

import 'package:flutter/material.dart';

import '../../../routes/route_names.dart';
import '../../auth/models/marketplace_role.dart';
import '../widgets/delivery_widgets.dart';

class DeliverySplashScreen extends StatefulWidget {
  const DeliverySplashScreen({super.key});
  @override
  State<DeliverySplashScreen> createState() => _DeliverySplashScreenState();
}

class _DeliverySplashScreenState extends State<DeliverySplashScreen> {
  Timer? _timer;
  bool _opened = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), _open);
  }

  void _open() {
    if (!mounted || _opened || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _opened = true;
    _timer?.cancel();
    final entry = ModalRoute.of(context)?.settings.arguments;
    Navigator.pushReplacementNamed(
      context,
      RouteNames.deliveryLogin,
      arguments: entry == AuthEntry.signIn
          ? AuthEntry.signIn
          : AuthEntry.signUp,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DeliveryFrame(
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  '${DeliveryStyle.assets}delivery_scooter.png',
                  height: (constraints.maxHeight * 0.43).clamp(170.0, 350.0),
                  fit: BoxFit.contain,
                  semanticLabel: 'Courier on an orange delivery scooter',
                ),
                const SizedBox(height: 14),
                const ParcelWordmark(size: 35),
                const SizedBox(height: 12),
                const Text(
                  'Send, track and deliver anything\naround your city — in a few taps.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DeliveryStyle.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _open,
                  child: const Text(
                    'Get started',
                    style: TextStyle(color: DeliveryStyle.orange),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'CRAFTISAN DELIVERY',
                  style: TextStyle(
                    fontSize: 10,
                    color: DeliveryStyle.muted,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
