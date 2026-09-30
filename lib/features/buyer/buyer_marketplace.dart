import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/route_names.dart';
import '../../shared/models/craftisan_demo_messages.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/craftisan_messaging.dart';
import 'buyer_demo.dart';

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

class BuyerMarketplace extends StatefulWidget {
  const BuyerMarketplace({super.key});
  @override
  State<BuyerMarketplace> createState() => _BuyerMarketplaceState();
}

class _BuyerMarketplaceState extends State<BuyerMarketplace> {
  final demo = BuyerDemo();
  @override
  void dispose() {
    demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _BuyerPage(
    demo: demo,
    title: 'Craftisan',
    tab: 0,
    children: [
      const _Eyebrow('HANDMADE & SMALL BATCH'),
      const _Heading('Hello! what are you looking for?'),
      const SizedBox(height: 20),
      TextField(
        readOnly: true,
        onTap: () => _open(context, BuyerSearch(demo: demo)),
        decoration: const InputDecoration(
          hintText: 'Search products',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.tune),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      const SizedBox(height: 24),
      const _Heading('Browse categories'),
      const _Eyebrow('CURATED BY MATERIAL & CLAY BODIES'),
      for (final p in demoProducts)
        _Panel(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(width: 66, height: 66, child: _Photo(p)),
            title: Text(p.category),
            subtitle: Text(p.studio),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () =>
                _open(context, BuyerSearch(demo: demo, category: p.category)),
          ),
        ),
      const SizedBox(height: 16),
      const _Eyebrow('MOST CHERISHED THIS WEEK'),
      const _Heading('Popular Today'),
      for (final p in demoProducts) _ProductCard(demo: demo, product: p),
      const _Panel(
        child: Text(
          '“Every ridge on this vessel is carved by hand while the clay rests leather-hard.”\n\n— From the artisan’s workbench',
        ),
      ),
    ],
  );
}

class _BuyerPage extends StatelessWidget {
  const _BuyerPage({
    required this.demo,
    required this.title,
    required this.children,
    this.tab,
    this.footer,
  });
  final BuyerDemo demo;
  final String title;
  final List<Widget> children;
  final int? tab;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineLarge
            ?.copyWith(fontSize: 26),
      ),
      backgroundColor: AppColors.background,
      actions: [
        ListenableBuilder(
          listenable: demo,
          builder: (context, _) => IconButton(
            tooltip: 'Cart (${demo.count})',
            icon: Badge(
              label: Text('${demo.count}'),
              isLabelVisible: demo.count > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () => _open(context, BuyerCart(demo: demo)),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: children,
          ),
        ),
      ),
    ),
    bottomNavigationBar: footer != null
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: footer,
            ),
          )
        : tab == null
        ? null
        : NavigationBar(
            selectedIndex: tab!,
            backgroundColor: AppColors.background,
            indicatorColor: AppColors.terracotta.withValues(alpha: .12),
            onDestinationSelected: (index) {
              if (index == tab) return;
              if (index == 0) {
                Navigator.popUntil(
                  context,
                  (r) => r.settings.name == RouteNames.marketplace || r.isFirst,
                );
              } else {
                final screen = switch (index) {
                  1 => BuyerSearch(demo: demo),
                  2 => BuyerFavorites(demo: demo),
                  _ => BuyerProfile(demo: demo),
                };
                if (tab == 0) {
                  _open(context, screen);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(builder: (_) => screen),
                  );
                }
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                label: 'Explore',
              ),
              NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline),
                label: 'Favorites',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
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
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

class _Photo extends StatelessWidget {
  const _Photo(this.product, {this.height});
  final DemoProduct product;
  final double? height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Image.memory(
      product.image,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      semanticLabel: product.name,
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.demo, required this.product});
  final BuyerDemo demo;
  final DemoProduct product;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () =>
              _open(context, BuyerProductDetails(demo: demo, product: product)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _Photo(product, height: 250),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _FavoriteButton(demo: demo, product: product),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Eyebrow(product.studio.toUpperCase()),
              _Heading(product.name),
              Text(
                money(product.price),
                style: const TextStyle(
                  color: AppColors.terracotta,
                  fontSize: 22,
                ),
              ),
              Text(
                product.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CustomButton(
          label: 'View piece',
          onPressed: () =>
              _open(context, BuyerProductDetails(demo: demo, product: product)),
        ),
      ],
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
  const BuyerSearch({super.key, required this.demo, this.category = 'All'});
  final BuyerDemo demo;
  final String category;
  @override
  State<BuyerSearch> createState() => _BuyerSearchState();
}

class _BuyerSearchState extends State<BuyerSearch> {
  final query = TextEditingController();
  late String category = widget.category;
  String location = 'All';
  String artisan = 'All';
  RangeValues prices = const RangeValues(0, 200);
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = demoProducts
        .where(
          (p) =>
              (category == 'All' || p.category == category) &&
              (location == 'All' || p.location == location) &&
              (artisan == 'All' || p.artisan == artisan) &&
              p.price >= prices.start &&
              p.price <= prices.end &&
              '${p.name} ${p.category} ${p.artisan} ${p.studio} ${p.location}'
                  .toLowerCase()
                  .contains(query.text.trim().toLowerCase()),
        )
        .toList();
    final active =
        (category == 'All' ? 0 : 1) +
        (location == 'All' ? 0 : 1) +
        (artisan == 'All' ? 0 : 1) +
        (prices.start > 0 || prices.end < 200 ? 1 : 0);
    return _BuyerPage(
      demo: widget.demo,
      title: 'Search results',
      tab: 1,
      children: [
        TextField(
          controller: query,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search products',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        _Heading('${results.length} pieces found'),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter Artifacts · $active active',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      category = 'All';
                      location = 'All';
                      artisan = 'All';
                      prices = const RangeValues(0, 200);
                    }),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const _Eyebrow('CATEGORY'),
              Wrap(
                spacing: 8,
                children: ['All', ...demoProducts.map((p) => p.category)]
                    .map(
                      (c) => ChoiceChip(
                        label: Text(c),
                        selected: c == category,
                        selectedColor: AppColors.terracotta.withValues(
                          alpha: .18,
                        ),
                        onSelected: (_) => setState(() => category = c),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const _Eyebrow('LOCATION'),
              Wrap(
                spacing: 8,
                children: ['All', 'Colombo', 'Kandy', 'Galle', 'Matara']
                    .map(
                      (value) => ChoiceChip(
                        label: Text(value),
                        selected: value == location,
                        selectedColor: AppColors.terracotta.withValues(
                          alpha: .18,
                        ),
                        onSelected: (_) => setState(() => location = value),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const _Eyebrow('ARTISAN'),
              Wrap(
                spacing: 8,
                children: ['All', ...buyerArtisans.map((a) => a.name)]
                    .map(
                      (value) => ChoiceChip(
                        label: Text(value),
                        selected: value == artisan,
                        selectedColor: AppColors.terracotta.withValues(
                          alpha: .18,
                        ),
                        onSelected: (_) => setState(() => artisan = value),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _Eyebrow(
                'PRICE RANGE · ${money(prices.start)} – ${money(prices.end)}',
              ),
              RangeSlider(
                values: prices,
                min: 0,
                max: 200,
                divisions: 20,
                labels: RangeLabels(money(prices.start), money(prices.end)),
                onChanged: (v) => setState(() => prices = v),
              ),
              const Text('Filters update results immediately.'),
            ],
          ),
        ),
        if (results.isEmpty)
          const _Panel(
            child: Text(
              'No pieces match. Try another search or clear your filters.',
            ),
          ),
        for (final p in results) _ProductCard(demo: widget.demo, product: p),
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
  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return _BuyerPage(
      demo: widget.demo,
      title: 'Product Detail',
      footer: CustomButton(
        label: 'Add to Cart · ${money(p.price * quantity)}',
        onPressed: () {
          widget.demo.add(p, quantity);
          _open(context, BuyerCart(demo: widget.demo));
        },
      ),
      children: [
        Stack(
          children: [
            _Photo(p, height: 360),
            Positioned(
              right: 10,
              top: 10,
              child: _FavoriteButton(demo: widget.demo, product: p),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _Eyebrow('NATURAL CLAY & EARTH · STUDIO BATCH'),
        _Heading(p.name),
        Text(
          '${money(p.price)} / unique edition',
          style: const TextStyle(color: AppColors.terracotta, fontSize: 22),
        ),
        _Panel(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.surface,
              child: Icon(Icons.palette_outlined, color: AppColors.sage),
            ),
            title: Text(p.artisan),
            subtitle: Text('${p.studio}\nGuild Member · ★ 4.9 (38)'),
            trailing: TextButton(
              onPressed: () => _open(
                context,
                BuyerArtisanProfile(
                  demo: widget.demo,
                  artisan: artisanFor(p.artisan),
                  avatarProduct: p,
                ),
              ),
              child: const Text('View Artisan'),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _open(
              context,
              const CraftisanConversationScreen(
                viewer: DemoMessageAuthor.buyer,
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Message Artisan'),
          ),
        ),
        const _Heading('Material & Lineage'),
        Text(p.description, style: Theme.of(context).textTheme.bodyLarge),
        const _Panel(
          child: Text(
            'Small-batch craft\nHand-finished natural clay · Each piece is unique\nMaker provenance card included',
          ),
        ),
        _Panel(
          child: Row(
            children: [
              const Expanded(child: Text('Quantity')),
              _Quantity(
                value: quantity,
                onChanged: (v) {
                  if (v > 0) setState(() => quantity = v);
                },
              ),
            ],
          ),
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (context, _) {
      final following = demo.followedArtisans.contains(artisan.name);
      final products = demoProducts
          .where((product) => product.artisan == artisan.name)
          .toList();
      return _BuyerPage(
        demo: demo,
        title: 'Artisan Profile',
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundImage: MemoryImage(avatarProduct.image),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: _Heading(artisan.name)),
          Center(child: Text(artisan.studio)),
          const SizedBox(height: 8),
          const Center(
            child: Chip(
              avatar: Icon(Icons.verified, color: AppColors.sage, size: 18),
              label: Text('Verified Guild Artisan'),
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
              const CraftisanConversationScreen(
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
                          Text(money(product.price)),
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
    builder: (context, _) => _BuyerPage(
      demo: demo,
      title: 'Atelier Bag (${demo.count} pieces)',
      footer: demo.cart.isEmpty
          ? null
          : CustomButton(
              label: 'Proceed to Checkout · ${money(demo.total)}',
              onPressed: () => _open(context, BuyerCheckout(demo: demo)),
            ),
      children: [
        const _Eyebrow('STUDIO SELECTIONS'),
        if (demo.cart.isEmpty) ...[
          const _Heading('Your bag is waiting for a story'),
          const Text('Discover a handmade piece to begin your collection.'),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Explore pieces',
            onPressed: () => Navigator.popUntil(
              context,
              (r) => r.settings.name == RouteNames.marketplace || r.isFirst,
            ),
          ),
        ],
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
                            Text('${money(entry.key.price)} each'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: Text(money(entry.key.price * entry.value))),
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
              'Studio Packaging\nHand-packed with recyclable wrap and a maker provenance card. Complimentary delivery on orders of \$250 or more.',
            ),
          ),
          _Totals(demo),
        ],
      ],
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
        _Amount('Items subtotal (${demo.count})', money(demo.subtotal)),
        const _Amount('Studio packaging', 'Included'),
        _Amount('Delivery', demo.delivery == 0 ? 'Free' : money(demo.delivery)),
        const _Amount('Tax', 'Included in prices'),
        const Divider(),
        _Amount('Total', money(demo.total)),
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

class BuyerFavorites extends StatelessWidget {
  const BuyerFavorites({super.key, required this.demo});
  final BuyerDemo demo;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (_, _) => _BuyerPage(
      demo: demo,
      title: 'Favorites',
      tab: 2,
      children: [
        const _Eyebrow('BUYER COLLECTION'),
        const _Heading('Curated Atelier Pieces'),
        Text('${demo.favorites.length} saved pieces from independent makers.'),
        if (demo.favorites.isEmpty)
          const _Panel(
            child: Text('Tap the heart on a piece to save it here.'),
          ),
        for (final p in demo.favorites) _ProductCard(demo: demo, product: p),
      ],
    ),
  );
}

class BuyerProfile extends StatelessWidget {
  const BuyerProfile({super.key, required this.demo});
  final BuyerDemo demo;
  @override
  Widget build(BuildContext context) => _BuyerPage(
    demo: demo,
    title: 'Collector Profile',
    tab: 3,
    children: [
      const Center(
        child: CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.surface,
          child: Icon(
            Icons.person_outline,
            size: 40,
            color: AppColors.terracotta,
          ),
        ),
      ),
      const SizedBox(height: 20),
      const _Eyebrow('GUILD PATRON · DEMO COLLECTOR'),
      const _Heading('Clara Lindqvist'),
      const Text(
        'Curating organic stoneware, tea bowls, and wood-fired ceramics from independent studios.',
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
              onTap: () => _open(context, BuyerOrders(demo: demo)),
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
  final form = GlobalKey<FormState>();
  late final fields = [
    widget.demo.name,
    widget.demo.address,
    widget.demo.city,
    widget.demo.postalCode,
    widget.demo.country,
    widget.demo.phone,
    widget.demo.instructions,
  ].map((v) => TextEditingController(text: v)).toList();
  late String payment = widget.demo.payment;
  @override
  void dispose() {
    for (final c in fields) {
      c.dispose();
    }
    super.dispose();
  }

  void next() {
    final d = widget.demo;
    if (d.cart.isEmpty) return;
    if (widget.step == 0) {
      if (!form.currentState!.validate()) return;
      d.name = fields[0].text.trim();
      d.address = fields[1].text.trim();
      d.city = fields[2].text.trim();
      d.postalCode = fields[3].text.trim();
      d.country = fields[4].text.trim();
      d.phone = fields[5].text.trim();
      d.instructions = fields[6].text.trim();
    }
    if (widget.step == 1) d.payment = payment;
    if (widget.step < 2) {
      _open(context, BuyerCheckout(demo: d, step: widget.step + 1));
    } else {
      final receipt = Map<DemoProduct, int>.of(d.cart);
      final total = d.total;
      final order = d.createOrder(receipt, total);
      d.clearCart();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => BuyerOrderSuccess(demo: d, order: order),
        ),
        (r) => r.settings.name == RouteNames.marketplace || r.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.demo;
    final step = widget.step;
    const labels = ['Address', 'Payment', 'Review'];
    return ListenableBuilder(
      listenable: d,
      builder: (context, _) => _BuyerPage(
        demo: d,
        title: 'Secure Checkout',
        footer: d.cart.isEmpty
            ? null
            : CustomButton(
                label: step == 2
                    ? 'Place Order · ${money(d.total)}'
                    : 'Continue to ${labels[step + 1]}',
                onPressed: next,
              ),
        children: [
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: i <= step
                          ? AppColors.terracotta
                          : AppColors.surface,
                      foregroundColor: i <= step
                          ? Colors.white
                          : AppColors.muted,
                      child: i < step
                          ? const Icon(Icons.check)
                          : Text('${i + 1}'),
                    ),
                    const SizedBox(height: 8),
                    Text(labels[i]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _Eyebrow('STEP ${step + 1} OF 3'),
          _Heading(
            [
              'Address Details',
              'Payment methods',
              'Review & Place Order',
            ][step],
          ),
          if (d.cart.isEmpty)
            const _Panel(
              child: Text('Your bag is empty. Add a piece before continuing.'),
            ),
          if (step == 0) ...[
            const Text(
              'Where should your hand-packaged studio items journey to?',
            ),
            Form(
              key: form,
              child: _Panel(
                child: Column(
                  children: List.generate(
                    fields.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CustomTextField(
                        label: const [
                          'Full name',
                          'Street address',
                          'City / Region',
                          'Postal code',
                          'Country',
                          'Phone number',
                          'Delivery instructions (optional)',
                        ][i],
                        controller: fields[i],
                        icon: i == 5
                            ? Icons.phone_outlined
                            : Icons.location_on_outlined,
                        keyboardType: i == 5
                            ? TextInputType.phone
                            : TextInputType.text,
                        validator: i == 6
                            ? null
                            : (v) => v == null || v.trim().isEmpty
                                  ? 'Please complete this field.'
                                  : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const _Panel(
              child: Text(
                'Studio Packaging Guarantee\nEvery piece is secured in recyclable wrap with maker sign-off seals.',
              ),
            ),
          ],
          if (step == 1) ...[
            const Text('Choose a payment method for this demo order.'),
            for (final method in [
              'Cash on delivery',
              'Demo Visa ending in 4092',
              'Studio Guild Credits',
            ])
              _Panel(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    payment == method
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: AppColors.terracotta,
                  ),
                  title: Text(method),
                  subtitle: Text(
                    method == 'Cash on delivery'
                        ? 'Pay upon receipt and unboxing'
                        : method == 'Studio Guild Credits'
                        ? 'Demo balance: \$140.00'
                        : 'Sample card · No charge will be made',
                  ),
                  selected: payment == method,
                  onTap: method == 'Studio Guild Credits' && d.total > 140
                      ? null
                      : () => setState(() => payment = method),
                  trailing: method == 'Studio Guild Credits' && d.total > 140
                      ? const Text('Insufficient\ncredits')
                      : null,
                ),
              ),
            const _Panel(
              child: Text(
                'UI preview only. No payment details are collected and no payment is processed.',
              ),
            ),
          ],
          if (step == 2) ...[
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Shipping Destination',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back to payment'),
                      ),
                    ],
                  ),
                  Text(d.destination),
                  if (d.instructions.isNotEmpty) Text('\n${d.instructions}'),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Change address'),
                  ),
                ],
              ),
            ),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Eyebrow('PAYMENT METHOD'),
                  Text(d.payment),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Change payment'),
                  ),
                ],
              ),
            ),
            const _Panel(
              child: Text(
                'Courier & Handling\nStandard delivery · Estimated 3–5 business days',
              ),
            ),
            const _Heading('Consigned Pieces'),
            for (final e in d.cart.entries)
              _Panel(
                child: Row(
                  children: [
                    SizedBox(width: 64, height: 76, child: _Photo(e.key)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${e.key.name}\n${e.key.artisan}\nQty: ${e.value}',
                      ),
                    ),
                    Text(money(e.key.price * e.value)),
                  ],
                ),
              ),
            _Totals(d),
            const Text(
              'Demo order only · No charge will be made.',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
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
                        money(order.total),
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
  Widget build(BuildContext context) => _BuyerPage(
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
              Text(money(entry.key.price * entry.value)),
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
            _Amount('Items subtotal (${order.count})', money(order.subtotal)),
            _Amount(
              'Delivery fee',
              order.deliveryFee == 0 ? 'Free' : money(order.deliveryFee),
            ),
            const Divider(),
            _Amount('Total', money(order.total)),
          ],
        ),
      ),
    ],
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
  static const _stages = BuyerOrderStatus.values;

  @override
  Widget build(BuildContext context) => _BuyerPage(
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
      if (order.status.index >= BuyerOrderStatus.courierAssigned.index)
        _Panel(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.surface,
              child: Icon(Icons.local_shipping_outlined, color: AppColors.sage),
            ),
            title: const Text('Guild Courier · Marco V.'),
            subtitle: const Text(
              'Demo dispatch contact\nYour handcrafted parcel is being handled with care.',
            ),
          ),
        ),
      const _Panel(
        child: Text(
          'Tracking is a static demo preview. No location services or live delivery updates are connected.',
        ),
      ),
    ],
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
      const Text(
        'Demo confirmation · No payment was taken.\nYour pieces would be hand-packaged with care.',
      ),
      for (final e in order.items.entries)
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Photo(e.key, height: 200),
              const SizedBox(height: 12),
              Text(e.key.name),
              _Amount('Quantity: ${e.value}', money(e.key.price * e.value)),
            ],
          ),
        ),
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Amount('Total · delivery included', money(order.total)),
            const Divider(),
            const _Eyebrow('DELIVERY LOCATION'),
            Text(demo.destination),
            const SizedBox(height: 10),
            const Text('Standard Courier · 3–5 business days'),
          ],
        ),
      ),
      CustomButton(
        label: 'Track Order',
        onPressed: () =>
            _open(context, BuyerOrderTracking(demo: demo, order: order)),
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
