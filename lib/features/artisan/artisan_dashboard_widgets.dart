import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/domain_models.dart' as domain;
import 'artisan_demo.dart';

const studioClay = Color(0xFFA44126);
const studioCream = Color(0xFFF8F5F1);
const studioBlush = Color(0xFFFBEAE5);

TextStyle studioHeading(double size) => TextStyle(
  fontFamily: 'CormorantGaramond',
  fontSize: size,
  height: 1.1,
  color: AppColors.ink,
);

class ArtisanStudioHeader extends StatelessWidget {
  const ArtisanStudioHeader({
    super.key,
    required this.demo,
    required this.onProfile,
    required this.onNotifications,
    required this.onMessages,
  });
  final ArtisanDemo demo;
  final VoidCallback onProfile, onNotifications, onMessages;
  @override
  Widget build(BuildContext context) {
    final name = demo.artisanName;
    final photo =
        demo.userProfileData['photoUrl'] as String? ??
        demo.profile['photoUrl'] as String? ??
        '';
    final brand = Row(
      children: [
        const Icon(Icons.spa_outlined, color: studioClay, size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Artisan',
                style: studioHeading(34).copyWith(color: studioClay),
              ),
              const Text(
                'HANDCRAFTED WITH HEART',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.2,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Messages',
          onPressed: onMessages,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 21),
        ),
        IconButton(
          tooltip: 'Order updates',
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_none_rounded, size: 26),
        ),
        IconButton(
          tooltip: 'Artisan profile',
          onPressed: onProfile,
          icon: ClipOval(
            child: SizedBox.square(
              dimension: 34,
              child: photo.isEmpty
                  ? _initial(name)
                  : Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _initial(name),
                    ),
            ),
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 330 ||
            MediaQuery.textScalerOf(context).scale(14) > 21) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              brand,
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: brand),
            actions,
          ],
        );
      },
    );
  }

  Widget _initial(String name) => ColoredBox(
    color: const Color(0xFFEEDDD0),
    child: Center(
      child: Text(
        name.characters.first.toUpperCase(),
        style: const TextStyle(color: studioClay, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class ArtisanStudioHero extends StatelessWidget {
  const ArtisanStudioHero({super.key, required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2294492F),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/admin/craft_collection.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    studioClay,
                    studioClay.withValues(alpha: .93),
                    studioClay.withValues(alpha: .15),
                  ],
                  stops: const [0, .48, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                width: constraints.maxWidth * .78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CREATE & SELL',
                      style: TextStyle(
                        color: Color(0xFFF2D7C3),
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Handcrafted\npieces that matter',
                      style: studioHeading(30).copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add your unique creations and reach more customers.',
                      style: TextStyle(
                        color: Color(0xFFF9E8DD),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onAdd,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: studioClay,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      child: const Wrap(
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Add Product',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
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

class ArtisanStudioStats extends StatelessWidget {
  const ArtisanStudioStats({super.key, required this.demo});
  final ArtisanDemo demo;
  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final order in demo.dashboardOrders.where(
      (o) => o.status == domain.OrderStatus.delivered,
    )) {
      final revenue = order.items.fold<double>(
        0,
        (sum, item) => sum + item.unitPrice * item.quantity,
      );
      totals.update(
        order.currency,
        (value) => value + revenue,
        ifAbsent: () => revenue,
      );
    }
    final pending = demo.dashboardOrders
        .where((o) => o.status == domain.OrderStatus.pending)
        .length;
    final live = demo.repository != null;
    final unavailable = demo.ordersLoading || demo.ordersError != null || !live;
    final sales = totals.isEmpty
        ? 'No sales yet'
        : totals.entries
              .map((e) => '${e.key} ${e.value.toStringAsFixed(2)}')
              .join('\n');
    final stats = [
      (Icons.bar_chart_rounded, 'TOTAL SALES', unavailable ? '—' : sales),
      (
        Icons.shopping_bag_outlined,
        'TOTAL ORDERS',
        unavailable
            ? '—'
            : '${demo.dashboardOrders.map((o) => o.id).toSet().length}',
      ),
      (
        Icons.schedule_rounded,
        'ORDER STATUS',
        unavailable
            ? '—'
            : pending > 0
            ? '$pending pending'
            : demo.dashboardOrders.isEmpty
            ? 'No orders'
            : 'Up to date',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 330 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        Widget card(int i) => Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1E8E0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: studioBlush,
                child: Icon(stats[i].$1, color: studioClay, size: 21),
              ),
              const SizedBox(height: 12),
              Text(
                stats[i].$2,
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: .8,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                stats[i].$3,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
        return stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: card(i),
                    ),
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                          child: card(i),
                        ),
                      ),
                  ],
                ),
              );
      },
    );
  }
}

class ArtisanStudioProductTile extends StatelessWidget {
  const ArtisanStudioProductTile({
    super.key,
    required this.product,
    required this.demo,
    required this.photo,
    required this.onView,
    required this.onEdit,
  });
  final ArtisanProduct product;
  final ArtisanDemo demo;
  final Widget photo;
  final VoidCallback onView, onEdit;
  @override
  Widget build(BuildContext context) {
    final record = demo.catalogRecords[product.id];
    final status = record?.status.name ?? 'active';
    final date = record?.createdAt.toLocal();
    final badge = switch (status) {
      'active' => 'Active',
      'draft' => 'Draft',
      'hidden' => 'Hidden',
      _ => status,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E5DD)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onView,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow =
                    constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(14) > 21;
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'active'
                            ? const Color(0xFFEAF0E5)
                            : const Color(0xFFF5E9E1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          color: status == 'active'
                              ? AppColors.sage
                              : studioClay,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record == null
                          ? artisanMoney(product.price)
                          : '${record.currency} ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date == null
                          ? '${product.category} · ${product.stock} in stock'
                          : 'Added ${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                );
                final menu = PopupMenuButton<String>(
                  tooltip: 'Manage ${product.name}',
                  onSelected: (value) => value == 'edit' ? onEdit() : onView(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'view', child: Text('View Product')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                  ],
                );
                return narrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 140, child: photo),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: details),
                              menu,
                            ],
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 92, height: 108, child: photo),
                          const SizedBox(width: 14),
                          Expanded(child: details),
                          SizedBox(width: 32, child: menu),
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }
}
