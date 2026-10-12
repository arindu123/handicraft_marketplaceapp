import 'package:flutter/material.dart';

import '../../shared/models/domain_models.dart';
import 'artisan_dashboard_widgets.dart';
import 'artisan_demo.dart';

String studioOrderStatus(OrderStatus status) => switch (status) {
  OrderStatus.pending => 'Pending',
  OrderStatus.confirmed => 'Ready for Dispatch',
  OrderStatus.courierAssigned => 'Courier Assigned',
  OrderStatus.pickedUp || OrderStatus.onTheWay => 'On the Way',
  OrderStatus.delivered => 'Delivered',
  OrderStatus.cancelled => 'Cancelled',
};

String studioOrderMoney(Order order, num amount) =>
    '${order.currency} ${amount.toStringAsFixed(2)}';

class ArtisanStudioOrders extends StatefulWidget {
  const ArtisanStudioOrders({
    super.key,
    required this.demo,
    required this.onOpen,
    required this.onRetry,
  });
  final ArtisanDemo demo;
  final ValueChanged<String> onOpen;
  final VoidCallback onRetry;
  @override
  State<ArtisanStudioOrders> createState() => _ArtisanStudioOrdersState();
}

class _ArtisanStudioOrdersState extends State<ArtisanStudioOrders> {
  String query = '';
  String status = 'All';
  String sort = 'Newest first';
  static const tabs = [
    'All',
    'Pending',
    'Ready for Dispatch',
    'Courier Assigned',
    'On the Way',
    'Delivered',
    'Cancelled',
  ];

  Future<void> _options() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: studioCream,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sort orders', style: studioHeading(30)),
                for (final value in [
                  'Newest first',
                  'Oldest first',
                  'Highest total',
                  'Lowest total',
                ])
                  ListTile(
                    title: Text(value),
                    trailing: value == sort
                        ? const Icon(Icons.check, color: studioClay)
                        : null,
                    onTap: () => Navigator.pop(context, value),
                  ),
                const Text(
                  'Use the status tabs to filter orders. Totals sort within each currency.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => sort = selected);
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.demo.dashboardOrders;
    final visible = all
        .where(
          (o) =>
              (status == 'All' || studioOrderStatus(o.status) == status) &&
              '${o.id} ${o.recipientName} ${o.buyerId} ${o.items.map((i) => i.productName).join(' ')}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    visible.sort(
      (a, b) => switch (sort) {
        'Oldest first' => a.createdAt.compareTo(b.createdAt),
        'Highest total' =>
          a.currency.compareTo(b.currency) != 0
              ? a.currency.compareTo(b.currency)
              : b.total.compareTo(a.total),
        'Lowest total' =>
          a.currency.compareTo(b.currency) != 0
              ? a.currency.compareTo(b.currency)
              : a.total.compareTo(b.total),
        _ => b.createdAt.compareTo(a.createdAt),
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'STUDIO ORDERS & LOGISTICS',
          style: TextStyle(
            color: studioClay,
            letterSpacing: 2,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "${widget.demo.artisanName}'s Studio Orders",
          style: studioHeading(34),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          children: [
            Text(
              '${all.length} orders',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            FilledButton.tonalIcon(
              onPressed: _options,
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filter'),
              style: FilledButton.styleFrom(
                backgroundColor: studioBlush,
                foregroundColor: studioClay,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (value) =>
              setState(() => query = value.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search orders, customer, product…',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final tab in tabs)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      '$tab (${tab == 'All' ? all.length : all.where((o) => studioOrderStatus(o.status) == tab).length})',
                    ),
                    selected: status == tab,
                    onSelected: (_) => setState(() => status = tab),
                    selectedColor: studioClay,
                    backgroundColor: const Color(0xFFF2EAE4),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: status == tab
                          ? Colors.white
                          : const Color(0xFF5D514B),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: const StadiumBorder(),
                    side: BorderSide.none,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: const ExpansionTile(
            leading: Icon(Icons.inventory_2_outlined, color: studioClay),
            title: Text('Studio Packaging Checklist'),
            childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(
                'Protect with wood-wool wrapping.\nInclude the signed Certificate of Kiln Provenance.\nSeal and label the fragile crate.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.demo.ordersLoading)
          for (var i = 0; i < 2; i++) const _OrderSkeleton()
        else if (widget.demo.ordersError != null)
          _OrderState(
            icon: Icons.cloud_off_outlined,
            message: widget.demo.ordersError!,
            action: TextButton(
              onPressed: widget.onRetry,
              child: const Text('Try Again'),
            ),
          )
        else if (visible.isEmpty)
          _OrderState(
            icon: Icons.receipt_long_outlined,
            message: all.isEmpty
                ? 'No orders yet. Your studio orders will appear here.'
                : 'No orders match your search or status filter.',
          )
        else
          for (final order in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ArtisanStudioOrderCard(
                order: order,
                onOpen: () => widget.onOpen(order.id),
              ),
            ),
      ],
    );
  }
}

class ArtisanStudioOrderCard extends StatelessWidget {
  const ArtisanStudioOrderCard({
    super.key,
    required this.order,
    required this.onOpen,
    this.showAction = true,
  });
  final Order order;
  final VoidCallback onOpen;
  final bool showAction;
  @override
  Widget build(BuildContext context) {
    final colour = switch (order.status) {
      OrderStatus.delivered => const Color(0xFF50704E),
      OrderStatus.cancelled => const Color(0xFF9B4040),
      OrderStatus.confirmed => const Color(0xFF9A570E),
      _ => studioClay,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: studioClay.withValues(alpha: .04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '#${order.id}',
                style: const TextStyle(
                  color: studioClay,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      switch (order.status) {
                        OrderStatus.delivered => Icons.check_circle_outline,
                        OrderStatus.cancelled => Icons.cancel_outlined,
                        OrderStatus.pending => Icons.schedule_outlined,
                        OrderStatus.confirmed => Icons.inventory_2_outlined,
                        _ => Icons.local_shipping_outlined,
                      },
                      size: 18,
                      color: colour,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        studioOrderStatus(order.status),
                        style: TextStyle(
                          color: colour,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${order.createdAt.day} ${_months[order.createdAt.month - 1]} ${order.createdAt.year}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.recipientName.isNotEmpty
                ? order.recipientName
                : 'Buyer ${order.buyerId}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: studioClay,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StudioOrderItem(item: item, order: order),
            ),
          if (showAction)
            OutlinedButton(
              onPressed: onOpen,
              style: OutlinedButton.styleFrom(
                foregroundColor: studioClay,
                side: const BorderSide(color: studioClay),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('View Order Details'),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class StudioOrderItem extends StatelessWidget {
  const StudioOrderItem({super.key, required this.item, required this.order});
  final OrderItem item;
  final Order order;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F0ED),
      borderRadius: BorderRadius.circular(16),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final image = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 68,
            height: 76,
            child: item.imageUrl == null || item.imageUrl!.isEmpty
                ? const Icon(Icons.inventory_2_outlined, color: studioClay)
                : Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: studioClay,
                    ),
                  ),
          ),
        );
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Qty: ${item.quantity} · ${studioOrderMoney(order, item.unitPrice)}',
            ),
            Text(
              'Subtotal: ${studioOrderMoney(order, item.quantity * item.unitPrice)}',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        );
        return constraints.maxWidth < 250 ||
                MediaQuery.textScalerOf(context).scale(16) > 24
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [image, const SizedBox(height: 10), text],
              )
            : Row(
                children: [
                  image,
                  const SizedBox(width: 12),
                  Expanded(child: text),
                ],
              );
      },
    ),
  );
}

class _OrderState extends StatelessWidget {
  const _OrderState({required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Icon(icon, color: studioClay, size: 36),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        ?action,
      ],
    ),
  );
}

class _OrderSkeleton extends StatelessWidget {
  const _OrderSkeleton();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading orders',
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          for (final width in [1.0, .65, .85])
            Container(
              height: 20,
              margin: const EdgeInsets.only(bottom: 16),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: studioBlush,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
