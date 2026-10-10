import 'craftisan_home_hero.dart';

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'home/craftisan_preview_home.dart';
import 'handicraft_navigation_bar.dart';
import '../auth/models/marketplace_role.dart';
import '../../shared/data/community_repository.dart';
import '../../shared/data/marketplace_repository.dart';
import '../../shared/widgets/delivery_confirmation_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/route_names.dart';
import '../../shared/models/craftisan_demo_messages.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/craftisan_messaging.dart';
import 'buyer_demo.dart';
import 'buyer_orders_screens.dart';
import 'collector_profile_header.dart';
import '../../shared/data/profile_repository.dart';
import 'rotating_product_banner.dart';
import 'services/buyer_notifications.dart';
import 'product_reviews.dart';

void _signIn(BuildContext context) => Navigator.pushNamed(
  context,
  RouteNames.signIn,
  arguments: MarketplaceRole.buyer,
);

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

class BuyerMarketplace extends StatefulWidget {
  const BuyerMarketplace({super.key, this.backend, this.preview = false});
  final MarketplaceRepository? backend;
  final bool preview;
  @override
  State<BuyerMarketplace> createState() => _BuyerMarketplaceState();
}

class _BuyerMarketplaceState extends State<BuyerMarketplace> {
  late final demo = BuyerDemo(backend: widget.backend);
  StreamSubscription<RemoteMessage>? _notificationTap;
  @override
  void initState() {
    super.initState();
    if (!widget.preview || widget.backend != null) demo.addListener(_refresh);
    if (!widget.preview &&
        MarketplaceBackend.enabled &&
        demo.isSignedIn &&
        BuyerNotifications.supported) {
      unawaited(BuyerNotifications.instance.enable().catchError((Object _) {}));
      _notificationTap = FirebaseMessaging.onMessageOpenedApp.listen(
        _openAlert,
      );
      unawaited(
        FirebaseMessaging.instance
            .getInitialMessage()
            .then((message) {
              if (message != null) _openAlert(message);
            })
            .catchError((Object _) {}),
      );
    }
  }

  void _openAlert(RemoteMessage message) {
    if (message.data['type'] != 'buyerOrder') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && demo.isSignedIn) _notifications(context);
    });
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    if (demo.orderAlerts.isNotEmpty) {
      final alerts = [...demo.orderAlerts];
      demo.orderAlerts.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final alert in alerts) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(alert),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }

  void _notifications(BuildContext context) {
    if (!demo.isSignedIn) {
      _signIn(context);
      return;
    }
    _open(context, _BuyerNotificationsScreen(demo: demo));
  }

  @override
  void dispose() {
    _notificationTap?.cancel();
    if (!widget.preview || widget.backend != null) demo.dispose();
    super.dispose();
  }

  void _browse(
    BuildContext context, {
    String category = 'All',
    String query = '',
  }) => _open(
    context,
    BuyerSearch(demo: demo, category: category, initialQuery: query),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.preview && widget.backend == null) {
      return const CraftisanPreviewHome();
    }
    final categories = demo.products
        .map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    final newest = [...demo.products]
      ..sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );
    final preferred = demo.favorites.map((p) => p.category).toSet();
    final recommended = [...newest]
      ..sort(
        (a, b) => (preferred.contains(b.category) ? 1 : 0).compareTo(
          preferred.contains(a.category) ? 1 : 0,
        ),
      );
    return Theme(
      data: _buyerTheme(context),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: _cream,
          body: ColoredBox(
            color: const Color(0xFFF2E3D5),
            child: SafeArea(
              top: true,
              bottom: false,
              child: ColoredBox(
                color: _cream,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final margin = constraints.maxWidth > 900
                        ? (constraints.maxWidth - 900) / 2 + 16
                        : 16.0;
                    final cardWidth =
                        ((constraints.maxWidth - margin * 2 - 12) / 2).clamp(
                          120.0,
                          220.0,
                        );
                    final textScale =
                        MediaQuery.textScalerOf(context).scale(14) / 14;
                    final cardHeight = cardWidth / 1.06 + 112 * textScale + 20;
                    Widget section(String title, {String? subtitle}) =>
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              margin,
                              20,
                              margin,
                              12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -.5,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _browse(context),
                                      child: const Text('See all'),
                                    ),
                                  ],
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF776C64),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                    return CustomScrollView(
                      key: const PageStorageKey('buyer-home-scroll'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverToBoxAdapter(
                          child: ColoredBox(
                            color: const Color(0xFFF2E3D5),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 900,
                                ),
                                child: CraftisanHomeHero(
                                  productImageBuilder: (context, index) {
                                    final photographed = demo.products
                                        .where(
                                          (p) =>
                                              p.imageUrl?.trim().isNotEmpty ==
                                                  true ||
                                              p.imageUrls.isNotEmpty,
                                        )
                                        .toList();
                                    if (photographed.isEmpty) {
                                      return const Center(
                                        child: Icon(
                                          Icons.handyman_outlined,
                                          size: 56,
                                          color: AppColors.warmBrown,
                                        ),
                                      );
                                    }
                                    final product =
                                        photographed[index %
                                            photographed.length];
                                    return InkWell(
                                      onTap: () => _open(
                                        context,
                                        BuyerProductDetails(
                                          demo: demo,
                                          product: product,
                                        ),
                                      ),
                                      child: _Photo(
                                        product,
                                        url:
                                            product.imageUrl
                                                    ?.trim()
                                                    .isNotEmpty ==
                                                true
                                            ? product.imageUrl
                                            : product.imageUrls.first,
                                      ),
                                    );
                                  },
                                  onExplore: () => _browse(context),
                                  onSearch: (query) =>
                                      _browse(context, query: query),
                                  header: SafeArea(
                                    bottom: false,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        8,
                                        0,
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Expanded(
                                                child: Text(
                                                  'Craftisan',
                                                  style: TextStyle(
                                                    fontSize: 30,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: -1,
                                                    color: _charcoal,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Order notifications',
                                                onPressed: () =>
                                                    _notifications(context),
                                                icon: Badge(
                                                  isLabelVisible:
                                                      demo.unreadNotifications >
                                                      0,
                                                  label: Text(
                                                    '${demo.unreadNotifications}',
                                                  ),
                                                  child: const Icon(
                                                    Icons
                                                        .notifications_outlined,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Cart',
                                                onPressed: () => _open(
                                                  context,
                                                  BuyerCart(demo: demo),
                                                ),
                                                icon: const Icon(
                                                  Icons.shopping_bag_outlined,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Profile',
                                                onPressed: () => _open(
                                                  context,
                                                  BuyerProfile(demo: demo),
                                                ),
                                                icon: CollectorProfileIcon(
                                                  repository:
                                                      demo.repository == null
                                                      ? null
                                                      : ProfileRepository(
                                                          firestore: demo
                                                              .repository!
                                                              .db,
                                                          auth: demo
                                                              .repository!
                                                              .auth,
                                                        ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () => _open(
                                              context,
                                              BuyerCheckout(demo: demo),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 17,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      demo.city.isEmpty
                                                          ? 'Choose delivery address'
                                                          : 'Deliver to ${demo.city}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.keyboard_arrow_down,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        DecoratedSliver(
                          decoration: const BoxDecoration(color: _cream),
                          sliver: SliverMainAxisGroup(
                            slivers: [
                              if (demo.error != null &&
                                  demo.catalogError == null)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.all(margin),
                                    child: _Panel(child: Text(demo.error!)),
                                  ),
                                ),
                              section('Shop by Category'),
                              if (demo.loading ||
                                  demo.catalogError != null ||
                                  demo.products.isEmpty) ...[
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: margin,
                                    ),
                                    child: _Catalog(
                                      demo: demo,
                                      products: demo.products,
                                    ),
                                  ),
                                ),
                                for (final title in [
                                  'Featured Collections',
                                  'Trending Handmade',
                                  'Special Handmade Finds',
                                  'New Arrivals',
                                  'Recommended for You',
                                ]) ...[
                                  section(title),
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        margin,
                                        0,
                                        margin,
                                        8,
                                      ),
                                      child: _HomeSectionState(
                                        loading: demo.loading,
                                        error: demo.catalogError != null,
                                        onRetry: demo.repository == null
                                            ? null
                                            : demo.refreshCatalog,
                                      ),
                                    ),
                                  ),
                                ],
                              ] else ...[
                                SliverToBoxAdapter(
                                  child: SizedBox(
                                    height: 82 + 38 * textScale,
                                    child: ListView.separated(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: margin,
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: categories.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 16),
                                      itemBuilder: (context, index) {
                                        final category = categories[index];
                                        final product = demo.products
                                            .firstWhere(
                                              (p) => p.category == category,
                                            );
                                        return SizedBox(
                                          width: 82,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            onTap: () => _browse(
                                              context,
                                              category: category,
                                            ),
                                            child: Column(
                                              children: [
                                                ClipOval(
                                                  child: SizedBox(
                                                    width: 72,
                                                    height: 72,
                                                    child: _Photo(product),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  category,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                section(
                                  'Featured Collections',
                                  subtitle: 'Find your favourite material. Make it your own.',
                                ),
                                SliverToBoxAdapter(
                                  child: SizedBox(
                                    height: 180 + (textScale - 1) * 100,
                                    child: ListView.separated(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: margin,
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: categories.take(6).length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final category = categories[index];
                                        final products = demo.products
                                            .where(
                                              (p) => p.category == category,
                                            )
                                            .toList();
                                        return SizedBox(
                                          width: (constraints.maxWidth * .72)
                                              .clamp(230.0, 340.0),
                                          child: Material(
                                            color: index.isEven
                                                ? const Color(0xFFEDE2D5)
                                                : const Color(0xFFE4EADF),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: InkWell(
                                              onTap: () => _browse(
                                                context,
                                                category: category,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            category,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            '${products.length} handmade finds',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 11,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          const Icon(
                                                            Icons
                                                                .arrow_forward_rounded,
                                                            size: 20,
                                                            color: _clay,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    SizedBox(
                                                      width: 80,
                                                      height: 112,
                                                      child: _Photo(
                                                        products.first,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                section(
                                  'Trending Handmade',
                                  subtitle: 'Discover pieces from the current handmade edit.',
                                ),
                                SliverToBoxAdapter(
                                  child: SizedBox(
                                    height: cardHeight,
                                    child: ListView.separated(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: margin,
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: demo.products.take(10).length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (_, index) => SizedBox(
                                        width: cardWidth,
                                        child: _ProductCard(
                                          demo: demo,
                                          product: demo.products[index],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                section(
                                  'Special Handmade Finds',
                                  subtitle: 'A closer look at distinctive pieces from our makers.',
                                ),
                                SliverToBoxAdapter(
                                  child: SizedBox(
                                    height: cardHeight,
                                    child: ListView.separated(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: margin,
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: newest.take(6).length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (_, index) => SizedBox(
                                        width: cardWidth,
                                        child: _ProductCard(
                                          demo: demo,
                                          product: newest[index],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                section(
                                  'New Arrivals',
                                  subtitle: 'Fresh additions from independent makers.',
                                ),
                                SliverPadding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: margin,
                                  ),
                                  sliver: SliverLayoutBuilder(
                                    builder: (context, constraints) {
                                      final width =
                                          (constraints.crossAxisExtent - 12) /
                                          2;
                                      return SliverGrid(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 14,
                                              mainAxisExtent:
                                                  width / 1.06 +
                                                  112 * textScale +
                                                  20,
                                            ),
                                        delegate: SliverChildBuilderDelegate(
                                          (_, index) => _ProductCard(
                                            demo: demo,
                                            product: newest[index],
                                          ),
                                          childCount: newest.take(12).length,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                section(
                                  'Recommended for You',
                                  subtitle: preferred.isEmpty
                                      ? 'Save pieces you love to shape your recommendations.'
                                      : 'More from the craft categories you have saved.',
                                ),
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(
                                    margin,
                                    0,
                                    margin,
                                    24,
                                  ),
                                  sliver: SliverLayoutBuilder(
                                    builder: (context, constraints) {
                                      final width =
                                          (constraints.crossAxisExtent - 12) /
                                          2;
                                      return SliverGrid(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 14,
                                              mainAxisExtent:
                                                  width / 1.06 +
                                                  112 * textScale +
                                                  20,
                                            ),
                                        delegate: SliverChildBuilderDelegate(
                                          (_, index) => _ProductCard(
                                            demo: demo,
                                            product: recommended[index],
                                          ),
                                          childCount: recommended
                                              .take(12)
                                              .length,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          bottomNavigationBar: HandicraftNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (index) {
              if (index == 0) return;
              _open(context, switch (index) {
                1 => BuyerSearch(demo: demo),
                2 => BuyerFavorites(demo: demo),
                3 => BuyerCart(demo: demo),
                _ => BuyerProfile(demo: demo),
              });
            },
          ),
        ),
      ),
    );
  }
}

class _BuyerNotificationsScreen extends StatefulWidget {
  const _BuyerNotificationsScreen({required this.demo});
  final BuyerDemo demo;

  @override
  State<_BuyerNotificationsScreen> createState() =>
      _BuyerNotificationsScreenState();
}

class _BuyerNotificationsScreenState extends State<_BuyerNotificationsScreen> {
  bool _enabling = false;

  @override
  void initState() {
    super.initState();
    widget.demo.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.demo.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _enable() async {
    setState(() => _enabling = true);
    try {
      await BuyerNotifications.instance.enable();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order alerts enabled.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(marketplaceError(e))));
      }
    } finally {
      if (mounted) setState(() => _enabling = false);
    }
  }

  Future<void> _select(Map<String, dynamic> notification) async {
    try {
      await widget.demo.readNotification(notification['id'] as String);
      if (!mounted) return;
      _open(
        context,
        BuyerOrderDetailsScreen(
          demo: widget.demo,
          orderId: notification['orderId'] as String,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(marketplaceError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order notifications')),
    body: Column(
      children: [
        if (BuyerNotifications.supported)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _enabling ? null : _enable,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(
                _enabling ? 'Enabling alerts…' : 'Enable phone alerts',
              ),
            ),
          ),
        if (widget.demo.notificationError != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.demo.notificationError!),
          ),
        Expanded(
          child: widget.demo.notifications.isEmpty
              ? const Center(child: Text('Order updates will appear here.'))
              : ListView.separated(
                  itemCount: widget.demo.notifications.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = widget.demo.notifications[index];
                    return ListTile(
                      leading: Icon(
                        notification['read'] == true
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: AppColors.warmBrown,
                      ),
                      title: Text(
                        notification['body'] as String? ?? 'Order updated',
                        style: TextStyle(
                          fontWeight: notification['read'] == true
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text('Order #${notification['orderId']}'),
                      onTap: () => _select(notification),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

class _HomeSectionState extends StatelessWidget {
  const _HomeSectionState({
    required this.loading,
    required this.error,
    this.onRetry,
  });
  final bool loading, error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF0E8DD),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5D8CA)),
    ),
    child: Row(
      children: [
        if (loading)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            error ? Icons.cloud_off_outlined : Icons.handyman_outlined,
            color: _clay,
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            loading
                ? 'Finding handmade pieces?'
                : error
                ? 'Unable to load this collection. Check your connection and try again.'
                : 'New handmade pieces will appear here when makers publish them.',
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        if (error && onRetry != null)
          IconButton(
            tooltip: 'Retry collection',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
          ),
      ],
    ),
  );
}

const _clay = Color(0xFF9A4023);
const _cream = Color(0xFFFBF9F7);
const _charcoal = Color(0xFF1B1C1B);
const _mint = Color(0xFFC6EBD9);

ThemeData _buyerTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    scaffoldBackgroundColor: _cream,
    colorScheme: base.colorScheme.copyWith(
      primary: _clay,
      surface: _cream,
      onSurface: _charcoal,
    ),
    textTheme: base.textTheme
        .apply(
          fontFamily: 'Roboto',
          bodyColor: _charcoal,
          displayColor: _charcoal,
        )
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 28,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
            color: _charcoal,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            height: 1.4,
            color: _charcoal,
          ),
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE1DEDB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE1DEDB)),
      ),
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.onPressed);
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: _clay,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 54),
      padding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: onPressed,
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );
}

class _Catalog extends StatelessWidget {
  const _Catalog({required this.demo, required this.products});
  final BuyerDemo demo;
  final List<DemoProduct> products;
  @override
  Widget build(BuildContext context) {
    if (demo.loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (demo.catalogError != null) {
      return _Panel(
        child: Column(
          children: [
            Text(demo.catalogError!),
            if (demo.repository != null)
              TextButton(
                onPressed: demo.refreshCatalog,
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }
    if (products.isEmpty) {
      return const _Panel(
        child: Text('No pieces found. Try another search or come back soon.'),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 10,
        runSpacing: 14,
        children: [
          for (final p in products)
            SizedBox(
              width: (constraints.maxWidth - 10) / 2,
              child: _ProductCard(demo: demo, product: p),
            ),
        ],
      ),
    );
  }
}

class _BuyerPage extends StatelessWidget {
  const _BuyerPage({
    required this.demo,
    required this.title,
    required this.children,
    this.tab,
    this.footer,
    this.requiresLogin = false,
  });
  final BuyerDemo demo;
  final String title;
  final List<Widget> children;
  final int? tab;
  final Widget? footer;
  final bool requiresLogin;
  bool get locked => requiresLogin && !demo.isSignedIn;
  @override
  Widget build(BuildContext context) => Theme(
    data: _buyerTheme(context),
    child: Builder(
      builder: (context) => Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _cream,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: tab != 0,
          leading: tab == 0
              ? null
              : BackButton(onPressed: () => Navigator.maybePop(context)),
          centerTitle: tab != 0,
          title: Text(
            title,
            style: TextStyle(
              fontSize: tab == 0 ? 30 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -.6,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Cart',
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () => _open(context, BuyerCart(demo: demo)),
            ),
            if (tab == 0)
              IconButton(
                tooltip: 'Profile',
                icon: CollectorProfileIcon(
                  repository: demo.repository == null
                      ? null
                      : ProfileRepository(
                          firestore: demo.repository!.db,
                          auth: demo.repository!.auth,
                        ),
                ),
                onPressed: () => _open(context, BuyerProfile(demo: demo)),
              ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  ListenableBuilder(
                    listenable: demo,
                    builder: (_, _) => demo.error == null
                        ? const SizedBox.shrink()
                        : _Panel(
                            child: Text(
                              demo.error!,
                              style: const TextStyle(color: _clay),
                            ),
                          ),
                  ),
                  if (locked) ...[
                    const SizedBox(height: 32),
                    const Icon(Icons.lock_outline, size: 48, color: _clay),
                    const SizedBox(height: 20),
                    const _Heading('Sign in to continue'),
                    const SizedBox(height: 12),
                    const Text(
                      'Sign in to view your profile, add pieces to your cart and place orders. You can browse products without an account.',
                    ),
                    const SizedBox(height: 24),
                    _Action('Sign in', () => _signIn(context)),
                  ] else
                    ...children,
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: !locked && footer != null
            ? Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E2DF))),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SafeArea(
                  top: false,
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                        child: footer,
                      ),
                    ),
                  ),
                ),
              )
            : tab == null
            ? null
            : HandicraftNavigationBar(
                selectedIndex: tab!,
                onDestinationSelected: (index) {
                  if (index == tab) return;
                  if (index == 0) {
                    Navigator.popUntil(
                      context,
                      (r) =>
                          r.settings.name == RouteNames.marketplace ||
                          r.isFirst,
                    );
                    return;
                  }
                  final screen = switch (index) {
                    1 => BuyerSearch(demo: demo),
                    2 => BuyerFavorites(demo: demo),
                    3 => BuyerCart(demo: demo),
                    _ => BuyerProfile(demo: demo),
                  };
                  if (tab == 0 || index == 3) {
                    _open(context, screen);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(builder: (_) => screen),
                    );
                  }
                },
              ),
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: Theme.of(context).textTheme.headlineLarge),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      letterSpacing: 1,
      color: AppColors.terracotta,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE8E5E2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

class _Photo extends StatelessWidget {
  const _Photo(this.product, {this.height, this.url});
  final DemoProduct product;
  final double? height;
  final String? url;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: ColoredBox(
      color: const Color(0xFFEFECE8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final source = url ?? product.imageUrl;
          if (source == null || source.isEmpty) {
            return SizedBox(
              height: height,
              width: double.infinity,
              child: const Center(
                child: Icon(Icons.image_outlined, color: Colors.grey),
              ),
            );
          }
          final pixels =
              (constraints.maxWidth.isFinite
                      ? constraints.maxWidth *
                            MediaQuery.devicePixelRatioOf(context)
                      : 900)
                  .round()
                  .clamp(100, 1600);
          final uri = Uri.tryParse(source);
          final imageUrl =
              uri?.host == 'res.cloudinary.com' &&
                  source.contains('/image/upload/')
              ? source.replaceFirst(
                  '/image/upload/',
                  '/image/upload/c_limit,w_$pixels,q_auto:good,f_auto/',
                )
              : source;
          return Image.network(
            imageUrl,
            cacheWidth: pixels,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: product.name,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : SizedBox(
                    height: height,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
            errorBuilder: (_, _, _) => SizedBox(
              height: height,
              child: const Center(
                child: Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _ProductCardPhotos extends StatelessWidget {
  const _ProductCardPhotos(this.product);
  final DemoProduct product;

  @override
  Widget build(BuildContext context) {
    final images = [
      ?product.imageUrl,
      ...product.imageUrls,
    ].where((url) => url.trim().isNotEmpty).toSet().toList();
    if (images.length < 2) return _Photo(product, url: images.firstOrNull);
    return RotatingProductBanner(
      key: ValueKey(product.id),
      slide: true,
      imageKeys: images,
      imageBuilder: (_, index) => Stack(
        fit: StackFit.expand,
        children: [
          _Photo(product, url: images[index]),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${index + 1}/${images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.demo, required this.product});
  final BuyerDemo demo;
  final DemoProduct product;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    elevation: 1.5,
    shadowColor: const Color(0x1870452F),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () =>
          _open(context, BuyerProductDetails(demo: demo, product: product)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.06,
                child: _ProductCardPhotos(product),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F1E7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.isVerified
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: Color(0xFF47745C),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Verified maker',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF47745C),
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Handmade',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF70452F),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: _FavoriteButton(demo: demo, product: product),
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (product.studio.isNotEmpty)
                  Text(
                    product.studio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 6),
                Text(
                  product.priceLabel(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.demo, required this.product});
  final BuyerDemo demo;
  final DemoProduct product;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (_, _) {
      final saved = demo.favorites.contains(product);
      return IconButton.filledTonal(
        style: IconButton.styleFrom(backgroundColor: Colors.white),
        tooltip: saved ? 'Remove from favorites' : 'Save to favorites',
        onPressed: () => demo.favorite(product),
        icon: Icon(
          saved ? Icons.favorite : Icons.favorite_outline,
          color: AppColors.terracotta,
        ),
      );
    },
  );
}

class BuyerSearch extends StatefulWidget {
  const BuyerSearch({
    super.key,
    required this.demo,
    this.category = 'All',
    this.initialQuery = '',
  });
  final BuyerDemo demo;
  final String category;
  final String initialQuery;
  @override
  State<BuyerSearch> createState() => _BuyerSearchState();
}

class _BuyerSearchState extends State<BuyerSearch> {
  late final query = TextEditingController(text: widget.initialQuery);
  final maxPrice = TextEditingController();
  late String category = widget.category;
  String sort = 'Name';
  String location = 'All';
  String studio = 'All';
  bool filters = false;
  @override
  void initState() {
    super.initState();
    widget.demo.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.demo.removeListener(_refresh);
    query.dispose();
    maxPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final limit = double.tryParse(maxPrice.text);
    final results = widget.demo.products
        .where(
          (p) =>
              (category == 'All' || p.category == category) &&
              (location == 'All' || p.location == location) &&
              (studio == 'All' || p.studio == studio) &&
              (limit == null || p.price <= limit) &&
              '${p.name} ${p.category} ${p.studio}'.toLowerCase().contains(
                query.text.trim().toLowerCase(),
              ),
        )
        .toList();
    if (sort == 'Price: low to high') {
      results.sort((a, b) => a.price.compareTo(b.price));
    }
    if (sort == 'Price: high to low') {
      results.sort((a, b) => b.price.compareTo(a.price));
    }
    if (sort == 'Name') results.sort((a, b) => a.name.compareTo(b.name));
    final active =
        (category == 'All' ? 0 : 1) +
        (limit == null ? 0 : 1) +
        (location == 'All' ? 0 : 1) +
        (studio == 'All' ? 0 : 1);
    return _BuyerPage(
      demo: widget.demo,
      title: 'Search',
      tab: 1,
      children: [
        TextField(
          controller: query,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search handmade pieces',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Clear search',
              onPressed: () => setState(query.clear),
              icon: const Icon(Icons.cancel_outlined),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => filters = !filters),
                icon: const Icon(Icons.tune),
                label: Text(active == 0 ? 'Filters' : 'Filters  $active'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PopupMenuButton<String>(
                initialValue: sort,
                onSelected: (v) => setState(() => sort = v),
                itemBuilder: (_) => [
                  for (final v in [
                    'Price: low to high',
                    'Price: high to low',
                    'Name',
                  ])
                    PopupMenuItem(value: v, child: Text(v)),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_vert),
                      SizedBox(width: 8),
                      Text('Sort'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (filters)
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in {
                      'All',
                      ...widget.demo.products
                          .map((p) => p.category)
                          .where((c) => c.isNotEmpty),
                    })
                      ChoiceChip(
                        label: Text(c),
                        selected: c == category,
                        onSelected: (_) => setState(() => category = c),
                      ),
                  ],
                ),
                if (widget.demo.products.any((p) => p.location.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  const Text('Location'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final value in {
                        'All',
                        ...widget.demo.products
                            .map((p) => p.location)
                            .where((v) => v.isNotEmpty),
                      })
                        ChoiceChip(
                          label: Text(value),
                          selected: location == value,
                          onSelected: (_) => setState(() => location = value),
                        ),
                    ],
                  ),
                ],
                if (widget.demo.products.any((p) => p.studio.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  const Text('Artisan'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final value in {
                        'All',
                        ...widget.demo.products
                            .map((p) => p.studio)
                            .where((v) => v.isNotEmpty),
                      })
                        ChoiceChip(
                          label: Text(value),
                          selected: studio == value,
                          onSelected: (_) => setState(() => studio = value),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: maxPrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Maximum price'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        if (active > 0)
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (category != 'All')
                InputChip(
                  label: Text(category),
                  onDeleted: () => setState(() => category = 'All'),
                ),
              if (location != 'All')
                InputChip(
                  label: Text(location),
                  onDeleted: () => setState(() => location = 'All'),
                ),
              if (studio != 'All')
                InputChip(
                  label: Text(studio),
                  onDeleted: () => setState(() => studio = 'All'),
                ),
              if (limit != null)
                InputChip(
                  label: Text('Under ${maxPrice.text}'),
                  onDeleted: () => setState(maxPrice.clear),
                ),
              TextButton(
                onPressed: () => setState(() {
                  category = 'All';
                  location = 'All';
                  studio = 'All';
                  maxPrice.clear();
                }),
                child: const Text('Clear all'),
              ),
            ],
          ),
        const SizedBox(height: 14),
        if (!widget.demo.loading && widget.demo.catalogError == null)
          Row(
            children: [
              Expanded(
                child: Text(
                  '${results.length} pieces found',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  sort,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        _Catalog(demo: widget.demo, products: results),
      ],
    );
  }
}

class BuyerProductDetails extends StatefulWidget {
  const BuyerProductDetails({
    super.key,
    required this.demo,
    required this.product,
  });
  final BuyerDemo demo;
  final DemoProduct product;
  @override
  State<BuyerProductDetails> createState() => _BuyerProductDetailsState();
}

class _BuyerProductDetailsState extends State<BuyerProductDetails> {
  int quantity = 1;
  int photo = 0;
  bool adding = false;
  @override
  void initState() {
    super.initState();
    widget.demo.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.demo.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.demo.products
        .where((p) => p == widget.product)
        .firstOrNull;
    if (p == null) {
      return _BuyerPage(
        demo: widget.demo,
        title: 'Product details',
        children: const [Text('This product is no longer available.')],
      );
    }
    final images = p.imageUrls;
    return _BuyerPage(
      demo: widget.demo,
      title: 'Product details',
      footer: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total', style: TextStyle(color: Colors.grey)),
                Text(
                  p.priceLabel(quantity),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _Action(
              adding ? 'Adding...' : 'Add to cart',
              adding || p.stock == null || quantity > p.stock!
                  ? null
                  : () async {
                      if (!widget.demo.isSignedIn) {
                        _signIn(context);
                        return;
                      }
                      setState(() => adding = true);
                      try {
                        await widget.demo.add(p, quantity);
                        if (context.mounted) {
                          _open(context, BuyerCart(demo: widget.demo));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(marketplaceError(e))),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => adding = false);
                      }
                    },
            ),
          ),
        ],
      ),
      children: [
        AspectRatio(
          aspectRatio: 1.2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (images.isEmpty)
                _Photo(p)
              else
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (v) => setState(() => photo = v),
                  itemBuilder: (_, i) => _Photo(p, url: images[i]),
                ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    _FavoriteButton(demo: widget.demo, product: p),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      tooltip: 'Copy product details',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text:
                                '${p.name} - ${p.priceLabel()}\n${p.description}',
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product details copied.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.ios_share),
                    ),
                  ],
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Chip(label: Text('${photo + 1} / ${images.length}')),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (p.category.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              backgroundColor: _mint,
              side: BorderSide.none,
              label: Text(p.category),
            ),
          ),
        _Heading(p.name),
        Row(
          children: [
            Expanded(
              child: Text(
                p.priceLabel(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (p.stock != null)
              Text(
                p.stock == 0 ? 'Out of stock' : '${p.stock} available',
                style: const TextStyle(color: _clay),
              ),
          ],
        ),
        _Panel(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: _mint,
              child: Icon(Icons.storefront_outlined),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    p.studio.isEmpty ? 'Meet the maker' : p.studio,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (p.isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: Color(0xFF47745C),
                  ),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(
              context,
              BuyerArtisanProfile(
                demo: widget.demo,
                artisan: BuyerArtisan(
                  name: p.artisan,
                  studio: '',
                  location: '',
                  bio: '',
                  rating: 0,
                  reviewCount: 0,
                  reviews: const [],
                ),
                avatarProduct: p,
              ),
            ),
          ),
        ),
        if (widget.demo.repository != null && widget.demo.isSignedIn)
          _Panel(
            child: ProductReviews(
              repository: CommunityRepository(
                firestore: widget.demo.repository!.db,
                auth: widget.demo.repository!.auth,
              ),
              productId: p.id,
            ),
          ),
        if (p.description.isNotEmpty)
          _Panel(
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: const Text('Details & care'),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(p.description),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Quantity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            _Quantity(
              value: quantity,
              onChanged: (v) {
                if (v > 0 && p.stock != null && v <= p.stock!) {
                  setState(() => quantity = v);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class BuyerArtisanProfile extends StatelessWidget {
  const BuyerArtisanProfile({
    super.key,
    required this.demo,
    required this.artisan,
    required this.avatarProduct,
  });
  final BuyerDemo demo;
  final BuyerArtisan artisan;
  final DemoProduct avatarProduct;

  @override
  Widget build(BuildContext context) => MarketplaceBackend.enabled
      ? StreamBuilder(
          stream: CommunityRepository().reviews(avatarProduct.artisan),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _BuyerPage(
                demo: demo,
                title: 'Artisan Profile',
                children: [Text(marketplaceError(snapshot.error!))],
              );
            }
            final rows = snapshot.data?.docs ?? [];
            final reviews = rows
                .map(
                  (d) => BuyerReview(
                    d.data()['buyerId'] as String,
                    (d.data()['rating'] as num).toDouble(),
                    d.data()['comment'] as String,
                    '',
                  ),
                )
                .toList();
            return StreamBuilder(
              stream: CommunityRepository().profile(avatarProduct.artisan),
              builder: (context, profile) {
                final data = profile.data?.data() ?? {};
                return _content(
                  context,
                  BuyerArtisan(
                    name: avatarProduct.artisan,
                    studio: data['studioName'] as String? ?? '',
                    location: data['location'] as String? ?? '',
                    bio: data['bio'] as String? ?? '',
                    rating: reviews.isEmpty
                        ? 0
                        : reviews.fold<double>(
                                0,
                                (total, r) => total + r.rating,
                              ) /
                              reviews.length,
                    reviewCount: reviews.length,
                    reviews: reviews,
                  ),
                );
              },
            );
          },
        )
      : _content(context, artisan);
  Widget _content(
    BuildContext context,
    BuyerArtisan artisan,
  ) => ListenableBuilder(
    listenable: demo,
    builder: (context, _) {
      final following = demo.followedArtisans.contains(artisan.name);
      final products = demo.products
          .where((product) => product.artisan == artisan.name)
          .toList();
      return _BuyerPage(
        demo: demo,
        title: 'Artisan Profile',
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundImage: avatarProduct.imageUrl == null
                  ? null
                  : NetworkImage(avatarProduct.imageUrl!),
              child: avatarProduct.imageUrl == null
                  ? const Icon(Icons.storefront_outlined)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: _Heading(artisan.name)),
          Center(child: Text(artisan.studio)),
          const SizedBox(height: 8),
          if (avatarProduct.isVerified)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFB9D8C2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Color(0xFF47745C), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Verified maker',
                      style: TextStyle(
                        color: Color(0xFF47745C),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Center(
            child: Text(
              artisan.location,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => demo.followArtisan(artisan),
            style: FilledButton.styleFrom(
              backgroundColor: following
                  ? AppColors.surface
                  : AppColors.terracotta,
              foregroundColor: following ? AppColors.terracotta : Colors.white,
              minimumSize: const Size(180, 48),
            ),
            icon: Icon(following ? Icons.check : Icons.add),
            label: Text(following ? 'Following' : 'Follow Artisan'),
          ),
          TextButton.icon(
            onPressed: () => _open(
              context,
              CraftisanConversationScreen(
                artisanId: avatarProduct.artisan,
                viewer: DemoMessageAuthor.buyer,
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Message Artisan'),
          ),
          const SizedBox(height: 20),
          const _Heading('About the studio'),
          Text(artisan.bio, style: Theme.of(context).textTheme.bodyLarge),
          _Panel(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.star, color: Color(0xFF91620E)),
                Text(
                  '${artisan.rating.toStringAsFixed(1)} overall rating',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${artisan.reviewCount} reviews',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const _Heading('Reviews'),
          for (final review in artisan.reviews)
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.reviewer,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Color(0xFF91620E),
                      ),
                      Text(' ${review.rating.toStringAsFixed(1)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.comment),
                  const SizedBox(height: 8),
                  Text(
                    review.date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          _Heading('From ${artisan.name.split(' ').first}'),
          for (final product in products)
            _Panel(
              child: InkWell(
                onTap: () => _open(
                  context,
                  BuyerProductDetails(demo: demo, product: product),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 68, height: 68, child: _Photo(product)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name),
                          Text(product.priceLabel()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _Quantity extends StatelessWidget {
  const _Quantity({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Decrease quantity',
        onPressed: () => onChanged(value - 1),
        icon: const Icon(Icons.remove),
      ),
      Text('$value'),
      IconButton(
        tooltip: 'Increase quantity',
        onPressed: () => onChanged(value + 1),
        icon: const Icon(Icons.add),
      ),
    ],
  );
}

class BuyerCart extends StatelessWidget {
  const BuyerCart({super.key, required this.demo});
  final BuyerDemo demo;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (context, _) => _ShoppingCartPage(
      demo: demo,
      title: 'Cart (${demo.count})',
      requiresLogin: true,
      children: [
        if (demo.loading || demo.cartLoading)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (demo.cartError != null)
          Text(demo.cartError!)
        else if (demo.cart.isEmpty && demo.unavailableCartIds.isEmpty)
          _EmptyShoppingCart(demo: demo),
        for (final id in demo.unavailableCartIds)
          _Panel(
            child: ListTile(
              title: const Text('This product is no longer available.'),
              trailing: IconButton(
                tooltip: 'Remove unavailable product',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => demo.removeUnavailable(id),
              ),
            ),
          ),
        for (final entry in demo.cart.entries)
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => _open(
                    context,
                    BuyerProductDetails(demo: demo, product: entry.key),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 100,
                        child: _Photo(entry.key),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(entry.key.artisan),
                            Text('${entry.key.priceLabel()} each'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: Text(entry.key.priceLabel(entry.value))),
                    _Quantity(
                      value: entry.value,
                      onChanged: (v) => demo.quantity(entry.key, v),
                    ),
                    IconButton(
                      tooltip: 'Remove ${entry.key.name}',
                      onPressed: () => demo.quantity(entry.key, 0),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (demo.cart.isNotEmpty) ...[
          const _Panel(
            child: Text(
              'Checkout supports up to four different products from one artisan per order.',
            ),
          ),
          _Totals(demo),
        ],
        const Divider(height: 40),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.local_shipping_outlined),
          title: Text(
            'Cash on delivery',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Track your order from confirmation to delivery.'),
        ),
        const SizedBox(height: 24),
        const _Heading('More to love'),
        const SizedBox(height: 16),
        if (demo.catalogError != null)
          Text(demo.catalogError!)
        else if (!demo.loading && demo.products.isEmpty)
          const Text('No products available right now.')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final products = demo.products
                  .where((p) => (p.stock ?? 0) > 0)
                  .take(12)
                  .toList();
              return Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  for (final product in products)
                    SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: _ProductCard(demo: demo, product: product),
                    ),
                ],
              );
            },
          ),
      ],
    ),
  );
}

class _EmptyShoppingCart extends StatelessWidget {
  const _EmptyShoppingCart({required this.demo});
  final BuyerDemo demo;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 42),
    child: Column(
      children: [
        Container(
          width: 124,
          height: 124,
          decoration: const BoxDecoration(
            color: Color(0xFFFFEEE8),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shopping_cart_outlined,
            size: 68,
            color: Color(0xFFE63246),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Your cart is empty.',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          'Continue shopping to explore more.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF1F3F5),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
          ),
          onPressed: () => _open(context, BuyerSearch(demo: demo)),
          child: const Text(
            'Explore items',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
      ],
    ),
  );
}

class _ShoppingCartPage extends StatelessWidget {
  const _ShoppingCartPage({
    required this.demo,
    required this.title,
    required this.children,
    this.requiresLogin = true,
  });
  final BuyerDemo demo;
  final String title;
  final List<Widget> children;
  final bool requiresLogin;

  Future<void> _clear(BuildContext context) async {
    final repository = demo.repository;
    if (repository == null) return;
    try {
      final snapshot = await repository.userCollection('cart').get();
      final batch = repository.db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(marketplaceError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: _buyerTheme(context),
    child: Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          IconButton(
            tooltip: 'Search products',
            onPressed: () => _open(context, BuyerSearch(demo: demo)),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Saved products',
            onPressed: () => _open(context, BuyerFavorites(demo: demo)),
            icon: const Icon(Icons.favorite_border),
          ),
          IconButton(
            tooltip: 'Clear cart',
            onPressed: demo.cart.isEmpty && demo.unavailableCartIds.isEmpty
                ? null
                : () => _clear(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        demo.country.isEmpty
                            ? 'Choose delivery address'
                            : demo.country,
                      ),
                    ),
                    TextButton(
                      onPressed: demo.isSignedIn
                          ? () => _open(context, BuyerCheckout(demo: demo))
                          : () => _signIn(context),
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
              if (demo.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(demo.error!),
                ),
              if (requiresLogin && !demo.isSignedIn) ...[
                const SizedBox(height: 40),
                const Center(child: Text('Sign in to continue')),
                TextButton(
                  onPressed: () => _signIn(context),
                  child: const Text('Sign in'),
                ),
              ] else
                ...children,
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: _cream,
              border: Border(top: BorderSide(color: Color(0xFFEDEDED))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${demo.count} items',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        money(demo.total, demo.currency),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE60023),
                    disabledBackgroundColor: const Color(0xFFFFDDE3),
                    disabledForegroundColor: const Color(0xFFA96570),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 15,
                    ),
                  ),
                  onPressed:
                      demo.cart.isEmpty ||
                          demo.cartLoading ||
                          demo.cartError != null ||
                          !demo.isSignedIn
                      ? null
                      : () => _open(context, BuyerCheckout(demo: demo)),
                  child: Text(
                    'Checkout (${demo.count})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          NavigationBar(
            backgroundColor: _cream,
            indicatorColor: const Color(0xFFFFE4E8),
            selectedIndex: 2,
            height: 66,
            onDestinationSelected: (index) {
              if (index == 0) {
                Navigator.popUntil(
                  context,
                  (route) =>
                      route.isFirst ||
                      route.settings.name == RouteNames.marketplace,
                );
              }
              if (index == 1) _open(context, BuyerSearch(demo: demo));
              if (index == 3) _open(context, BuyerProfile(demo: demo));
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              NavigationDestination(icon: Icon(Icons.search), label: 'Shop'),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart, color: Color(0xFFE60023)),
                label: 'Cart',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Account',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Totals extends StatelessWidget {
  const _Totals(this.demo);
  final BuyerDemo demo;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      children: [
        _Amount(
          'Items subtotal (${demo.count})',
          money(demo.subtotal, demo.currency),
        ),
        _Amount(
          'Delivery',
          demo.delivery == 0 ? 'Free' : money(demo.delivery, demo.currency),
        ),
        const Divider(),
        _Amount('Total', money(demo.total, demo.currency)),
      ],
    ),
  );
}

class _Amount extends StatelessWidget {
  const _Amount(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class BuyerFavorites extends StatefulWidget {
  const BuyerFavorites({super.key, required this.demo});
  final BuyerDemo demo;
  @override
  State<BuyerFavorites> createState() => _BuyerFavoritesState();
}

class _BuyerFavoritesState extends State<BuyerFavorites> {
  String? _category;
  int _sort = 0;
  BuyerDemo get demo => widget.demo;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (_, _) {
      final categories = demo.favorites
          .map((p) => p.category)
          .where((c) => c.isNotEmpty)
          .toSet();
      final selected = categories.contains(_category) ? _category : null;
      final pieces = demo.favorites
          .where((p) => selected == null || p.category == selected)
          .toList();
      if (_sort != 0) {
        pieces.sort(
          (a, b) => _sort == 1
              ? a.price.compareTo(b.price)
              : b.price.compareTo(a.price),
        );
      }
      return _BuyerPage(
        demo: demo,
        title: 'Saved',
        tab: 2,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFEB),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'COLLECT LITTLE JOYS',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 2,
                          color: Color(0xFF10494D),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, color: _clay, size: 19),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Love it.\nKeep it close.',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 39,
                    height: 1.02,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10494D),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A little space for the pieces that feel like you.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF526B62),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (demo.loading || demo.catalogError != null)
            _Catalog(demo: demo, products: pieces)
          else if (demo.favorites.isEmpty) ...[
            const SizedBox(height: 18),
            const Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFFF3E7DD),
                child: Icon(Icons.bookmarks_outlined, size: 34, color: _clay),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your favourites start here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap the heart on a piece to save it here.\nCome back whenever it feels right.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            _Action(
              'Find your first favourite',
              () => _open(context, BuyerSearch(demo: demo)),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${pieces.length} saved ${pieces.length == 1 ? 'piece' : 'pieces'}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<int>(
                  tooltip: 'Sort saved pieces',
                  initialValue: _sort,
                  onSelected: (value) => setState(() => _sort = value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0, child: Text('Default order')),
                    PopupMenuItem(value: 1, child: Text('Price: low to high')),
                    PopupMenuItem(value: 2, child: Text('Price: high to low')),
                  ],
                  icon: const Icon(Icons.sort_rounded, color: _clay),
                ),
              ],
            ),
            if (categories.length > 1) ...[
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final category in <String?>[null, ...categories])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category ?? 'All pieces'),
                          selected: selected == category,
                          selectedColor: const Color(0xFFE8EFEB),
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (final product in pieces)
              _SavedProductRow(
                key: ValueKey(product.id),
                demo: demo,
                product: product,
              ),
            const SizedBox(height: 22),
            TextButton.icon(
              onPressed: () => _open(context, BuyerSearch(demo: demo)),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Discover more to love'),
            ),
          ],
        ],
      );
    },
  );
}

class _SavedProductRow extends StatefulWidget {
  const _SavedProductRow({
    super.key,
    required this.demo,
    required this.product,
  });
  final BuyerDemo demo;
  final DemoProduct product;
  @override
  State<_SavedProductRow> createState() => _SavedProductRowState();
}

class _SavedProductRowState extends State<_SavedProductRow> {
  bool _adding = false;
  Future<void> _add() async {
    if (!widget.demo.isSignedIn) {
      _signIn(context);
      return;
    }
    setState(() => _adding = true);
    try {
      await widget.demo.add(widget.product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} added to cart'),
            action: SnackBarAction(
              label: 'View cart',
              onPressed: () => _open(context, BuyerCart(demo: widget.demo)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(marketplaceError(e))));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final unavailable = product.stock != null && product.stock! <= 0;
    void details() => _open(
      context,
      BuyerProductDetails(demo: widget.demo, product: product),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: details,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: (constraints.maxWidth * .36).clamp(90.0, 190.0),
                child: AspectRatio(
                  aspectRatio: .85,
                  child: _ProductCardPhotos(product),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: details,
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (product.studio.isNotEmpty)
                    Text(
                      product.studio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  if (product.category.isNotEmpty)
                    Text(
                      product.category,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    product.priceLabel(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF222222),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      onPressed: _adding || unavailable ? null : _add,
                      child: Text(
                        _adding
                            ? 'Adding…'
                            : unavailable
                            ? 'Out of stock'
                            : 'Add to cart',
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Remove ${product.name} from saved',
                      onPressed: () => widget.demo.favorite(product),
                      icon: const Icon(Icons.favorite, color: _clay),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BuyerProfile extends StatelessWidget {
  const BuyerProfile({super.key, required this.demo});
  final BuyerDemo demo;
  @override
  Widget build(BuildContext context) => _BuyerPage(
    demo: demo,
    title: 'Collector Profile',
    requiresLogin: true,
    tab: 4,
    children: [
      CollectorProfileHeader(
        repository: demo.repository == null
            ? null
            : ProfileRepository(
                firestore: demo.repository!.db,
                auth: demo.repository!.auth,
              ),
      ),
      const SizedBox(height: 20),
      const _Heading('Collector Hub'),
      _Panel(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Saved pieces'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, BuyerFavorites(demo: demo)),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('My bag'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, BuyerCart(demo: demo)),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('My Orders'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(
                context,
                BuyerOrdersScreen(
                  demo: demo,
                  onDestinationSelected: (index) {
                    switch (index) {
                      case 0:
                        Navigator.of(context).popUntil(
                          (route) =>
                              route.settings.name == RouteNames.marketplace ||
                              route.isFirst,
                        );
                      case 1:
                        _open(context, BuyerSearch(demo: demo));
                      case 2:
                        _open(context, BuyerFavorites(demo: demo));
                      case 3:
                        _open(context, BuyerCart(demo: demo));
                      case 4:
                        Navigator.maybePop(context);
                    }
                  },
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: const Text('Discover makers and pieces'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, BuyerSearch(demo: demo)),
            ),
          ],
        ),
      ),
      const _Panel(
        child: Text(
          'A collection with meaning\nSupport independent makers and discover the story behind every piece.',
        ),
      ),
    ],
  );
}

class BuyerCheckout extends StatefulWidget {
  const BuyerCheckout({super.key, required this.demo, this.step = 0});
  final BuyerDemo demo;
  final int step;
  @override
  State<BuyerCheckout> createState() => _BuyerCheckoutState();
}

class _BuyerCheckoutState extends State<BuyerCheckout> {
  bool busy = false;
  Future<void> editAddress([Map<String, dynamic>? existing]) async {
    const keys = ['name', 'address', 'city', 'postalCode', 'country', 'phone'];
    const labels = [
      'Full name',
      'Street address',
      'City',
      'Postal code',
      'Country',
      'Phone number',
    ];
    final controllers = [
      for (final key in keys)
        TextEditingController(text: existing?[key] as String? ?? ''),
    ];
    final form = GlobalKey<FormState>();
    bool saving = false;
    String? failure;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'Add a new address' : 'Edit address',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < keys.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: controllers[i],
                        enabled: !saving,
                        maxLength: i == 1
                            ? 300
                            : i == 5
                            ? 40
                            : 100,
                        textInputAction: i == 5
                            ? TextInputAction.done
                            : TextInputAction.next,
                        keyboardType: i == 5
                            ? TextInputType.phone
                            : TextInputType.streetAddress,
                        decoration: InputDecoration(
                          labelText: labels[i],
                          counterText: '',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please complete this field.'
                            : null,
                      ),
                    ),
                  if (failure != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        failure!,
                        style: const TextStyle(color: _clay),
                      ),
                    ),
                  _Action(
                    saving ? 'Saving...' : 'Save address',
                    saving
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            update(() {
                              saving = true;
                              failure = null;
                            });
                            try {
                              await widget.demo.saveAddress({
                                for (var i = 0; i < keys.length; i++)
                                  keys[i]: controllers[i].text.trim(),
                              }, id: existing?['id'] as String?);
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                update(() {
                                  saving = false;
                                  failure = marketplaceError(e);
                                });
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Wait until the closing sheet has released its text fields.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Future<void> next() async {
    final d = widget.demo;
    if (busy ||
        d.checkingOut ||
        d.cart.isEmpty ||
        d.selectedAddressId == null) {
      return;
    }
    setState(() => busy = true);
    try {
      if (widget.step < 2) {
        await d.validateCheckout();
        if (mounted) {
          _open(context, BuyerCheckout(demo: d, step: widget.step + 1));
        }
      } else {
        final order = await d.checkout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => BuyerOrderSuccess(demo: d, order: order),
          ),
          (r) => r.settings.name == RouteNames.marketplace || r.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(marketplaceError(e))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.demo,
    builder: (context, _) {
      final d = widget.demo;
      final step = widget.step;
      return _BuyerPage(
        demo: d,
        title: 'Checkout',
        requiresLogin: true,
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (d.cart.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Order total',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                    Text(
                      money(d.total, d.currency),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            _Action(
              busy || d.checkingOut
                  ? 'Please wait...'
                  : [
                      'Continue to payment  \u2192',
                      'Continue to review  \u2192',
                      'Place order',
                    ][step],
              busy ||
                      d.checkingOut ||
                      d.cart.isEmpty ||
                      d.selectedAddressId == null ||
                      d.repository == null
                  ? null
                  : next,
            ),
          ],
        ),
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Divider(
                      color: i <= step
                          ? const Color(0xFF50745B)
                          : const Color(0xFFDAD7D4),
                    ),
                  ),
                SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: i < step
                            ? const Color(0xFF50745B)
                            : i == step
                            ? _clay
                            : const Color(0xFFECE9E5),
                        foregroundColor: i <= step ? Colors.white : Colors.grey,
                        child: i < step
                            ? const Icon(Icons.check, size: 18)
                            : Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 14),
                              ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ['Address', 'Payment', 'Review'][i],
                        style: TextStyle(
                          color: i == step ? _clay : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          _Heading(
            ['Delivery address', 'Payment method', 'Review your order'][step],
          ),
          Text(
            [
              'Choose where your order arrives.',
              'Choose how you\u2019d like to pay.',
              'Check your details before placing your order.',
            ][step],
            style: const TextStyle(color: Color(0xFF756861), fontSize: 17),
          ),
          const SizedBox(height: 14),
          if (d.cart.isEmpty)
            const _Panel(
              child: Text('Your bag is empty. Add a piece before continuing.'),
            ),
          if (step == 0) ...[
            if (d.addressesLoading)
              const Center(child: CircularProgressIndicator()),
            if (d.addressError != null) _Panel(child: Text(d.addressError!)),
            if (!d.addressesLoading &&
                d.addressError == null &&
                d.addresses.isEmpty)
              const _Panel(child: Text('No saved addresses yet.')),
            for (final address in d.addresses)
              _SelectionPanel(
                selected: address['id'] == d.selectedAddressId,
                onTap: () => d.selectAddress(address),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          address['id'] == d.selectedAddressId
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _clay,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => editAddress(address),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                    Text(
                      address['name'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${address['address']}\n${address['city']}, ${address['postalCode']}\n${address['country']}',
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(address['phone'] as String)),
                      ],
                    ),
                  ],
                ),
              ),
            _Panel(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add),
                title: const Text('Add a new address'),
                onTap: d.repository == null ? null : () => editAddress(),
              ),
            ),
            const SizedBox(height: 8),
            const _Heading('Delivery method'),
            _SelectionPanel(
              selected: true,
              child: Row(
                children: [
                  const Icon(Icons.radio_button_checked, color: _clay),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Standard',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  if (d.cart.isNotEmpty)
                    Text(
                      money(d.delivery, d.currency),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                ],
              ),
            ),
            _Panel(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('Delivery instructions'),
                subtitle: const Text('Optional'),
                children: [
                  TextFormField(
                    initialValue: d.instructions,
                    maxLength: 1000,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add instructions for your delivery',
                    ),
                    onChanged: (v) => d.instructions = v.trim(),
                  ),
                ],
              ),
            ),
          ],
          if (step >= 1) ...[
            if (step == 1)
              _Panel(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.credit_card_outlined, color: _clay),
                  title: const Text('Stripe card payment - Demo'),
                  subtitle: const Text(
                    'Preview only. No payment will be processed.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    useSafeArea: true,
                    builder: (sheetContext) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Stripe demo preview',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _SelectionPanel(
                              selected: true,
                              child: ListTile(
                                leading: Icon(Icons.credit_card),
                                title: Text('Sample card ending 4242'),
                                subtitle: Text(
                                  'Illustrative card - not a saved payment method',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'This preview is not connected to Stripe. No card details are collected, no charge is made, and no paid order is created. Use cash on delivery to place an order.',
                            ),
                            const SizedBox(height: 20),
                            _Action(
                              'Back to payment methods',
                              () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            _SelectionPanel(
              selected: true,
              child: const Row(
                children: [
                  Icon(Icons.radio_button_checked, color: _clay),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash on delivery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pay when your order arrives',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.payments_outlined),
                ],
              ),
            ),
            _Panel(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(
                  d.selectedAddressId == null
                      ? 'Choose a delivery address'
                      : 'Deliver to ${d.name} \u00b7 ${d.city}',
                ),
                subtitle: step == 2 ? Text(d.destination) : null,
                trailing: TextButton(
                  onPressed: () {
                    for (var i = 0; i < step; i++) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Change'),
                ),
              ),
            ),
            if (step == 2 && d.instructions.isNotEmpty)
              _Panel(child: Text(d.instructions)),
          ],
          if (d.cart.isNotEmpty)
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step >= 1) ...[
                    const Text(
                      'Order summary',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${d.count} items',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                  ],
                  for (final e in d.cart.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(width: 60, height: 60, child: _Photo(e.key)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.key.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Qty ${e.value}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            e.key.priceLabel(e.value),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  if (step >= 1)
                    _Amount('Subtotal', money(d.subtotal, d.currency)),
                  _Amount('Standard delivery', money(d.delivery, d.currency)),
                ],
              ),
            ),
          if (step == 1)
            const Text(
              'You\u2019ll review your order before placing it.',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      );
    },
  );
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.selected,
    required this.child,
    this.onTap,
  });
  final bool selected;
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? _clay : const Color(0xFFE5E2DF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    ),
  );
}

class BuyerOrders extends StatelessWidget {
  const BuyerOrders({super.key, required this.demo});
  final BuyerDemo demo;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (context, _) => _BuyerPage(
      demo: demo,
      title: 'My Orders',
      requiresLogin: true,
      children: [
        const _Eyebrow('COLLECTOR ORDERS'),
        const _Heading('Pieces on their way'),
        const Text(
          'Follow each studio consignment from confirmation to delivery.',
        ),
        for (final order in demo.orders)
          _Panel(
            child: InkWell(
              onTap: () =>
                  _open(context, BuyerOrderDetails(demo: demo, order: order)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 76,
                        height: 84,
                        child: _Photo(order.primaryProduct),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.primaryProduct.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.primaryProduct.studio,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${order.id} · ${order.date}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _BuyerOrderStatus(status: order.status),
                      const Spacer(),
                      Text(
                        money(order.total, order.currency),
                        style: const TextStyle(
                          color: AppColors.terracotta,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class BuyerOrderDetails extends StatelessWidget {
  const BuyerOrderDetails({super.key, required this.demo, required this.order});
  final BuyerDemo demo;
  final BuyerDemoOrder order;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (context, _) => _BuyerPage(
      demo: demo,
      title: 'Order Details',
      footer: CustomButton(
        label: 'Track Order',
        onPressed: () =>
            _open(context, BuyerOrderTracking(demo: demo, order: order)),
      ),
      children: [
        const _Eyebrow('ORDER REFERENCE'),
        _Heading(order.id),
        _BuyerOrderStatus(status: order.status),
        if (MarketplaceBackend.enabled &&
            order.status != BuyerOrderStatus.delivered &&
            order.status != BuyerOrderStatus.cancelled)
          DeliveryConfirmationCard(key: ValueKey(order.id), orderId: order.id),
        const SizedBox(height: 18),
        const _Heading('Consigned Pieces'),
        for (final entry in order.items.entries)
          _Panel(
            child: Row(
              children: [
                SizedBox(width: 70, height: 78, child: _Photo(entry.key)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${entry.key.name}\n${entry.key.artisan}\nQty: ${entry.value}',
                  ),
                ),
                Text(entry.key.priceLabel(entry.value)),
              ],
            ),
          ),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('DELIVERY ADDRESS'),
              const SizedBox(height: 8),
              Text(order.address),
              const SizedBox(height: 16),
              const _Eyebrow('PAYMENT METHOD'),
              const SizedBox(height: 8),
              Text(order.payment),
            ],
          ),
        ),
        const _Heading('Order Summary'),
        _Panel(
          child: Column(
            children: [
              _Amount(
                'Items subtotal (${order.count})',
                money(order.subtotal, order.currency),
              ),
              _Amount(
                'Delivery fee',
                order.deliveryFee == 0
                    ? 'Free'
                    : money(order.deliveryFee, order.currency),
              ),
              const Divider(),
              _Amount('Total', money(order.total, order.currency)),
            ],
          ),
        ),
      ],
    ),
  );
}

class BuyerOrderTracking extends StatelessWidget {
  const BuyerOrderTracking({
    super.key,
    required this.demo,
    required this.order,
  });
  final BuyerDemo demo;
  final BuyerDemoOrder order;
  static const _stages = [
    BuyerOrderStatus.pending,
    BuyerOrderStatus.confirmed,
    BuyerOrderStatus.courierAssigned,
    BuyerOrderStatus.pickedUp,
    BuyerOrderStatus.onTheWay,
    BuyerOrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (context, _) => _BuyerPage(
      demo: demo,
      title: 'Order Tracking',
      children: [
        const _Eyebrow('STUDIO CONSIGNMENT'),
        _Heading(order.id),
        Text(
          '${order.primaryProduct.name}\n${order.primaryProduct.studio}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        const _Heading('Delivery progress'),
        _Panel(
          child: Column(
            children: [
              if (order.status == BuyerOrderStatus.cancelled)
                const Text('Order cancelled'),
              if (order.status != BuyerOrderStatus.cancelled)
                for (var index = 0; index < _stages.length; index++) ...[
                  _TrackingStage(stage: _stages[index], current: order.status),
                  if (index < _stages.length - 1)
                    Container(
                      width: 2,
                      height: 24,
                      color: index < order.status.index
                          ? AppColors.terracotta
                          : const Color(0xFFE5DCD4),
                    ),
                ],
            ],
          ),
        ),
        if (order.status != BuyerOrderStatus.cancelled &&
            order.status.index >= BuyerOrderStatus.courierAssigned.index)
          _Panel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.sage,
                ),
              ),
              title: const Text('Assigned Guild Courier'),
              subtitle: const Text(
                'Your handcrafted parcel is being handled with care.',
              ),
            ),
          ),
        const _Panel(
          child: Text(
            'Order status updates appear here as your parcel moves through delivery.',
          ),
        ),
      ],
    ),
  );
}

class _BuyerOrderStatus extends StatelessWidget {
  const _BuyerOrderStatus({required this.status});
  final BuyerOrderStatus status;
  @override
  Widget build(BuildContext context) {
    final color = status == BuyerOrderStatus.delivered
        ? AppColors.sage
        : AppColors.terracotta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TrackingStage extends StatelessWidget {
  const _TrackingStage({required this.stage, required this.current});
  final BuyerOrderStatus stage, current;
  @override
  Widget build(BuildContext context) {
    final done = stage.index <= current.index;
    final active = stage == current;
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppColors.terracotta : AppColors.muted,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            stage.label,
            style: TextStyle(
              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              color: active ? AppColors.terracotta : AppColors.ink,
            ),
          ),
        ),
        if (active)
          const Text(
            'Current',
            style: TextStyle(fontSize: 12, color: AppColors.terracotta),
          ),
      ],
    );
  }
}

class BuyerOrderSuccess extends StatelessWidget {
  const BuyerOrderSuccess({super.key, required this.demo, required this.order});
  final BuyerDemo demo;
  final BuyerDemoOrder order;
  @override
  Widget build(BuildContext context) => _BuyerPage(
    demo: demo,
    title: 'Order Successful',
    children: [
      const Icon(Icons.check_circle, color: AppColors.sage, size: 80),
      const SizedBox(height: 20),
      const _Eyebrow('THANK YOU FOR CHAMPIONING SLOW CRAFT'),
      const _Heading('Your order successfully placed'),
      const Text('Your order has been submitted. Pay cash on delivery.'),
      for (final e in order.items.entries)
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Photo(e.key, height: 200),
              const SizedBox(height: 12),
              Text(e.key.name),
              _Amount('Quantity: ${e.value}', e.key.priceLabel(e.value)),
            ],
          ),
        ),
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Amount(
              'Total · delivery included',
              money(order.total, order.currency),
            ),
            const Divider(),
            const _Eyebrow('DELIVERY LOCATION'),
            Text(demo.destination),
            const SizedBox(height: 10),
            Text('Order status: ${order.status.label}'),
          ],
        ),
      ),
      CustomButton(
        label: 'Track Order',
        onPressed: () => _open(
          context,
          BuyerOrderDetailsScreen(demo: demo, orderId: order.id),
        ),
      ),
      TextButton(
        child: const Text('Back to dashboard'),
        onPressed: () => Navigator.popUntil(
          context,
          (r) => r.settings.name == RouteNames.marketplace || r.isFirst,
        ),
      ),
    ],
  );
}
