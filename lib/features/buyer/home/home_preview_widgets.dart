import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'home_preview_data.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader(
    this.title, {
    super.key,
    this.action = 'See more',
    required this.onTap,
    this.icon,
  });
  final String title, action;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.terracotta, size: 20),
          const SizedBox(width: 5),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
            ),
          ),
        ),
        Flexible(
          child: TextButton(
            onPressed: onTap,
            child: Text('$action >', style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    ),
  );
}

class HomeCategoryRow extends StatelessWidget {
  const HomeCategoryRow({
    super.key,
    required this.onCategory,
    required this.onEvent,
  });
  final ValueChanged<String> onCategory;
  final VoidCallback onEvent;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 156,
          child: Material(
            color: AppColors.promoTint,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onEvent,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.card_giftcard_outlined,
                      size: 30,
                      color: AppColors.warmBrown,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Little gifts.\nBig smiles.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Starts soon >',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warmBrown,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        for (final category in homeCategories)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 76,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onCategory(category.$1),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: category.$1 == 'New'
                            ? AppColors.sageTint
                            : AppColors.promoTint,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        category.$2,
                        size: 28,
                        color: AppColors.warmBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class HomeVoucherCard extends StatelessWidget {
  const HomeVoucherCard({
    super.key,
    required this.collected,
    required this.onCollect,
  });
  final bool collected;
  final VoidCallback onCollect;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.sageTint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: _Voucher('25% OFF', 'Welcome voucher')),
            const SizedBox(width: 8),
            const Expanded(child: _Voucher('Rs.290', 'Free shipping')),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: collected ? null : onCollect,
          child: Text(collected ? 'Collected for preview' : 'Collect All'),
        ),
        const Text(
          'Sample vouchers - not valid at checkout',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class _Voucher extends StatelessWidget {
  const _Voucher(this.title, this.subtitle);
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.warmBrown,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class HomeEventBanner extends StatelessWidget {
  const HomeEventBanner({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
    child: Material(
      color: AppColors.warmBrown,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.heroCream, size: 32),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE MAKERS FESTIVAL',
                      style: TextStyle(
                        color: AppColors.heroCream,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Small batches. Special finds.',
                      style: TextStyle(
                        color: AppColors.background,
                        fontWeight: FontWeight.w700,
                        fontSize: 21,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Explore the preview collection >',
                      style: TextStyle(
                        color: AppColors.heroCream,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HomeProductCard extends StatelessWidget {
  const HomeProductCard({
    super.key,
    required this.product,
    required this.saved,
    required this.onSave,
    required this.onTap,
  });
  final HomePreviewProduct product;
  final bool saved;
  final VoidCallback onSave, onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.background,
    elevation: 1,
    shadowColor: AppColors.warmBrown.withValues(alpha: .12),
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  product.asset,
                  fit: BoxFit.cover,
                  cacheWidth: 600,
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton.filledTonal(
                  tooltip: saved ? 'Remove favourite' : 'Save favourite',
                  onPressed: onSave,
                  icon: Icon(
                    saved ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.terracotta,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.terracotta,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    '-${product.discount}%',
                    style: const TextStyle(
                      color: AppColors.background,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.priceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warmBrown,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '? ${product.rating} - ${product.sold} sold',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.selected,
    required this.cartCount,
    required this.onSelect,
    this.unread = 2,
  });
  final int selected, cartCount, unread;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selected,
    onDestinationSelected: onSelect,
    backgroundColor: AppColors.background,
    indicatorColor: AppColors.promoTint,
    destinations: [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home, color: AppColors.warmBrown),
        label: 'For You',
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          backgroundColor: AppColors.terracotta,
          child: const Icon(Icons.chat_bubble_outline),
        ),
        label: 'Messages',
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: cartCount > 0,
          label: Text('$cartCount'),
          backgroundColor: AppColors.terracotta,
          child: const Icon(Icons.shopping_bag_outlined),
        ),
        label: 'Cart',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        label: 'Account',
      ),
    ],
  );
}

class HomeFloatingPromo extends StatelessWidget {
  const HomeFloatingPromo({
    super.key,
    required this.onClose,
    required this.onTap,
  });
  final VoidCallback onClose, onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 80,
    height: 100,
    child: Stack(
      children: [
        Positioned(
          left: 0,
          bottom: 0,
          child: FloatingActionButton.small(
            heroTag: 'home-promo',
            tooltip: 'Preview vouchers',
            backgroundColor: AppColors.heroCream,
            foregroundColor: AppColors.warmBrown,
            onPressed: onTap,
            child: const Icon(Icons.card_giftcard),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            tooltip: 'Dismiss promotion',
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18),
          ),
        ),
      ],
    ),
  );
}
