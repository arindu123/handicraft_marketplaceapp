import 'package:flutter/material.dart';

import '../../../routes/route_names.dart';
import '../models/delivery_order.dart';
import '../widgets/delivery_widgets.dart';
import '../widgets/delivery_status_widgets.dart';
import 'delivery_request_screen.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});
  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  final _orders = DeliveryOrder.demoOrders();
  final _search = TextEditingController();
  int _tab = 0;
  String _filter = 'All';
  bool _notifications = true;
  static const _services = [
    (name: 'Ride', icon: Icons.delivery_dining, color: Color(0xFFE8763E)),
    (
      name: 'Transit',
      icon: Icons.directions_bus_rounded,
      color: Color(0xFFCE584C),
    ),
    (name: 'Car', icon: Icons.directions_car_rounded, color: Color(0xFFE6AD39)),
    (
      name: 'Truck',
      icon: Icons.local_shipping_rounded,
      color: Color(0xFFD59749),
    ),
    (name: 'Send', icon: Icons.inventory_2_rounded, color: Color(0xFFCEA254)),
  ];
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _book(String service) async {
    final order = await Navigator.push<DeliveryOrder>(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryRequestScreen(service: service),
      ),
    );
    if (!mounted || order == null) return;
    setState(() {
      _orders.insert(0, order);
      _tab = 1;
      _filter = 'Active';
    });
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
          label: 'Wallet',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: DeliveryStyle.orange),
          label: 'Account',
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
    final services = _services
        .where((service) => service.name.toLowerCase().contains(query))
        .toList();
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
                  child: Icon(Icons.person, color: DeliveryStyle.ink),
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
                        'Guest Courier',
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
            const SizedBox(height: 18),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Find Local Services',
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
                            'MOVE WITH CARE',
                            style: TextStyle(
                              fontSize: 9,
                              color: DeliveryStyle.orange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Moving day,\nmade simple',
                          style: TextStyle(
                            fontSize: 23,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: DeliveryStyle.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A careful ride for every\nhandcrafted piece.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF70665E),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => _book('Truck'),
                          style: FilledButton.styleFrom(
                            backgroundColor: DeliveryStyle.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                          ),
                          child: const Text(
                            'Book now →',
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
              'Services',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (services.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No services found. Try Ride, Transit, Car, Truck or Send.',
                  style: TextStyle(color: DeliveryStyle.muted),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 8,
                runSpacing: 12,
                children: services
                    .map(
                      (service) => SizedBox(
                        width: ((constraints.maxWidth - 32) / 5).clamp(
                          58.0,
                          85.0,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () => _book(service.name),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Column(
                              children: [
                                Container(
                                  height: 57,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: DeliveryStyle.surface,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    service.icon,
                                    size: 33,
                                    color: service.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  service.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'DEMO PREVIEW · Sample balances and deliveries',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: DeliveryStyle.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F3F5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Total Balance',
                style: TextStyle(fontSize: 12, color: DeliveryStyle.muted),
              ),
            ),
            Text(
              'DEMO',
              style: TextStyle(
                fontSize: 10,
                color: DeliveryStyle.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '\$1,280.87 ',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: DeliveryStyle.ink,
                ),
              ),
              TextSpan(
                text: 'USD',
                style: TextStyle(fontSize: 11, color: DeliveryStyle.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _walletAction('Pay', Icons.credit_card)),
            const SizedBox(width: 8),
            Expanded(child: _walletAction('Top Up', Icons.add_box_outlined)),
            const SizedBox(width: 8),
            Expanded(child: _walletAction('More', Icons.more_horiz)),
          ],
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _MoneyStat(
              label: 'Income',
              amount: '\$3,420.00',
              icon: Icons.south_west,
              color: Color(0xFF65A887),
            ),
            _MoneyStat(
              label: 'Spending',
              amount: '\$2,139.13',
              icon: Icons.north_east,
              color: Color(0xFFC77989),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _walletAction(String label, IconData icon) => TextButton(
    style: TextButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: DeliveryStyle.ink,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    onPressed: () {
      if (label == 'More') {
        setState(() => _tab = 2);
        return;
      }
      showDeliveryNotice(
        context,
        '$label unavailable',
        'This is a demo wallet. No funds are held and no payments or top-ups can be made.',
      );
    },
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Icon(icon, size: 16),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
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
                  onSelected: (_) => setState(() => _filter = filter),
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
        for (final order in filtered)
          Padding(
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
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: DeliveryStyle.orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              order.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        order.id,
                        style: const TextStyle(
                          fontSize: 11,
                          color: DeliveryStyle.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.destination,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      DeliveryStatusPill(status: order.status),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
      _heading('My Wallet', 'A preview of your delivery earnings.'),
      const SizedBox(height: 20),
      _balanceCard(),
      const SizedBox(height: 24),
      const Text(
        'Recent activity',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      for (final item in [
        (title: 'Ceramic collection delivery', amount: '+\$24.00'),
        (title: 'Studio pickup', amount: '+\$18.50'),
        (title: 'Packing materials', amount: '-\$8.00'),
      ])
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: DeliveryStyle.surface,
            child: Icon(
              Icons.receipt_long_outlined,
              color: DeliveryStyle.orange,
            ),
          ),
          title: Text(item.title, style: const TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Sample transaction',
            style: TextStyle(fontSize: 11),
          ),
          trailing: Text(
            item.amount,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      const SizedBox(height: 12),
      const Text(
        'Demo only. Balances and transactions are illustrative.',
        style: TextStyle(fontSize: 12, color: DeliveryStyle.muted),
      ),
    ],
  );

  Widget _account() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _heading('Account', 'Your Craftisan delivery workspace.'),
      const SizedBox(height: 24),
      const CircleAvatar(
        radius: 35,
        backgroundColor: DeliveryStyle.peach,
        child: Icon(
          Icons.person_outline,
          size: 40,
          color: DeliveryStyle.orange,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Guest Courier',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Demo profile',
        textAlign: TextAlign.center,
        style: TextStyle(color: DeliveryStyle.muted),
      ),
      const SizedBox(height: 24),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Demo notification preference'),
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
