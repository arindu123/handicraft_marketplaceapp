import 'package:flutter/material.dart';

class AdminStyle {
  static const navy = Color(0xFF243447);
  static const cream = Color(0xFFFAF8F5);
  static const clay = Color(0xFFC35D3D);
  static const sage = Color(0xFF527D67);
  static const amber = Color(0xFFAB7B29);
  static const muted = Color(0xFF827E79);
  static const border = Color(0xFFECE6DE);
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AdminStyle.border),
    ),
    child: child,
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
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AdminStyle.navy),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;
