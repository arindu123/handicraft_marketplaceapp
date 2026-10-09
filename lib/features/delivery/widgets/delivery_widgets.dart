import 'package:flutter/material.dart';

class DeliveryStyle {
  // Match the buyer marketplace's button and navigation accent.
  static const orange = Color(0xFF9A4023);
  static const ink = Color(0xFF252321);
  static const muted = Color(0xFF8C8782);
  static const surface = Color(0xFFF5F5F5);
  static const peach = Color(0xFFF3E7DD);
  static const heroCream = Color(0xFFF2E3D5);
  static const assets = 'lib/features/delivery/widgets/';
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: orange,
      primary: orange,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: orange),
      ),
      errorMaxLines: 3,
    ),
  );
}

class DeliveryFrame extends StatelessWidget {
  const DeliveryFrame({
    super.key,
    required this.child,
    this.bottomBar,
    this.appBar,
  });
  final Widget child;
  final Widget? bottomBar;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) => Theme(
    data: DeliveryStyle.theme,
    child: Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: bottomBar,
    ),
  );
}

class DeliveryButton extends StatelessWidget {
  const DeliveryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: DeliveryStyle.orange,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
      ],
    ),
  );
}

class ParcelWordmark extends StatelessWidget {
  const ParcelWordmark({super.key, this.size = 23});
  final double size;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.delivery_dining, color: DeliveryStyle.orange, size: size + 4),
      const SizedBox(width: 7),
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'Par',
              style: TextStyle(color: DeliveryStyle.ink),
            ),
            const TextSpan(
              text: 'cel',
              style: TextStyle(color: DeliveryStyle.orange),
            ),
          ],
        ),
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
    ],
  );
}

Future<void> showDeliveryNotice(
  BuildContext context,
  String title,
  String message,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Got it'),
      ),
    ],
  ),
);
