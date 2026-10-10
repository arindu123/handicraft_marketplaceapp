import 'package:flutter/material.dart';

import '../../../shared/widgets/role_selection_back_button.dart';

import '../models/admin_demo_store.dart';
import '../widgets/admin_widgets.dart';
import 'admin_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.store});
  final AdminDemoStore? store;
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _MissingProductImage extends StatelessWidget {
  const _MissingProductImage();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AdminStyle.cream,
    child: Center(
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: AdminStyle.muted,
      ),
    ),
  );
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final _store = widget.store ?? AdminDemoStore();
  @override
  void initState() {
    super.initState();
    _store.addListener(_showError);
  }

  void _showError() {
    if (!mounted || _store.error == null) return;
    final error = _store.error!;
    _store.error = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    });
  }

  final _search = TextEditingController();
  int _tab = 0;
  String _approvalFilter = 'Pending', _orderFilter = 'All';
  static const _statuses = ['Pending', 'Processing', 'Shipped', 'Delivered'];

  @override
  void dispose() {
    _search.dispose();
    _store.removeListener(_showError);
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  void _manage(AdminSection section) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => AdminManagementScreen(section: section, store: _store),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) => Scaffold(
      backgroundColor: AdminStyle.cream,
      appBar: AppBar(
        leading: const RoleSelectionBackButton(),
        backgroundColor: AdminStyle.cream,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AdminStyle.navy,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CRAFTISAN',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: AdminStyle.clay,
              ),
            ),
            Text(
              'Control',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Review pending applications',
            onPressed: () => setState(() => _tab = 1),
            icon: Badge(
              label: Text('${_store.pending}'),
              child: const Icon(Icons.notifications_none),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: IndexedStack(
              index: _tab,
              children: [
                _page('overview', _overview()),
                _page('approvals', _approvals()),
                _page('orders', _orders()),
                _page('more', _more()),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFF2DED3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Orders',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    ),
  );

  Widget _page(String key, List<Widget> children) => ListView(
    key: PageStorageKey(key),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: children,
  );
  Widget _space([double height = 18]) => SizedBox(height: height);
  Widget _title(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          fontFamily: 'CormorantGaramond',
          fontWeight: FontWeight.w600,
          color: AdminStyle.navy,
        ),
      ),
      _space(6),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: AdminStyle.muted,
        ),
      ),
      _space(),
    ],
  );
  Widget _filters(
    List<String> values,
    String selected,
    ValueChanged<String> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Wrap(
      spacing: 7,
      runSpacing: 6,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(value),
            selected: selected == value,
            selectedColor: const Color(0xFFF2DED3),
            onSelected: (_) => setState(() => change(value)),
          ),
      ],
    ),
  );

  List<Widget> _overview() => [
    Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminStyle.navy,
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('lib/features/auth/widgets/pottery_vase.png'),
          fit: BoxFit.cover,
          alignment: Alignment(0, 0.3),
          colorFilter: ColorFilter.mode(Color(0xB3243447), BlendMode.srcATop),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GUILD ADMINISTRATION  /  LIVE',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              color: Color(0xFFEAC9AE),
            ),
          ),
          _space(14),
          const Text(
            'Your marketplace,\nat a glance.',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 34,
              height: 1.05,
              color: Colors.white,
            ),
          ),
          _space(12),
          const Text(
            'A little oversight. A thriving creative community.',
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Color(0xFFCFD6DD),
            ),
          ),
          _space(18),
          FilledButton.icon(
            onPressed: () => _manage(AdminSection.products),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF2DED3),
              foregroundColor: AdminStyle.navy,
            ),
            icon: const Icon(Icons.arrow_outward, size: 18),
            label: const Text('Explore catalogue'),
          ),
        ],
      ),
    ),
    _space(),
    LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _metric(
            (constraints.maxWidth - 12) / 2,
            'Total orders',
            '${_store.orders.length}',
            Icons.inventory_2_outlined,
            () => setState(() => _tab = 2),
          ),
          _metric(
            (constraints.maxWidth - 12) / 2,
            'Active artisans',
            '${_store.activeArtisans}',
            Icons.palette_outlined,
            () => _manage(AdminSection.users),
          ),
          _metric(
            (constraints.maxWidth - 12) / 2,
            'Pending approvals',
            '${_store.pending}',
            Icons.verified_outlined,
            () => setState(() => _tab = 1),
          ),
          _metric(
            (constraints.maxWidth - 12) / 2,
            'Order value',
            adminMoney(_store.revenue),
            Icons.account_balance_wallet_outlined,
            () => setState(() => _tab = 2),
          ),
        ],
      ),
    ),
    _space(24),
    AdminSectionHeading(
      'Made by our community',
      action: 'Catalogue',
      onPressed: () => _manage(AdminSection.products),
    ),
    _space(6),
    const Text(
      'A closer look at the craft behind your marketplace.',
      style: TextStyle(fontSize: 12, color: AdminStyle.muted),
    ),
    _space(12),
    LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          if (_store.orders.isEmpty)
            const AdminPanel(child: Text('No orders to showcase yet.')),
          for (final order in _store.orders.take(2))
            SizedBox(
              width: constraints.maxWidth < 340
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2,
              child: _featuredCraft(order),
            ),
        ],
      ),
    ),
    _space(24),
    const AdminSectionHeading('Needs your attention'),
    _space(12),
    AdminPanel(
      child: Column(
        children: [
          if (_store.pending > 0)
            _action(
              Icons.person_add_alt,
              '${_store.pending} applications waiting',
              'Review studio and courier applications',
              () => setState(() => _tab = 1),
            ),
          if (!_store.productReportResolved)
            _action(
              Icons.flag_outlined,
              'Product listing reported',
              'Check listing details',
              () => _manage(AdminSection.reports),
            ),
          if (!_store.deliveryIssueResolved)
            _action(
              Icons.local_shipping_outlined,
              'Delivery delay flagged',
              'Review the reports section',
              () => _manage(AdminSection.reports),
            ),
          if (_store.attentionCount == 0)
            const AdminEmptyState('All caught up. No pending issues.'),
        ],
      ),
    ),
    _space(24),
    const AdminSectionHeading('Sales overview'),
    _space(12),
    _sales(),
    _space(20),
    AdminSectionHeading(
      'Recent orders',
      action: 'View all',
      onPressed: () => setState(() => _tab = 2),
    ),
    _space(8),
    for (final order in _store.orders.take(3)) _orderCard(order),
    const Text(
      'Live marketplace administration · Firestore-backed data',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11, color: AdminStyle.muted),
    ),
  ];

  Widget _featuredCraft(AdminOrder order) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _orderDetails(order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: order.imageUrl?.isNotEmpty == true
                ? Image.network(
                    order.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _MissingProductImage(),
                  )
                : const _MissingProductImage(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.studio.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: AdminStyle.clay,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _space(8),
                Text(
                  order.product,
                  style: const TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                    color: AdminStyle.navy,
                  ),
                ),
                _space(10),
                Text(
                  adminMoney(order.amount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AdminStyle.navy,
                  ),
                ),
                _space(8),
                const Text(
                  'View order →',
                  style: TextStyle(fontSize: 12, color: AdminStyle.clay),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _metric(
    double width,
    String label,
    String value,
    IconData icon,
    VoidCallback action,
  ) => SizedBox(
    width: width,
    child: Semantics(
      button: true,
      child: GestureDetector(
        onTap: action,
        child: AdminPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AdminStyle.clay, size: 22),
              _space(14),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: AdminStyle.navy,
                ),
              ),
              _space(6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AdminStyle.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _action(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AdminStyle.clay, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AdminStyle.navy,
                    ),
                  ),
                  _space(4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AdminStyle.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AdminStyle.muted, size: 20),
          ],
        ),
      ),
    ),
  );

  Widget _sales() {
    final values = [
      _store.orders
          .where((order) => order.status == 'Delivered')
          .fold<int>(0, (sum, order) => sum + order.amount),
    ];
    const labels = ['Delivered'];
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recorded completed-order value', style: TextStyle(color: AdminStyle.muted)),
          Text(
            adminMoney(values.fold<int>(0, (a, b) => a + b)),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AdminStyle.navy,
            ),
          ),
          const Text(
            'Sales activity from delivered orders',
            style: TextStyle(fontSize: 11, color: AdminStyle.muted),
          ),
          _space(22),
          AdminSalesChart(values: values, labels: labels),
        ],
      ),
    );
  }

  List<Widget> _approvals() {
    final items = _store.approvals.where(
      (a) => _approvalFilter == 'All' || a.status == _approvalFilter,
    );
    return [
      _title(
        'Make room for great craft.',
        'Review studio and courier applications.',
      ),
      _filters(
        ['Pending', 'Approved', 'Rejected', 'All'],
        _approvalFilter,
        (v) => _approvalFilter = v,
      ),
      if (items.isEmpty) const AdminEmptyState('No applications in this view.'),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AdminPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminStatus(item.status),
                _space(12),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AdminStyle.navy,
                  ),
                ),
                _space(6),
                Text(
                  '${item.type} · ${item.location}',
                  style: const TextStyle(fontSize: 12, color: AdminStyle.muted),
                ),
                _space(8),
                TextButton(
                  onPressed: () => _review(item),
                  child: const Text('Review application →'),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Future<void> _review(AdminApproval item) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(item.name, '${item.id} · ${item.type} · ${item.location}'),
            AdminStatus(item.status),
            _space(),
            Text(item.description, style: const TextStyle(height: 1.6)),
            _space(),
            const Text(
        'Review the submitted application before making a decision.',
              style: TextStyle(fontSize: 12, color: AdminStyle.muted),
            ),
            _space(),
            if (item.status == 'Pending')
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final approved in [false, true])
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: approved
                            ? AdminStyle.sage
                            : AdminStyle.navy,
                      ),
                      onPressed: () async {
                        final confirmed = await confirmAdminAction(
                          sheetContext,
                          approved
                              ? 'Approve application?'
                              : 'Reject application?',
                          'This updates the selected Firestore record.',
                        );
                        if (!mounted || !sheetContext.mounted || !confirmed) {
                          return;
                        }
                        _store.decide(item, approved);
                        Navigator.pop(sheetContext);
                      },
                      child: Text(approved ? 'Approve' : 'Reject'),
                    ),
                ],
              ),
          ],
        ),
      ),
    ),
  );

  List<Widget> _orders() {
    final query = _search.text.trim().toLowerCase();
    final orders = _store.orders.where(
      (o) =>
          (_orderFilter == 'All' || o.status == _orderFilter) &&
          '${o.id} ${o.customer} ${o.product}'.toLowerCase().contains(query),
    );
    return [
      _title(
        'Every piece has a journey.',
        'Browse and update marketplace orders.',
      ),
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search orders or customers',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              _search.clear();
              setState(() {});
            },
            icon: const Icon(Icons.close),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AdminStyle.border),
          ),
        ),
      ),
      _space(),
      _filters(['All', ..._statuses], _orderFilter, (v) => _orderFilter = v),
      if (orders.isEmpty)
        const AdminEmptyState(
          'No matching orders. Try another search or status.',
        ),
      for (final order in orders) _orderCard(order),
    ];
  }

  Widget _orderCard(AdminOrder order) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _orderDetails(order),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order.imageUrl?.isNotEmpty == true) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    order.imageUrl!,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    semanticLabel: order.product,
                    errorBuilder: (_, _, _) => const _MissingProductImage(),
                  ),
                ),
                _space(12),
              ] else ...[
                const SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: _MissingProductImage(),
                ),
                _space(12),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AdminStyle.clay,
                    ),
                  ),
                  AdminStatus(order.status),
                ],
              ),
              _space(10),
              Text(
                order.product,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AdminStyle.navy,
                ),
              ),
              _space(6),
              Text(
                order.customer,
                style: const TextStyle(fontSize: 12, color: AdminStyle.muted),
              ),
              _space(10),
              Text(
                adminMoney(order.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AdminStyle.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _orderDetails(AdminOrder order) {
    FocusScope.of(context).unfocus();
    var status = order.status;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, change) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(order.id, 'Order details'),
                Text(
                  order.product,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _space(),
                Text(
                  'Customer: ${order.customer}\nStudio: ${order.studio}',
                  style: const TextStyle(height: 1.7),
                ),
                _space(),
                Text(
                  adminMoney(order.amount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _space(),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final value in _statuses)
                      ChoiceChip(
                        label: Text(value),
                        selected: value == status,
                        onSelected: (_) => change(() => status = value),
                      ),
                  ],
                ),
                _space(),
                const Text(
                  'Status changes are saved to the marketplace order record.',
                  style: TextStyle(fontSize: 12, color: AdminStyle.muted),
                ),
                _space(),
                FilledButton(
                  onPressed: status == order.status
                      ? null
                      : () async {
                          final confirmed = await confirmAdminAction(
                            sheetContext,
                            'Update order?',
                            'Change ${order.id} to $status in this preview?',
                          );
                          if (!mounted || !sheetContext.mounted || !confirmed) {
                            return;
                          }
                          _store.updateOrder(order, status);
                          Navigator.pop(sheetContext);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminStyle.navy,
                  ),
                  child: const Text('Update status'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _more() => [
    _title(
      'Your guild workspace.',
      'Manage the details that keep the community moving.',
    ),
    AdminPanel(
      child: Column(
        children: [
          _action(
            Icons.people_outline,
            'Users & artisans',
            '${_store.users.length} profiles',
            () => _manage(AdminSection.users),
          ),
          _action(
            Icons.category_outlined,
            'Product catalogue',
            '${_store.products.length} listings',
            () => _manage(AdminSection.products),
          ),
          _action(
            Icons.local_shipping_outlined,
            'Courier directory',
            '${_store.couriers.length} courier partners',
            () => _manage(AdminSection.couriers),
          ),
          _action(
            Icons.bar_chart,
            'Reports & issues',
            'Order snapshot and flagged issues',
            () => _manage(AdminSection.reports),
          ),
          _action(
            Icons.tune,
            'Settings',
            'Notification preferences',
            () => _manage(AdminSection.settings),
          ),
        ],
      ),
    ),
    _space(24),
    const Text(
      'Admin actions use the authenticated Firestore account and follow the marketplace security rules.',
      style: TextStyle(fontSize: 12, height: 1.6, color: AdminStyle.muted),
    ),
  ];
}
