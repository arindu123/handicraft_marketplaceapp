import 'package:flutter/material.dart';

import '../models/admin_demo_store.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/admin_operations_widgets.dart';
import '../widgets/admin_notification_panel.dart';
import '../../../shared/data/marketplace_repository.dart';
import 'admin_artisan_review_screen.dart';

enum AdminSection { users, products, couriers, reports, settings, activity, notifications }

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({
    super.key,
    required this.section,
    required this.store,
  });
  final AdminSection section;
  final AdminDemoStore store;
  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _title => switch (widget.section) {
    AdminSection.users => 'Users & artisans',
    AdminSection.products => 'Product catalogue',
    AdminSection.couriers => 'Courier directory',
    AdminSection.reports => 'Reports & issues',
    AdminSection.settings => 'Settings',
    AdminSection.activity => 'Admin activity history',
    AdminSection.notifications => 'Notifications',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminStyle.cream,
    appBar: AppBar(
      title: Text(
        _title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      backgroundColor: AdminStyle.cream,
      foregroundColor: AdminStyle.navy,
      surfaceTintColor: Colors.transparent,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: AnimatedBuilder(
            animation: widget.store,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'ADMIN WORKSPACE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: AdminStyle.clay,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage live marketplace records and approvals.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AdminStyle.muted,
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.section == AdminSection.settings)
                  ..._settings()
                else if (widget.section == AdminSection.reports)
                  ..._reports()
                else if (widget.section == AdminSection.activity)
                  AdminActivityPanel(store: widget.store)
                else if (widget.section == AdminSection.notifications)
                  AdminNotificationPanel(store: widget.store)
                else
                  ..._directory(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _directory() {
    final items = switch (widget.section) {
      AdminSection.users => widget.store.users,
      AdminSection.products => widget.store.products,
      _ => widget.store.couriers,
    };
    final query = _search.text.trim().toLowerCase();
    final filtered = items
        .where(
          (item) => '${item.name} ${item.detail}'.toLowerCase().contains(query),
        )
        .toList();
    return [
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search $_title',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AdminStyle.border),
          ),
        ),
      ),
      const SizedBox(height: 18),
      if (filtered.isEmpty)
        const AdminEmptyState('No matching records. Try another search.'),
      for (final item in filtered)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AdminPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AdminStyle.cream,
                      foregroundColor: AdminStyle.clay,
                      child: Icon(
                        widget.section == AdminSection.products
                            ? Icons.inventory_2_outlined
                            : widget.section == AdminSection.couriers
                            ? Icons.local_shipping_outlined
                            : Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AdminStyle.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.detail,
                  style: const TextStyle(fontSize: 12, color: AdminStyle.muted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AdminStatus(item.active ? 'Active' : 'Paused'),
                    if (widget.section == AdminSection.users && item.isArtisan)
                      TextButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminArtisanReviewScreen(
                                store: widget.store,
                                artisan: item,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Review Profile',
                          style: TextStyle(color: AdminStyle.clay),
                        ),
                      ),
                    TextButton(
                      onPressed: () async {
                        final approved = await confirmAdminAction(
                          context,
                          item.active
                              ? 'Pause ${item.name}?'
                              : 'Reactivate ${item.name}?',
                          'This updates the selected marketplace record in Firestore.',
                        );
                        if (!mounted || !approved) return;
                        widget.store.toggleItem(item);
                      },
                      child: Text(
                        item.active ? 'Pause' : 'Reactivate',
                        style: const TextStyle(color: AdminStyle.clay),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _reports() => [
    AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order status snapshot',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AdminStyle.navy,
            ),
          ),
          const SizedBox(height: 18),
          for (final status in [
            'Pending',
            'Processing',
            'Shipped',
            'Delivered',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      status,
                      style: const TextStyle(color: AdminStyle.muted),
                    ),
                  ),
                  Text(
                    '${widget.store.orders.where((order) => order.status == status).length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AdminStyle.navy,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
    const SizedBox(height: 22),
    const AdminSectionHeading('Reports'),
    const SizedBox(height: 14),
    AdminReportsPanel(store: widget.store),
  ];

  List<Widget> _settings() => [
    AdminDeliveryFeePanel(store: widget.store),
    const SizedBox(height: 24),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Application notifications'),
      subtitle: const Text('Alerts for applications awaiting review.'),
      activeThumbColor: AdminStyle.sage,
      value: widget.store.applicationNotifications,
      onChanged: widget.store.noticePreferencesLoaded ? (value) => _setNotifications(applications: value) : null,
    ),
    const Divider(color: AdminStyle.border),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Order notifications'),
      subtitle: const Text('Alerts for new orders and status changes.'),
      activeThumbColor: AdminStyle.sage,
      value: widget.store.orderNotifications,
      onChanged: widget.store.noticePreferencesLoaded ? (value) => _setNotifications(orders: value) : null,
    ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero, title: const Text('Complaint notifications'),
      subtitle: const Text('Alerts for unresolved product and delivery complaints.'),
      activeThumbColor: AdminStyle.sage, value: widget.store.reportNotifications,
      onChanged: widget.store.noticePreferencesLoaded ? (value) => _setNotifications(reports: value) : null,
    ),
    const SizedBox(height: 24),
    const AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AdminStyle.clay),
          SizedBox(height: 10),
          Text(
            'Administration settings',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminStyle.navy,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Order, approval and catalogue changes are saved through the connected Firestore admin rules.',
            style: TextStyle(color: AdminStyle.muted, height: 1.5),
          ),
        ],
      ),
    ),
  ];

  Future<void> _setNotifications({bool? applications, bool? orders, bool? reports}) async {
    try { await widget.store.setNotifications(applications: applications, orders: orders, reports: reports); }
    catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(marketplaceError(error))));
    }
  }
}
