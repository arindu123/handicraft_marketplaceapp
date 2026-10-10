import 'package:flutter/material.dart';

import '../../../shared/data/marketplace_repository.dart';
import '../models/admin_demo_store.dart';
import 'admin_widgets.dart';

class AdminCourierAssignment extends StatefulWidget {
  const AdminCourierAssignment({
    super.key,
    required this.store,
    required this.order,
  });
  final AdminDemoStore store;
  final AdminOrder order;
  @override
  State<AdminCourierAssignment> createState() => _AdminCourierAssignmentState();
}

class _AdminCourierAssignmentState extends State<AdminCourierAssignment> {
  String? _selected;
  bool _saving = false;
  Future<void> _assign(AdminOrder order) async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.store.operations.assignCourier(
        order.id,
        _selected!,
        expectedStatus: order.status,
        expectedCourierId: order.courierId,
      );
      if (mounted) {
        setState(() => _selected = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Courier assignment saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(marketplaceError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final orders = widget.store.orders.where(
        (order) => order.id == widget.order.id,
      );
      final order = orders.isEmpty ? widget.order : orders.first;
      final couriers = widget.store.couriers
          .where((courier) => courier.active && courier.id.isNotEmpty)
          .toList();
      final selected = couriers.any((courier) => courier.id == _selected)
          ? _selected
          : null;
      final current = widget.store.couriers.where(
        (courier) => courier.id == order.courierId,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Courier assignment',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AdminStyle.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.courierId == null
                ? 'No courier assigned.'
                : 'Current courier: ${current.isEmpty ? order.courierId : current.first.name}',
          ),
          const SizedBox(height: 8),
          if (!order.canAssignCourier)
            const Text(
              'Assignment is available after packing and before pickup.',
              style: TextStyle(color: AdminStyle.muted),
            )
          else if (couriers.isEmpty)
            const Text(
              'No active courier accounts available.',
              style: TextStyle(color: AdminStyle.muted),
            )
          else ...[
            DropdownButton<String>(
              isExpanded: true,
              value: selected,
              hint: const Text('Choose courier'),
              items: couriers
                  .map(
                    (courier) => DropdownMenuItem(
                      value: courier.id,
                      child: Text(
                        courier.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _selected = value),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AdminStyle.clay),
              onPressed:
                  !_saving && selected != null && selected != order.courierId
                  ? () => _assign(order)
                  : null,
              child: Text(
                _saving
                    ? 'Saving…'
                    : order.courierId == null
                    ? 'Assign courier'
                    : 'Reassign courier',
              ),
            ),
          ],
        ],
      );
    },
  );
}
