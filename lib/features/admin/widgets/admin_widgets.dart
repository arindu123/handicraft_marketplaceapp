import 'package:artisan_marketplace/shared/widgets/craftisan_dialog.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AdminStyle {
  static const navy = AppColors.ink;
  static const cream = AppColors.background;
  static const clay = AppColors.terracotta;
  static const sage = AppColors.sage;
  static const amber = Color(0xFFAB7B29);
  static const muted = AppColors.muted;
  static const border = Color(0xFFECE6DE);

  static ThemeData theme(BuildContext context) => Theme.of(context).copyWith(
    colorScheme: Theme.of(context).colorScheme.copyWith(
      primary: clay,
      onPrimary: Colors.white,
      surface: cream,
      onSurface: navy,
      secondary: sage,
    ),
    dividerColor: border,
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: AppColors.heroCream,
      backgroundColor: Colors.white,
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: clay)),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: navy, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: clay,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AdminStyle.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0870452F),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

/// Decorative marketplace photography, separate from live product records.
class AdminPhotoBanner extends StatelessWidget {
  const AdminPhotoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.action,
    this.photo,
    this.overlayText = false,
  });
  final String title, subtitle, imagePath;
  final Widget? action;
  final Widget? photo;
  final bool overlayText;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AdminStyle.border),
    ),
    child: overlayText
        ? _photoOverlay()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              photo ??
                  ExcludeSemantics(
                    child: Image.asset(
                      imagePath,
                      height: 144,
                      fit: BoxFit.cover,
                      alignment: imagePath.endsWith('artisans.png')
                          ? Alignment.topCenter
                          : const Alignment(0, 0.2),
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CRAFTISAN GUILD',
                      style: TextStyle(
                        color: AdminStyle.clay,
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: AdminStyle.navy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AdminStyle.muted,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 16),
                      action!,
                    ],
                  ],
                ),
              ),
            ],
          ),
  );

  Widget _photoOverlay() => Stack(
    children: [
      Positioned.fill(
        child: ExcludeSemantics(
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
      ),
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x10493B30), Color(0xED29231F)],
              stops: [0, 0.85],
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 88, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CRAFTISAN GUILD',
              style: TextStyle(
                color: Color(0xFFF2D3AA),
                fontSize: 10,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFFFFF4E9),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    ],
  );
}

class AdminWorkspaceHeader extends StatelessWidget {
  const AdminWorkspaceHeader({
    super.key,
    required this.subtitle,
    this.imagePath = 'lib/features/auth/widgets/pottery_mug.png',
  });
  final String subtitle, imagePath;

  @override
  Widget build(BuildContext context) => AdminPanel(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ExcludeSemantics(
            child: Image.asset(
              imagePath,
              width: 72,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ADMIN WORKSPACE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.3,
                  color: AdminStyle.clay,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AdminStyle.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class AdminStatus extends StatelessWidget {
  const AdminStatus(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Approved' || 'Delivered' || 'Active' || 'Resolved' => AdminStyle.sage,
      'Rejected' || 'Paused' => AdminStyle.clay,
      'Shipped' => AdminStyle.navy,
      _ => AdminStyle.amber,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class AdminSectionHeading extends StatelessWidget {
  const AdminSectionHeading(
    this.title, {
    super.key,
    this.action,
    this.onPressed,
  });
  final String title;
  final String? action;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AdminStyle.navy,
          ),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onPressed,
          child: Text(
            action!,
            style: const TextStyle(fontSize: 12, color: AdminStyle.clay),
          ),
        ),
    ],
  );
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: [
        const Icon(Icons.task_alt, size: 34, color: AdminStyle.sage),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AdminStyle.muted, height: 1.5),
        ),
      ],
    ),
  );
}

class AdminSalesChart extends StatelessWidget {
  const AdminSalesChart({
    super.key,
    required this.values,
    required this.labels,
  });
  final List<int> values;
  final List<String> labels;
  @override
  Widget build(BuildContext context) {
    final max = values.reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          values.length,
          (index) => Expanded(
            child: Semantics(
              label: '${labels[index]}: ${values[index]} rupees',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: max == 0 ? 0 : values[index] / max,
                          child: Container(
                            width: 25,
                            decoration: BoxDecoration(
                              color: index == values.length - 1
                                  ? AdminStyle.clay
                                  : const Color(0xFFECD7CB),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AdminStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmAdminAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => CraftisanDialog(
        icon: Icons.fact_check_outlined,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AdminStyle.clay),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;
