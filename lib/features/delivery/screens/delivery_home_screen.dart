import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/data/profile_repository.dart';
import '../../../shared/widgets/role_selection_back_button.dart';
import '../widgets/delivery_profile_editor.dart';

import '../../../shared/data/marketplace_repository.dart';

import '../../../shared/models/domain_models.dart' as canonical;

import 'package:flutter/material.dart';

import '../../../routes/route_names.dart';
import '../../auth/services/auth_session.dart';

import '../models/delivery_order.dart';
import '../widgets/delivery_contact_details.dart';

import '../widgets/delivery_widgets.dart';

import '../widgets/delivery_status_widgets.dart';
import '../widgets/delivery_workflow_dialogs.dart';
import '../../../shared/data/delivery_workflow_repository.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  final _orders = MarketplaceBackend.enabled
      ? <DeliveryOrder>[]
      : DeliveryOrder.demoOrders();

  StreamSubscription<List<canonical.Order>>? _subscription;
  StreamSubscription<List<canonical.Order>>? _availableSubscription;
  List<canonical.Order> _assignedOrders = [];
  List<canonical.Order> _availableOrders = [];

  final _advancing = <String>{};
  final _alertIds = <String>{};
  final _demoIssues = <String, List<String>>{};
  bool _receivedOrders = false;
  ProfileRepository? _profiles;
  StreamSubscription<Map<String, dynamic>>? _profileSubscription;
  Map<String, dynamic>? _profile;

  Future<void> _editProfile() async {
    if (_profiles == null || _profile == null) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DeliveryProfileEditor(repository: _profiles!, profile: _profile!),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved.')));
    }
  }

  String get _photoUrl => _profile?['photoUrl'] as String? ?? '';
  String get _email => _profile?['email'] as String? ?? '';
  String get _locationLabel => MarketplaceBackend.enabled
      ? (_riderArea.isEmpty ? 'Add your delivery area' : _riderArea)
      : '$_riderArea \u00b7 \u2605 4.8';

  @override
  void initState() {
    super.initState();

    if (!MarketplaceBackend.enabled) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    _profiles = ProfileRepository();
    _profileSubscription = _profiles!.watch().listen((profile) {
      if (mounted) setState(() => _profile = profile);
    }, onError: _error);

    try {
      final repository = MarketplaceRepository();
      _subscription = repository.orders('courierId').listen((rows) {
        _assignedOrders = rows;
        _refreshOrders();
      }, onError: _error);
      _availableSubscription = repository.availableDeliveries().listen((rows) {
        _availableOrders = rows;
        _refreshOrders();
      }, onError: _error);
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _error(e));
    }
  }

  void _refreshOrders() {
    final rows = <String, canonical.Order>{
      for (final row in _availableOrders) row.id: row,
      for (final row in _assignedOrders) row.id: row,
    }.values.toList();
    if (!mounted) return;

    final incoming = rows
        .where(
          (row) =>
              (row.status == canonical.OrderStatus.courierAssigned ||
                  row.status == canonical.OrderStatus.confirmed) &&
              !_orders.any((old) => old.id == row.id),
        )
        .toList();
    if (_receivedOrders && _notifications && incoming.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${incoming.length} new delivery request(s)'),
          action: SnackBarAction(label: 'View', onPressed: _showNotifications),
        ),
      );
    }
    _receivedOrders = true;

    setState(() {
      _alertIds.addAll(incoming.map((row) => row.id));
      _alertIds.removeWhere(
        (id) => !rows.any(
          (row) =>
              row.id == id &&
              (row.status == canonical.OrderStatus.courierAssigned ||
                  row.status == canonical.OrderStatus.confirmed),
        ),
      );
      final previous = {for (final o in _orders) o.id: o};

      _orders.clear();

      for (final row in rows) {
        if (![
          canonical.OrderStatus.confirmed,
          canonical.OrderStatus.courierAssigned,

          canonical.OrderStatus.pickedUp,

          canonical.OrderStatus.onTheWay,

          canonical.OrderStatus.delivered,
        ].contains(row.status)) {
          continue;
        }

        final status = switch (row.status) {
          canonical.OrderStatus.confirmed => DeliveryStatus.pending,
          canonical.OrderStatus.courierAssigned => DeliveryStatus.accepted,

          canonical.OrderStatus.pickedUp => DeliveryStatus.pickedUp,

          canonical.OrderStatus.onTheWay => DeliveryStatus.onTheWay,

          _ => DeliveryStatus.delivered,
        };

        final order = previous[row.id] ?? DeliveryOrder.fromOrder(row);

        order.syncStatus(status);

        _orders.add(order);
      }
    });
  }

  void _error(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(marketplaceError(e))));
    }
  }

  final _search = TextEditingController();

  final _ordersScroll = ScrollController();

  int _tab = 0;

  String _filter = 'All';

  bool _notifications = true;

  bool _online = true;

  String get _riderName => MarketplaceBackend.enabled
      ? (_profile?['displayName'] as String? ?? 'Your profile')
      : 'Kasun Perera';
  String get _riderArea => MarketplaceBackend.enabled
      ? (_profile?['area'] as String? ?? '')
      : 'Colombo';

  @override
  void dispose() {
    _subscription?.cancel();
    _availableSubscription?.cancel();
    _profileSubscription?.cancel();

    _search.dispose();

    _ordersScroll.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DeliveryFrame(
    appBar: AppBar(
      leading: const RoleSelectionBackButton(),
      title: const Text('Craftisan Delivery'),
    ),

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
                ProfileAvatar(name: _riderName, url: _photoUrl),

                const SizedBox(width: 10),

                Expanded(
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

                  onPressed: _showNotifications,

                  icon: Badge(
                    isLabelVisible: _notificationOrders.isNotEmpty,
                    smallSize: 5,

                    child: const Icon(Icons.notifications_none, size: 22),
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

    subtitle: Text(_locationLabel),

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

  List<DeliveryOrder> get _notificationOrders => _orders
      .where(
        (order) => MarketplaceBackend.enabled
            ? _alertIds.contains(order.id)
            : order.status == DeliveryStatus.pending,
      )
      .toList();

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'New deliveries',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (!MarketplaceBackend.enabled)
              const Text('Sample delivery alerts'),
            if (_notificationOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No new delivery assignments.'),
              ),
            for (final order in _notificationOrders)
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(order.title),
                subtitle: Text(
                  '${order.id}\n${order.pickup} → ${order.destination}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showOrder(order);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _issueHistory(String orderId) => StreamBuilder(
    stream: MarketplaceRepository().db
        .collection('orders')
        .doc(orderId)
        .collection('deliveryIssues')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Text('Unable to load issue reports.');
      return Column(
        children: [
          for (final report in snapshot.data?.docs ?? [])
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: Text(report.data()['reason'] as String),
              subtitle: Text(report.data()['notes'] as String),
            ),
        ],
      );
    },
  );

  void _showOrder(DeliveryOrder order) {
    setState(() => _alertIds.remove(order.id));
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
                  '${order.id} / ${order.service}${MarketplaceBackend.enabled ? '' : ' / Demo'}',

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

                  subtitle: SelectableText(
                    order.pickup.isEmpty
                        ? 'Pickup address not provided'
                        : order.pickup,
                  ),
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,

                  leading: const Icon(
                    Icons.location_on_outlined,

                    color: DeliveryStyle.orange,
                  ),

                  title: const Text('Drop-off'),

                  subtitle: SelectableText(order.destination),
                ),

                DeliveryContactDetails(order: order),

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

                    onPressed: () async {
                      if (!_advancing.add(order.id)) return;
                      try {
                        String? code;
                        if (order.status == DeliveryStatus.onTheWay) {
                          code = await requestDeliveryCode(
                            sheetContext,
                            demo: !MarketplaceBackend.enabled,
                          );
                          if (code == null ||
                              !sheetContext.mounted ||
                              !mounted) {
                            return;
                          }
                        }
                        if (MarketplaceBackend.enabled) {
                          final next =
                              DeliveryStatus.values[order.status.index + 1];
                          final repository = MarketplaceRepository();
                          if (order.status == DeliveryStatus.pending) {
                            await repository.acceptDelivery(order.id);
                          } else {
                            await repository.advanceOrder(
                              order.id,
                              confirmationCode: code,
                            );
                          }
                          if (!mounted) return;
                          setState(() => order.syncStatus(next));
                          if (sheetContext.mounted) updateSheet(() {});

                          return;
                        }

                        if (!mounted || !sheetContext.mounted) return;
                        setState(order.advance);

                        updateSheet(() {});
                      } catch (e) {
                        if (e is FirebaseException &&
                            e.code == 'permission-denied' &&
                            order.status == DeliveryStatus.onTheWay) {
                          _error(
                            const MarketplaceFailure(
                              'Delivery could not be confirmed. Check the customer’s code and your assignment, then try again.',
                            ),
                          );
                        } else {
                          _error(e);
                        }
                      } finally {
                        _advancing.remove(order.id);
                      }
                    },
                  )
                else
                  Text(
                    MarketplaceBackend.enabled
                        ? 'Delivery completed.'
                        : 'Delivery completed in this demo.',

                    textAlign: TextAlign.center,
                  ),

                if (!order.delivered)
                  TextButton.icon(
                    icon: const Icon(Icons.report_problem_outlined),
                    label: const Text('Report delivery issue'),
                    onPressed: () async {
                      final saved = await reportDeliveryIssue(
                        sheetContext,
                        demo: !MarketplaceBackend.enabled,
                        save: (reason, notes) async {
                          if (MarketplaceBackend.enabled) {
                            await DeliveryWorkflowRepository(
                              MarketplaceRepository(),
                            ).reportIssue(order.id, reason, notes);
                          } else {
                            (_demoIssues[order.id] ??= []).add(
                              '$reason${notes.isEmpty ? '' : ': $notes'}',
                            );
                          }
                        },
                      );
                      if (saved == true && mounted && sheetContext.mounted) {
                        updateSheet(() {});
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Delivery issue reported.'),
                          ),
                        );
                      }
                    },
                  ),
                if (MarketplaceBackend.enabled)
                  _issueHistory(order.id)
                else
                  for (final issue in _demoIssues[order.id] ?? <String>[])
                    ListTile(
                      leading: const Icon(Icons.report_outlined),
                      title: Text(issue),
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

      Center(
        child: ProfileAvatar(name: _riderName, url: _photoUrl, radius: 35),
      ),

      const SizedBox(height: 12),

      Text(
        _riderName,

        textAlign: TextAlign.center,

        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),

      Text(
        _locationLabel,

        textAlign: TextAlign.center,

        style: TextStyle(color: DeliveryStyle.muted),
      ),

      const SizedBox(height: 12),

      if (_email.isNotEmpty) Text(_email, textAlign: TextAlign.center),
      if (_profiles != null)
        TextButton.icon(
          onPressed: _profile == null ? null : _editProfile,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit profile / photo'),
        ),
      _availability(),

      const SizedBox(height: 24),

      SwitchListTile(
        contentPadding: EdgeInsets.zero,

        title: const Text('Notifications'),

        subtitle: const Text('New delivery alerts while this page is open'),

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

        onTap: () => Navigator.pushNamedAndRemoveUntil(
          context,

          RouteNames.roleSelection,

          (_) => false,
        ),
      ),

      const SizedBox(height: 24),

      DeliveryButton(
        label: MarketplaceBackend.enabled ? 'Log Out' : 'Sign in to delivery',

        onPressed: () {
          if (MarketplaceBackend.enabled) {
            AuthSession.logout(context);
          } else {
            Navigator.pushReplacementNamed(context, RouteNames.deliveryLogin);
          }
        },
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
