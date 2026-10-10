import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/data/community_repository.dart';
import '../../shared/data/delivery_workflow_repository.dart';
import '../../shared/data/marketplace_repository.dart';
import '../../shared/models/domain_models.dart' as model;
import 'handicraft_navigation_bar.dart';
import 'buyer_demo.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({
    super.key,
    required this.demo,
    this.onDestinationSelected,
  });
  final BuyerDemo demo;
  final ValueChanged<int>? onDestinationSelected;

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  final _search = TextEditingController();
  String _filter = 'All';
  late final Stream<List<model.Order>> _orders = widget.demo.repository!.orders(
    'buyerId',
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF5F7FA),
      title: const Text(
        'My orders',
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
      ),
      actions: [
        if (widget.demo.repository?.auth.currentUser?.photoURL case final url?)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              child: ClipOval(
                child: Image.network(
                  url,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.person_outline),
                ),
              ),
            ),
          ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: AppColors.terracotta),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Track your handmade finds',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFF566176), fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search your orders',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE2E6EC)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Row(
              children: [
                for (final value in ['All', 'Active', 'Delivered'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _FilterChip(
                        label: value,
                        selected: _filter == value,
                        onTap: () => setState(() => _filter = value),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<model.Order>>(
              stream: _orders,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Orders unavailable',
                    detail: marketplaceError(snapshot.error!),
                    action: TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = _search.text.trim().toLowerCase();
                final all = [...snapshot.data!]
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final orders = all.where((o) {
                  final delivered = o.status == model.OrderStatus.delivered;
                  final matchesFilter =
                      _filter == 'All' ||
                      (_filter == 'Delivered'
                          ? delivered
                          : !delivered &&
                                o.status != model.OrderStatus.cancelled);
                  final matchesQuery =
                      query.isEmpty ||
                      o.id.toLowerCase().contains(query) ||
                      o.items.any(
                        (i) => i.productName.toLowerCase().contains(query),
                      );
                  return matchesFilter && matchesQuery;
                }).toList();
                if (orders.isEmpty) {
                  return _MessageState(
                    icon: Icons.receipt_long_outlined,
                    title: all.isEmpty ? 'No orders yet' : 'No matching orders',
                    detail: all.isEmpty
                        ? 'Orders you place will appear here.'
                        : 'Try another search or filter.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  itemCount: orders.length,
                  itemBuilder: (context, index) =>
                      _OrderCard(order: orders[index], demo: widget.demo),
                );
              },
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: HandicraftNavigationBar(
      selectedIndex: 4,
      onDestinationSelected:
          widget.onDestinationSelected ??
          (index) {
            if (index == 4) Navigator.maybePop(context);
          },
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.demo});
  final model.Order order;
  final BuyerDemo demo;

  @override
  Widget build(BuildContext context) {
    final assigned = order.status == model.OrderStatus.courierAssigned;
    return Card(
      color: assigned ? const Color(0xFFFFF7F1) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: assigned ? const Color(0xFFFFD8C6) : const Color(0xFFE6E9EF),
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _StatusBadge(status: order.status),
                const Spacer(),
                Flexible(
                  child: Text(
                    '#${order.id}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: Color(0xFF687184)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                _ItemPhoto(url: order.items.firstOrNull?.imageUrl, size: 92),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.items.map((e) => e.productName).join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${order.items.fold<int>(0, (quantityTotal, i) => quantityTotal + i.quantity)} item(s) · ${order.paymentMethod}',
                        style: const TextStyle(
                          color: Color(0xFF626E81),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _money(order.total, order.currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _OutlineAction(
                    label: assigned ? 'View assignment' : 'View order',
                    onTap: () => _open(
                      context,
                      assigned
                          ? CourierAssignedScreen(demo: demo, orderId: order.id)
                          : BuyerOrderDetailsScreen(
                              demo: demo,
                              orderId: order.id,
                            ),
                    ),
                  ),
                ),
                if (order.status == model.OrderStatus.delivered) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OutlineAction(
                      label: '★  Leave a review',
                      mint: true,
                      onTap: () => _leaveReview(context, demo, order),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BuyerOrderDetailsScreen extends StatefulWidget {
  const BuyerOrderDetailsScreen({
    super.key,
    required this.demo,
    required this.orderId,
  });
  final BuyerDemo demo;
  final String orderId;

  @override
  State<BuyerOrderDetailsScreen> createState() =>
      _BuyerOrderDetailsScreenState();
}

class _BuyerOrderDetailsScreenState extends State<BuyerOrderDetailsScreen> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _order = widget
      .demo
      .repository!
      .db
      .collection('orders')
      .doc(widget.orderId)
      .snapshots();

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: _order,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _unavailableScaffold(
          'Order unavailable',
          marketplaceError(snapshot.error!),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!snapshot.data!.exists || snapshot.data!.data() == null) {
        return _unavailableScaffold(
          'Order unavailable',
          'This order could not be found.',
        );
      }
      final order = model.Order.fromMap({
        ...snapshot.data!.data()!,
        'id': snapshot.data!.id,
      });
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            'Order details\n#${order.id}',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFF5F7FA),
          toolbarHeight: 76,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            _StatusHero(status: order.status),
            _Card(
              child: Column(
                children: [
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          _ItemPhoto(url: item.imageUrl, size: 82),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Qty ${item.quantity}',
                                  style: const TextStyle(
                                    color: Color(0xFF647087),
                                  ),
                                ),
                                Text(
                                  '${_money(item.unitPrice, order.currency)} each',
                                  style: const TextStyle(
                                    color: Color(0xFF647087),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _money(
                              item.unitPrice * item.quantity,
                              order.currency,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Delivery progress'),
                  for (var i = 0; i < _stages.length; i++)
                    _ProgressStep(
                      status: _stages[i],
                      current: order.status,
                      isLast: i == _stages.length - 1,
                    ),
                ],
              ),
            ),
            if (order.courierId != null)
              _CourierCard(
                repository: widget.demo.repository!,
                courierId: order.courierId!,
              ),
            _Card(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFF0E9),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.terracotta,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Delivering to'),
                        if (order.recipientName.isNotEmpty)
                          Text(
                            order.recipientName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        Text(
                          order.deliveryAddress,
                          style: const TextStyle(
                            height: 1.45,
                            color: Color(0xFF505C70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Cash on delivery',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _money(order.total, order.currency),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (order.status != model.OrderStatus.delivered &&
                      order.status != model.OrderStatus.cancelled) ...[
                    const Divider(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, color: Color(0xFF667286)),
                        SizedBox(width: 9),
                        Text('Delivery code'),
                        Spacer(),
                        Text(
                          '\u2022\u2022\u2022\u2022\u2022\u2022',
                          style: TextStyle(
                            letterSpacing: 3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _revealCode(order),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Show delivery code'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Share only when your parcel is handed to you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF59657A)),
                    ),
                  ],
                ],
              ),
            ),
            if (order.status == model.OrderStatus.delivered)
              OutlinedButton.icon(
                onPressed: () => _leaveReview(context, widget.demo, order),
                icon: const Icon(Icons.star_outline),
                label: const Text('Leave a review'),
              ),
          ],
        ),
      );
    },
  );

  Future<void> _revealCode(model.Order order) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await DeliveryWorkflowRepository(widget.demo.repository!)
          .confirmationCode(order.id);
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delivery confirmation code'),
            content: Text(
              '$code\n\nShare it only when your parcel is handed to you.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(marketplaceError(error))));
    }
  }
}

class CourierAssignedScreen extends StatelessWidget {
  const CourierAssignedScreen({
    super.key,
    required this.demo,
    required this.orderId,
  });
  final BuyerDemo demo;
  final String orderId;

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: demo.repository!.db.collection('orders').doc(orderId).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _unavailableScaffold(
          'Assignment unavailable',
          marketplaceError(snapshot.error!),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final data = snapshot.data!.data();
      if (data == null) {
        return _unavailableScaffold(
          'Assignment unavailable',
          'This order could not be found.',
        );
      }
      final order = model.Order.fromMap({...data, 'id': orderId});
      if (order.status != model.OrderStatus.courierAssigned) {
        return BuyerOrderDetailsScreen(demo: demo, orderId: orderId);
      }
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            'Delivery update\n#$orderId',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFF5F7FA),
          toolbarHeight: 76,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StatusBadge(status: model.OrderStatus.courierAssigned),
                  const SizedBox(height: 16),
                  const Text(
                    'Your courier is assigned',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your courier has accepted the delivery.',
                    style: TextStyle(color: Color(0xFF59657A), fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  const Icon(
                    Icons.delivery_dining,
                    color: AppColors.terracotta,
                    size: 62,
                  ),
                ],
              ),
            ),
            _CourierCard(
              repository: demo.repository!,
              courierId: order.courierId ?? '',
            ),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('What happens next'),
                  const SizedBox(height: 10),
                  const _NextStep(
                    icon: Icons.inventory_2_outlined,
                    title: 'Pickup from the artisan',
                    detail: 'Waiting for your courier to collect the parcel.',
                  ),
                  const SizedBox(height: 14),
                  const _NextStep(
                    icon: Icons.home_outlined,
                    title: 'Delivery to your address',
                    detail: 'You’ll see updates in order tracking.',
                  ),
                ],
              ),
            ),
            _Card(
              child: Column(
                children: [
                  for (final item in order.items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _ItemPhoto(url: item.imageUrl, size: 60),
                      title: Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('Qty ${item.quantity}'),
                      trailing: Text(
                        _money(item.unitPrice * item.quantity, order.currency),
                      ),
                    ),
                  const Divider(),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Cash on delivery',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _money(order.total, order.currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => _open(
                context,
                BuyerOrderDetailsScreen(demo: demo, orderId: orderId),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('View order tracking'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to my orders'),
            ),
          ],
        ),
      );
    },
  );
}

class _CourierCard extends StatelessWidget {
  const _CourierCard({required this.repository, required this.courierId});
  final MarketplaceRepository repository;
  final String courierId;

  @override
  Widget build(BuildContext context) {
    if (courierId.isEmpty) {
      return const _Card(child: Text('Courier details are not available yet.'));
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: repository.db
          .collection('courierPublicProfiles')
          .doc(courierId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _Card(child: Text('Courier details are unavailable.'));
        }
        if (!snapshot.hasData) {
          return const _Card(
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Expanded(child: Text('Loading courier details…')),
              ],
            ),
          );
        }
        final profile = snapshot.data?.data();
        if (profile == null) {
          return const _Card(child: Text('Courier profile is unavailable.'));
        }
        final name = profile['displayName'] as String?;
        final phone = profile['phone'] as String? ?? '';
        final call = _phoneUri(phone);
        return _Card(
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFFFFF0E9),
                child: (profile['photoUrl'] as String?)?.isNotEmpty == true
                    ? ClipOval(
                        child: Image.network(
                          profile['photoUrl'] as String,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.delivery_dining,
                            color: AppColors.terracotta,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.delivery_dining,
                        color: AppColors.terracotta,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name?.trim().isNotEmpty == true
                          ? name!
                          : 'Courier details unavailable',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      profile['area'] as String? ?? 'Assigned courier',
                      style: const TextStyle(color: Color(0xFF626E81)),
                    ),
                  ],
                ),
              ),
              if (call != null)
                OutlinedButton.icon(
                  onPressed: () =>
                      launchUrl(call, mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call'),
                ),
            ],
          ),
        );
      },
    );
  }
}

const _stages = [
  model.OrderStatus.pending,
  model.OrderStatus.confirmed,
  model.OrderStatus.courierAssigned,
  model.OrderStatus.pickedUp,
  model.OrderStatus.onTheWay,
  model.OrderStatus.delivered,
];
const _labels = [
  'Order placed',
  'Artisan confirmed',
  'Courier assigned',
  'Picked up',
  'On the way',
  'Delivered',
];

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.status,
    required this.current,
    required this.isLast,
  });
  final model.OrderStatus status, current;
  final bool isLast;
  @override
  Widget build(BuildContext context) {
    final index = _stages.indexOf(status);
    final canceled = current == model.OrderStatus.cancelled;
    final currentIndex = _stages.indexOf(current);
    final complete =
        !canceled &&
        (index < currentIndex || current == model.OrderStatus.delivered);
    final active = status == current && current != model.OrderStatus.delivered;
    final color = complete
        ? const Color(0xFF07865E)
        : active
        ? AppColors.terracotta
        : const Color(0xFF9AA4B2);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color,
                child: Icon(
                  complete ? Icons.check : _stageIcon(status),
                  size: 16,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 26,
                  color: complete
                      ? const Color(0xFF07865E)
                      : const Color(0xFFD9DEE6),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _labels[index],
                    style: TextStyle(
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? AppColors.terracotta
                          : const Color(0xFF263144),
                    ),
                  ),
                ),
                if (active)
                  const Text(
                    'Current',
                    style: TextStyle(color: AppColors.terracotta, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.status});
  final model.OrderStatus status;
  @override
  Widget build(BuildContext context) => _Card(
    child: Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFFFF0E9),
          child: Icon(_stageIcon(status), color: AppColors.terracotta),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _statusLabel(status),
                style: const TextStyle(
                  color: AppColors.terracotta,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _statusDescription(status),
                style: const TextStyle(color: Color(0xFF59657A)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      backgroundColor: selected ? AppColors.terracotta : Colors.white,
      foregroundColor: selected ? Colors.white : const Color(0xFF3F4A5E),
      side: BorderSide(
        color: selected ? AppColors.terracotta : const Color(0xFFD9DEE6),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Text(label),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final model.OrderStatus status;
  @override
  Widget build(BuildContext context) {
    final delivered = status == model.OrderStatus.delivered;
    final color = delivered
        ? const Color(0xFF07865E)
        : status == model.OrderStatus.pending
        ? const Color(0xFF98600A)
        : AppColors.terracotta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ItemPhoto extends StatelessWidget {
  const _ItemPhoto({required this.url, required this.size});
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: size,
      height: size,
      child: url?.isNotEmpty == true
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          : _placeholder(),
    ),
  );
  Widget _placeholder() => const ColoredBox(
    color: Color(0xFFF0EFED),
    child: Center(child: Icon(Icons.image_outlined, color: Color(0xFF9299A5))),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 7),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE7EAF0)),
      borderRadius: BorderRadius.circular(19),
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
    ),
  );
}

class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title, detail;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        backgroundColor: const Color(0xFFFFF0E9),
        child: Icon(icon, color: AppColors.terracotta),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(detail, style: const TextStyle(color: Color(0xFF69758A))),
          ],
        ),
      ),
    ],
  );
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.label,
    required this.onTap,
    this.mint = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool mint;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: mint ? const Color(0xFF07865E) : AppColors.terracotta,
      side: BorderSide(
        color: mint ? const Color(0xFF07865E) : AppColors.terracotta,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });
  final IconData icon;
  final String title, detail;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF8B95A4)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF69758A)),
          ),
          ?action,
        ],
      ),
    ),
  );
}

Scaffold _unavailableScaffold(String title, String detail) => Scaffold(
  backgroundColor: const Color(0xFFF5F7FA),
  appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFFF5F7FA)),
  body: _MessageState(
    icon: Icons.cloud_off_outlined,
    title: title,
    detail: detail,
  ),
);

void _open(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

Future<void> _leaveReview(
  BuildContext context,
  BuyerDemo demo,
  model.Order order,
) async {
  if (demo.repository == null || order.items.isEmpty) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _ReviewDialog(demo: demo, order: order),
  );
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.demo, required this.order});
  final BuyerDemo demo;
  final model.Order order;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late String _productId = widget.order.items.first.productId;
  final _comment = TextEditingController();
  double _rating = 5;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repository = widget.demo.repository!;
    try {
      await CommunityRepository(
        firestore: repository.db,
        auth: repository.auth,
      ).review(widget.order.id, _productId, _rating, _comment.text);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(marketplaceError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Leave a review'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.order.items.length > 1)
          DropdownButtonFormField<String>(
            initialValue: _productId,
            items: [
              for (final product in widget.order.items)
                DropdownMenuItem(
                  value: product.productId,
                  child: Text(
                    product.productName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _productId = value);
            },
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                onPressed: () => setState(() => _rating = i.toDouble()),
                icon: Icon(
                  i <= _rating ? Icons.star : Icons.star_border,
                  color: const Color(0xFF07865E),
                ),
              ),
          ],
        ),
        TextField(
          controller: _comment,
          maxLength: 2000,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Share your experience'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Submit review')),
    ],
  );
}

String _money(num value, String currency) => currency == 'USD'
    ? '\$${value.toStringAsFixed(2)}'
    : '$currency ${value.toStringAsFixed(2)}';
String _statusLabel(model.OrderStatus status) => switch (status) {
  model.OrderStatus.pending => 'Awaiting confirmation',
  model.OrderStatus.confirmed => 'Artisan confirmed',
  model.OrderStatus.courierAssigned => 'Courier assigned',
  model.OrderStatus.pickedUp => 'Picked up',
  model.OrderStatus.onTheWay => 'On the way',
  model.OrderStatus.delivered => 'Delivered',
  model.OrderStatus.cancelled => 'Cancelled',
};
String _statusDescription(model.OrderStatus status) => switch (status) {
  model.OrderStatus.pending =>
    'Your order is waiting for artisan confirmation.',
  model.OrderStatus.confirmed => 'The artisan has confirmed your order.',
  model.OrderStatus.courierAssigned =>
    'Your courier has accepted the delivery.',
  model.OrderStatus.pickedUp => 'The courier has collected your parcel.',
  model.OrderStatus.onTheWay => 'Your courier is bringing your order.',
  model.OrderStatus.delivered => 'Your order has been delivered.',
  model.OrderStatus.cancelled => 'This order was cancelled.',
};
IconData _stageIcon(model.OrderStatus status) => switch (status) {
  model.OrderStatus.pending => Icons.schedule,
  model.OrderStatus.confirmed => Icons.check,
  model.OrderStatus.courierAssigned => Icons.delivery_dining,
  model.OrderStatus.pickedUp => Icons.inventory_2_outlined,
  model.OrderStatus.onTheWay => Icons.local_shipping_outlined,
  model.OrderStatus.delivered => Icons.home_outlined,
  model.OrderStatus.cancelled => Icons.close,
};
Uri? _phoneUri(String phone) {
  final value = phone.replaceAll(RegExp(r'[\s()-]'), '');
  return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value)
      ? Uri(scheme: 'tel', path: value)
      : null;
}
