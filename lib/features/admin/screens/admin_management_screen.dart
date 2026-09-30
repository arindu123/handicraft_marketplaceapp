import 'package:flutter/material.dart';

import '../models/admin_demo_store.dart';
import '../widgets/admin_widgets.dart';
import 'admin_artisan_review_screen.dart';

enum AdminSection { users, products, couriers, reports, settings }

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
    AdminSection.settings => 'Preview settings',
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
                  'DEMO WORKSPACE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: AdminStyle.clay,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sample data only. Changes last for this preview session.',
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
                          'This changes only this sample record. No real user, product or courier is affected.',
                        );
                        if (!mounted || !approved) return;
                        widget.store.toggleItem(item);
                      },
                      child: Text(
                        item.active ? 'Pause in demo' : 'Reactivate in demo',
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
    const AdminSectionHeading('Needs review'),
    const SizedBox(height: 14),
    _issue(
      true,
      'Product listing reported',
      'Sample report: the description of a glazed serving bowl may not match its listed dimensions.',
      widget.store.productReportResolved,
    ),
    const SizedBox(height: 12),
    _issue(
      false,
      'Delivery delay flagged',
      'Sample issue: order CR-2047 is awaiting an updated arrival estimate from the courier.',
      widget.store.deliveryIssueResolved,
    ),
  ];

  Widget _issue(bool product, String title, String detail, bool resolved) =>
      AdminPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AdminStyle.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: const TextStyle(
                color: AdminStyle.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            AdminStatus(resolved ? 'Resolved' : 'Pending'),
            if (!resolved)
              TextButton(
                onPressed: () async {
                  final confirmed = await confirmAdminAction(
                    context,
                    'Resolve sample issue?',
                    'This marks the issue as resolved in this preview only.',
                  );
                  if (mounted && confirmed) widget.store.resolveIssue(product);
                },
                child: const Text(
                  'Mark resolved (demo)',
                  style: TextStyle(color: AdminStyle.clay),
                ),
              ),
          ],
        ),
      );

  List<Widget> _settings() => [
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Application notifications'),
      subtitle: const Text('Preview preference for new studio applications.'),
      activeThumbColor: AdminStyle.sage,
      value: widget.store.applicationNotifications,
      onChanged: (value) => widget.store.setNotifications(applications: value),
    ),
    const Divider(color: AdminStyle.border),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Order notifications'),
      subtitle: const Text('Preview preference for order updates.'),
      activeThumbColor: AdminStyle.sage,
      value: widget.store.orderNotifications,
      onChanged: (value) => widget.store.setNotifications(orders: value),
    ),
    const SizedBox(height: 24),
    const AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AdminStyle.clay),
          SizedBox(height: 10),
          Text(
            'A safe space to explore',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminStyle.navy,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This is a frontend preview. No notifications are sent, no payments are processed, and no admin privileges are granted.',
            style: TextStyle(color: AdminStyle.muted, height: 1.5),
          ),
        ],
      ),
    ),
  ];
}
