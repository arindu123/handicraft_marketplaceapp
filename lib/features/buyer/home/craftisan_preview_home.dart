import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../craftisan_home_hero.dart';
import 'home_preview_data.dart';
import 'home_preview_widgets.dart';

/// The existing home route's local presentation mode. No repository or Firebase
/// objects are created here. A catalogue adapter can be injected later.
class CraftisanPreviewHome extends StatefulWidget {
  const CraftisanPreviewHome({
    super.key,
    this.source = const LocalHomeCatalogue(),
  });
  final HomeCatalogueSource source;
  @override
  State<CraftisanPreviewHome> createState() => _CraftisanPreviewHomeState();
}

class _CraftisanPreviewHomeState extends State<CraftisanPreviewHome> {
  final _scroll = ScrollController();
  final _saved = <String>{};
  final _cart = <String, int>{};
  bool _collected = false, _showPromo = true;
  int _tab = 0, _visible = 4, _unread = 2;
  List<HomePreviewProduct> get _products => widget.source.products;
  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMore);
  }

  void _loadMore() {
    if (_scroll.position.extentAfter < 320 && _visible < _products.length) {
      setState(() => _visible = (_visible + 4).clamp(0, _products.length));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  void _toggle(HomePreviewProduct product) => setState(() {
    if (!_saved.add(product.id)) _saved.remove(product.id);
  });
  void _vouchers() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        child: StatefulBuilder(
          builder: (context, update) => HomeVoucherCard(
            collected: _collected,
            onCollect: () {
              setState(() => _collected = true);
              update(() {});
            },
          ),
        ),
      ),
    ),
  );
  void _detail(HomePreviewProduct product) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  product.asset,
                  height: 230,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.priceLabel,
                style: const TextStyle(
                  fontSize: 22,
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Local catalogue preview. Prices, discounts, ratings and sales counts are sample data. No order or payment will be placed.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(
                    () => _cart.update(
                      product.id,
                      (n) => n + 1,
                      ifAbsent: () => 1,
                    ),
                  );
                  Navigator.pop(context);
                  _message('Added to your preview bag');
                },
                child: const Text('Add to preview bag'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _browse({String query = '', String? category}) {
    final results = _products
        .where(
          (p) =>
              (category == null || p.category == category) &&
              p.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              category ??
                  (query.isEmpty ? 'All handmade pieces' : 'Search: $query'),
            ),
          ),
          body: results.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No sample pieces in this collection yet. Try Pottery or Home Decor.',
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final product = results[i];
                    return ListTile(
                      leading: Image.asset(
                        product.asset,
                        width: 52,
                        fit: BoxFit.cover,
                      ),
                      title: Text(product.name),
                      subtitle: Text(product.priceLabel),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _detail(product),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _card(HomePreviewProduct product) => HomeProductCard(
    product: product,
    saved: _saved.contains(product.id),
    onSave: () => _toggle(product),
    onTap: () => _detail(product),
  );

  Widget _home() => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final width = ((constraints.maxWidth - 44) / 2).clamp(130.0, 240.0);
      return CustomScrollView(
        controller: _scroll,
        key: const PageStorageKey('preview-home'),
        slivers: [
          SliverToBoxAdapter(
            child: CraftisanHomeHero(
              preview: true,
              onExplore: () => _browse(),
              onSearch: (query) => _browse(query: query),
              header: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Craftisan',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cart',
                          onPressed: () => setState(() => _tab = 2),
                          icon: const Icon(Icons.shopping_bag_outlined),
                        ),
                        IconButton(
                          tooltip: 'Account',
                          onPressed: () => setState(() => _tab = 3),
                          icon: const CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.surface,
                            child: Icon(Icons.person_outline, size: 20),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _message(
                        'Delivery address selection will connect when checkout is enabled.',
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Choose delivery address',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          DecoratedSliver(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: HomeCategoryRow(
                    onCategory: (category) => category == 'Free Shipping'
                        ? _vouchers()
                        : _browse(
                            category: category == 'New' ? null : category,
                          ),
                    onEvent: _vouchers,
                  ),
                ),
                SliverToBoxAdapter(
                  child: HomeSectionHeader(
                    'Claim Voucher to Save More',
                    action: 'More vouchers',
                    onTap: _vouchers,
                  ),
                ),
                SliverToBoxAdapter(
                  child: HomeVoucherCard(
                    collected: _collected,
                    onCollect: () => setState(() => _collected = true),
                  ),
                ),
                SliverToBoxAdapter(
                  child: HomeEventBanner(onTap: () => _browse()),
                ),
                SliverToBoxAdapter(
                  child: HomeSectionHeader(
                    'Flash Sale',
                    icon: Icons.bolt,
                    action: 'Shop More',
                    onTap: () => _browse(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: width + 155 * scale + 16,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _products.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) =>
                          SizedBox(width: width, child: _card(_products[i])),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: HomeSectionHeader(
                    'Artisan Picks',
                    onTap: () => _browse(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final cellWidth = (constraints.crossAxisExtent - 12) / 2;
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          mainAxisExtent: cellWidth + 155 * scale + 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _card(_products[i]),
                          childCount: _visible.clamp(0, _products.length),
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      children: [
                        if (_visible < _products.length)
                          TextButton(
                            onPressed: () => setState(
                              () => _visible = (_visible + 4).clamp(
                                0,
                                _products.length,
                              ),
                            ),
                            child: const Text('Discover more pieces'),
                          ),
                        const Text(
                          'Preview catalogue - sample prices, ratings and offers',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _otherTab() => CustomScrollView(
    slivers: [
      SliverAppBar(
        title: Text(['For You', 'Messages', 'Your Bag', 'Account'][_tab]),
        backgroundColor: AppColors.background,
      ),
      if (_tab == 1)
        SliverToBoxAdapter(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.chat_bubble_outline),
                title: Text('Your artisan conversations'),
                subtitle: Text('Preview inbox - no live messages are loaded.'),
              ),
              ListTile(
                title: const Text('Welcome to Craftisan'),
                subtitle: const Text(
                  'Discover the stories behind handmade pieces.',
                ),
                onTap: () =>
                    _message('Welcome! This is a local preview conversation.'),
              ),
              ListTile(
                title: const Text('Meet the makers'),
                subtitle: const Text('Thoughtfully made, thoughtfully chosen.'),
                onTap: () => _message(
                  'Live artisan messaging remains available in the connected marketplace.',
                ),
              ),
            ],
          ),
        ),
      if (_tab == 2) ...[
        if (_cart.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Your preview bag is empty. Explore a piece to add it.',
              ),
            ),
          ),
        SliverList.builder(
          itemCount: _cart.length,
          itemBuilder: (context, i) {
            final id = _cart.keys.elementAt(i);
            final product = _products.firstWhere((p) => p.id == id);
            return ListTile(
              leading: Image.asset(product.asset, width: 48, fit: BoxFit.cover),
              title: Text(product.name),
              subtitle: Text('${product.priceLabel} Ã— ${_cart[id]}'),
              trailing: IconButton(
                tooltip: 'Remove item',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _cart.remove(id)),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Preview only - checkout is not connected.'),
          ),
        ),
      ],
      if (_tab == 3) ...[
        const SliverToBoxAdapter(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text('Craftisan collector'),
            subtitle: Text('Local preview account'),
          ),
        ),
        SliverToBoxAdapter(
          child: ListTile(
            title: Text('Favourites (${_saved.length})'),
            leading: const Icon(Icons.favorite_border),
          ),
        ),
        SliverList.builder(
          itemCount: _saved.length,
          itemBuilder: (context, i) {
            final product = _products.firstWhere(
              (p) => p.id == _saved.elementAt(i),
            );
            return ListTile(
              title: Text(product.name),
              subtitle: Text(product.priceLabel),
              onTap: () => _detail(product),
            );
          },
        ),
        SliverToBoxAdapter(
          child: ListTile(
            title: const Text('Collected vouchers'),
            leading: const Icon(Icons.confirmation_number_outlined),
            onTap: _vouchers,
          ),
        ),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: AppColors.warmBrown,
        surface: AppColors.background,
        onSurface: AppColors.ink,
      ),
      textTheme: Theme.of(context).textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.warmBrown,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ),
    child: Scaffold(
      backgroundColor: AppColors.heroCream,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab == 0 ? 0 : 1,
          children: [
            TickerMode(enabled: _tab == 0, child: _home()),
            Material(color: AppColors.background, child: _otherTab()),
          ],
        ),
      ),
      floatingActionButton: _showPromo && _tab == 0
          ? HomeFloatingPromo(
              onClose: () => setState(() => _showPromo = false),
              onTap: _vouchers,
            )
          : null,
      bottomNavigationBar: HomeBottomNav(
        selected: _tab,
        cartCount: _cartCount,
        unread: _unread,
        onSelect: (tab) => setState(() {
          _tab = tab;
          if (tab == 1) _unread = 0;
        }),
      ),
    ),
  );
}
