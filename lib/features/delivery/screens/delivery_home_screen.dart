import 'package:flutter/material.dart';

import '../../../routes/route_names.dart';
import '../models/delivery_order.dart';
import '../widgets/delivery_widgets.dart';
import '../widgets/delivery_status_widgets.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});
  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  final _orders = DeliveryOrder.demoOrders();
  final _search = TextEditingController();
  final _ordersScroll = ScrollController();
  int _tab = 0;
  String _filter = 'All';
  bool _notifications = true;
  bool _online = true;
  // Display profile until delivery accounts are connected.
  static const _riderName = 'Kasun Perera';
  static const _riderArea = 'Colombo';
  @override
  void dispose() {
    _search.dispose();
    _ordersScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DeliveryFrame(
    bottomBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (value) => setState(() => _tab = value),
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFFFEEE3),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: DeliveryStyle.orange),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long, color: DeliveryStyle.orange),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(
            Icons.account_balance_wallet,
            color: DeliveryStyle.orange,
          ),
          label: 'Earnings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: DeliveryStyle.orange),
          label: 'Profile',
        ),
      ],
    ),
    child: IndexedStack(
      index: _tab,
      children: [_home(), _orderList(), _wallet(), _account()],
    ),
  );

  Widget _home() {
    final query = _search.text.trim().toLowerCase();
    final orders = _orders
        .where((order) => order.id.toLowerCase().contains(query))
        .toList();
    final waiting = _orders
        .where((order) => order.status == DeliveryStatus.pending)
        .length;
    return SingleChildScrollView(
      key: const PageStorageKey('delivery-home'),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [Color(0xFFFFE1C8), Colors.white],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text('KP', style: TextStyle(color: DeliveryStyle.ink)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 11,
                          color: DeliveryStyle.muted,
                        ),
                      ),
                      Text(
                        _riderName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Notifications',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                  ),
                  onPressed: () => showDeliveryNotice(
                    context,
                    'Notifications',
                    'You are viewing sample deliveries. There are no live notifications yet.',
                  ),
                  icon: const Badge(
                    smallSize: 5,
                    child: Icon(Icons.notifications_none, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _availability(),
            const SizedBox(height: 18),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search order ID',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: DeliveryStyle.muted,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close, size: 18),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                image: const DecorationImage(
                  image: AssetImage('${DeliveryStyle.assets}moving_truck.png'),
                  fit: BoxFit.cover,
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'DELIVERIES TODAY',
                            style: TextStyle(
                              fontSize: 9,
                              color: DeliveryStyle.orange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          '$waiting ${waiting == 1 ? 'delivery' : 'deliveries'}\nwaiting today',
                          style: TextStyle(
                            fontSize: 23,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: DeliveryStyle.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Accept an order and\nstart your delivery.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF70665E),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => setState(() {
                            _tab = 1;
                            _filter = 'Active';
                          }),
                          style: FilledButton.styleFrom(
                            backgroundColor: DeliveryStyle.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                          ),
                          child: const Text(
                            'View orders',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 4),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _balanceCard(),
            const SizedBox(height: 20),
            const Text(
              "Today's orders",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No orders found for this ID.'),
              ),
            for (final order in orders) _orderCard(order),
          ],
        ),
      ),
    );
  }

  Widget _availability() => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(_online ? 'Online' : 'Offline'),
    subtitle: const Text('$_riderArea \u00b7 \u2605 4.8'),
    value: _online,
    activeThumbColor: DeliveryStyle.orange,
    onChanged: (value) => setState(() => _online = value),
  );

  double get _earned => _orders
      .where((order) => order.delivered)
      .fold(0.0, (total, order) => total + order.earnings);

  Widget _balanceCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F3F5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Earnings',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _MoneyStat(
              label: 'Today',
              amount: 'Rs. ${_earned.toStringAsFixed(2)}',
              icon: Icons.today,
              color: const Color(0xFF65A887),
            ),
            _MoneyStat(
              label: 'This week',
              amount: 'Rs. ${_earned.toStringAsFixed(2)}',
              icon: Icons.date_range,
              color: DeliveryStyle.orange,
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => showDeliveryNotice(
            context,
            'Cash out unavailable',
            'Payouts are not connected yet. No cash out has been made.',
          ),
          icon: const Icon(Icons.account_balance_outlined),
          label: const Text('Cash out'),
        ),
      ],
    ),
  );

  Widget _orderCard(DeliveryOrder order) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: DeliveryStyle.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showOrder(order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                order.id,
                style: const TextStyle(
                  fontSize: 11,
                  color: DeliveryStyle.muted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.pickup} \u2192 ${order.destination}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DeliveryStatusPill(status: order.status),
                  Text(
                    'Earn Rs. ${order.earnings.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _orderList() {
    final filtered = _orders
        .where(
          (order) =>
              _filter == 'All' ||
              (_filter == 'Completed' ? order.delivered : !order.delivered),
        )
        .toList();
    return ListView(
      key: const PageStorageKey('delivery-orders'),
      controller: _ordersScroll,
      padding: const EdgeInsets.all(20),
      children: [
        _heading('My Orders', 'Sample deliveries for your courier workspace.'),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          children: ['All', 'Active', 'Completed']
              .map(
                (filter) => ChoiceChip(
                  label: Text(filter),
                  selected: _filter == filter,
                  onSelected: (_) {
                    setState(() => _filter = filter);
                    _ordersScroll.jumpTo(0);
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No deliveries in this view.'),
          ),
        for (final order in filtered) _orderCard(order),
      ],
    );
  }

  void _showOrder(DeliveryOrder order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  order.title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${order.id} · ${order.service} · Demo',
                  style: const TextStyle(color: DeliveryStyle.muted),
                ),
                const SizedBox(height: 22),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.trip_origin,
                    color: DeliveryStyle.orange,
                  ),
                  title: const Text('Pickup'),
                  subtitle: Text(order.pickup),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: DeliveryStyle.orange,
                  ),
                  title: const Text('Drop-off'),
                  subtitle: Text(order.destination),
                ),
                const SizedBox(height: 12),
                const Text(
                  'FRAGILE · Keep upright · Handle with care',
                  style: TextStyle(fontSize: 12, color: DeliveryStyle.orange),
                ),
                const SizedBox(height: 20),
                DeliveryStatusPill(status: order.status),
                if (order.status != DeliveryStatus.pending) ...[
                  const SizedBox(height: 16),
                  DeliveryStatusTracker(status: order.status),
                ],
                const SizedBox(height: 16),
                if (!order.delivered)
                  DeliveryButton(
                    label: order.status.action!,
                    onPressed: () {
                      setState(order.advance);
                      updateSheet(() {});
                    },
                  )
                else
                  const Text(
                    'Delivery completed in this demo.',
                    textAlign: TextAlign.center,
                  ),
                if (order.status != DeliveryStatus.pending)
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Back to My Orders'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wallet() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _heading('My Earnings', 'Your completed delivery earnings.'),
      const SizedBox(height: 20),
      _balanceCard(),
      const SizedBox(height: 24),
      const Text(
        'Recent activity',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      for (final order in _orders.where((order) => order.delivered))
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.receipt_long_outlined,
            color: DeliveryStyle.orange,
          ),
          title: Text(order.title, style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            '${order.id} \u00b7 Rs. ${order.earnings.toStringAsFixed(2)}',
          ),
        ),
    ],
  );

  Widget _account() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _heading('Profile', 'Your Craftisan delivery workspace.'),
      const SizedBox(height: 24),
      const CircleAvatar(
        radius: 35,
        backgroundColor: DeliveryStyle.peach,
        child: Text(
          'KP',
          style: TextStyle(fontSize: 28, color: DeliveryStyle.orange),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        _riderName,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const Text(
        '$_riderArea \u00b7 \u2605 4.8',
        textAlign: TextAlign.center,
        style: TextStyle(color: DeliveryStyle.muted),
      ),
      const SizedBox(height: 12),
      _availability(),
      const SizedBox(height: 24),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Notifications'),
        subtitle: const Text('For this preview session only'),
        value: _notifications,
        onChanged: (value) => setState(() => _notifications = value),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.help_outline),
        title: const Text('Handling guide'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showDeliveryNotice(
          context,
          'Care for every creation',
          'Keep ceramics upright. Check protective packaging before pickup, secure parcels during transit, and inspect the package with the recipient.',
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.swap_horiz),
        title: const Text('Back to role selection'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.popUntil(
          context,
          (route) =>
              route.settings.name == RouteNames.roleSelection || route.isFirst,
        ),
      ),
      const SizedBox(height: 24),
      DeliveryButton(
        label: 'Sign in to delivery',
        onPressed: () =>
            Navigator.pushReplacementNamed(context, RouteNames.deliveryLogin),
      ),
    ],
  );

  Widget _heading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: DeliveryStyle.ink,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: DeliveryStyle.muted,
          height: 1.5,
        ),
      ),
    ],
  );
}

class _MoneyStat extends StatelessWidget {
  const _MoneyStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: DeliveryStyle.muted),
          ),
          Text(
            amount,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ],
  );
}
