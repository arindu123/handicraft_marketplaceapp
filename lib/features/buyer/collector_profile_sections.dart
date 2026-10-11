import 'dart:async';

import 'package:flutter/material.dart';

const collectorTeal = Color(0xFF0B4545);
const collectorClay = Color(0xFFB44A2C);

class CollectorAction {
  const CollectorAction(
    this.label,
    this.icon,
    this.onTap, {
    this.color = collectorClay,
    this.showProgress = false,
  });
  final String label;
  final IconData icon;
  final FutureOr<void> Function() onTap;
  final Color color;
  final bool showProgress;
}

class CollectorCard extends StatelessWidget {
  const CollectorCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Color(0xFFF0EAE3)),
    ),
    child: child,
  );
}

class CollectorStatistics extends StatelessWidget {
  const CollectorStatistics({
    super.key,
    required this.saved,
    required this.bag,
    required this.orders,
    required this.actions,
    this.bagLoading = false,
  });
  final int saved, bag, orders;
  final bool bagLoading;
  final List<CollectorAction> actions;
  @override
  Widget build(BuildContext context) => CollectorCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: InkWell(
                onTap: actions[i].onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Column(
                    children: [
                      _ActionIcon(actions[i], size: 42),
                      const SizedBox(height: 8),
                      if (i == 1 && bagLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'Loading bag count',
                          ),
                        )
                      else
                        Text(
                          '${[saved, bag, orders][i]}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: collectorTeal,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        ['Saved Pieces', 'In My Bag', 'Orders'][i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFF676760),
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

class CollectorQuickActions extends StatelessWidget {
  const CollectorQuickActions({super.key, required this.actions});
  final List<CollectorAction> actions;
  @override
  Widget build(BuildContext context) => CollectorCard(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(14) > 20
            ? 2
            : 4;
        return Wrap(
          children: [
            for (final action in actions)
              SizedBox(
                width: constraints.maxWidth / columns,
                child: InkWell(
                  onTap: action.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    child: Column(
                      children: [
                        _ActionIcon(action, size: 52),
                        const SizedBox(height: 10),
                        Text(
                          action.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class CollectorSettings extends StatefulWidget {
  const CollectorSettings({super.key, required this.actions});
  final List<CollectorAction> actions;
  @override
  State<CollectorSettings> createState() => _CollectorSettingsState();
}

class _CollectorSettingsState extends State<CollectorSettings> {
  int? _busy;
  Future<void> _open(int index) async {
    if (_busy != null) return;
    setState(() => _busy = index);
    try {
      await widget.actions[index].onTap();
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => CollectorCard(
    child: Column(
      children: [
        for (var i = 0; i < widget.actions.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.only(left: 64, right: 20),
              child: Divider(height: 1, color: Color(0xFFF0EAE3)),
            ),
          ListTile(
            minVerticalPadding: 16,
            leading: Icon(
              widget.actions[i].icon,
              color: widget.actions[i].color,
            ),
            title: Text(
              widget.actions[i].label,
              style: const TextStyle(fontSize: 14),
            ),
            trailing: _busy == i && widget.actions[i].showProgress
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Opening account action',
                    ),
                  )
                : const Icon(Icons.chevron_right, color: Color(0xFF676760)),
            onTap: _busy == null ? () => _open(i) : null,
          ),
        ],
      ],
    ),
  );
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon(this.action, {required this.size});
  final CollectorAction action;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: action.color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(size * .35),
    ),
    child: Icon(action.icon, color: action.color, size: 24),
  );
}
