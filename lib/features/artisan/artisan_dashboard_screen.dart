import 'artisan_orders_widgets.dart';
import 'artisan_dashboard_widgets.dart';

import '../../shared/data/community_repository.dart';

import 'package:image_picker/image_picker.dart';

import '../../shared/data/marketplace_repository.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/route_names.dart';
import '../../shared/models/craftisan_demo_messages.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/craftisan_messaging.dart';
import '../auth/models/marketplace_role.dart';
import 'artisan_demo.dart';

void _open(BuildContext context, Widget page) =>
    Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page));
void _dashboard(BuildContext context) => Navigator.popUntil(
  context,
  (r) => r.settings.name == RouteNames.marketplace || r.isFirst,
);

class ArtisanDashboardScreen extends StatefulWidget {
  const ArtisanDashboardScreen({super.key, this.backend});
  final MarketplaceRepository? backend;
  @override
  State<ArtisanDashboardScreen> createState() => _ArtisanDashboardScreenState();
}

class _ArtisanDashboardScreenState extends State<ArtisanDashboardScreen> {
  late final demo = ArtisanDemo(backend: widget.backend);
  final _search = TextEditingController();
  String _filter = 'All';
  String get _query => _search.text.trim().toLowerCase();
  bool _matches(ArtisanProduct p) =>
      '${p.name} ${p.category} ${p.id}'.toLowerCase().contains(_query);
  @override
  void initState() {
    super.initState();
    demo.addListener(_showError);
  }

  void _showError() {
    if (mounted && demo.error != null) {
      final message = demo.error!;
      demo.error = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      });
    }
  }

  int tab = 0;
  @override
  void dispose() {
    _search.dispose();
    demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (context, _) => _Page(
      hideAppBar: true,
      onRefresh: _refreshDashboard,
      back: () => Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.roleSelection,
        (_) => false,
        arguments: AuthEntry.signIn,
      ),
      title: const [
        'Artisan Dashboard',
        'My Products',
        'Artisan Orders',
        'Artisan Profile',
      ][tab],
      actions: [
        IconButton(
          tooltip: 'Messages',
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => _open(
            context,
            const CraftisanMessagesInbox(viewer: DemoMessageAuthor.artisan),
          ),
        ),
      ],
      navigation: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: studioBlush,
            indicatorColor: const Color(0xFFF8D2C4),
            elevation: 0,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 11,
                color: states.contains(WidgetState.selected)
                    ? studioClay
                    : AppColors.muted,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? studioClay
                    : AppColors.muted,
              ),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                label: 'Products',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      children: [
        ArtisanStudioHeader(
          demo: demo,
          onProfile: () => setState(() => tab = 3),
          onNotifications: () => setState(() => tab = 2),
          onMessages: () => _open(
            context,
            const CraftisanMessagesInbox(viewer: DemoMessageAuthor.artisan),
          ),
        ),
        const SizedBox(height: 24),
        if (demo.repository == null)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Preview mode · Sample catalogue',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ...switch (tab) {
          0 => [
            Text(
              _greeting,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                letterSpacing: 1.6,
              ),
            ),
            _Heading(
              demo.profileLoading
                  ? 'Loading your studio…'
                  : 'Welcome back,\n${demo.artisanName}',
            ),
            _searchBar(),
            ArtisanStudioHero(
              onAdd: () => _open(context, ArtisanProductForm(demo: demo)),
            ),
            ArtisanStudioStats(demo: demo),
            if (demo.ordersLoading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              ),
            if (demo.ordersError != null) _Card(child: Text(demo.ordersError!)),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: _Heading('My Products')),
                TextButton(
                  onPressed: () => setState(() => tab = 1),
                  child: const Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('View All'),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            ..._productList(limit: _query.isEmpty ? 3 : null),
            if (_query.isNotEmpty) ...[
              const _Heading('Matching Orders'),
              if (_matchingOrders.isEmpty)
                const _Card(child: Text('No orders match your search.')),
              ..._matchingOrders.map(
                (o) => _Card(
                  child: ListTile(
                    title: Text('#${o.id}'),
                    subtitle: Text('${o.product.name} · ${o.status}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(
                      context,
                      ArtisanOrderDetails(demo: demo, orderId: o.id),
                    ),
                  ),
                ),
              ),
            ],
          ],
          1 => [
            const _Heading('My Products'),
            _searchBar(),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Add Product',
              onPressed: () => _open(context, ArtisanProductForm(demo: demo)),
            ),
            const SizedBox(height: 16),
            ..._productList(),
          ],
          2 when demo.repository != null => [
            ArtisanStudioOrders(
              demo: demo,
              onOpen: (id) =>
                  _open(context, ArtisanOrderDetails(demo: demo, orderId: id)),
              onRetry: _refreshDashboard,
            ),
          ],
          2 => [
            _searchBar(),
            const SizedBox(height: 16),
            if (demo.ordersLoading) const LinearProgressIndicator(),
            if (demo.ordersError != null) _Card(child: Text(demo.ordersError!)),
            if (!demo.ordersLoading && demo.orders.isEmpty)
              const _Card(
                child: Text(
                  'No orders yet. Your studio orders will appear here.',
                ),
              ),
            const _Caption('STUDIO DISPATCH & LOGISTICS'),
            _Heading("${demo.artisanName}'s Studio Orders"),
            Text('${demo.orders.map((o) => o.id).toSet().length} orders'),
            const _Card(
              child: Text(
                'Studio Packaging Checklist\nPlace the hand-signed Certificate of Kiln Provenance inside the protective crate before sealing.',
              ),
            ),
            ...(_query.isEmpty ? demo.orders : _matchingOrders).map(
              (o) => _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Caption('#${o.id} · ${o.status}'),
                    const SizedBox(height: 12),
                    Text('${o.buyer} · ${o.location}'),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SizedBox(
                        width: 60,
                        height: 60,
                        child: _Photo(o.product.images.first),
                      ),
                      title: Text(o.product.name),
                      subtitle: Text(
                        'Qty: ${o.quantity} · ${artisanMoney(o.total)}',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _open(
                        context,
                        ArtisanOrderDetails(demo: demo, orderId: o.id),
                      ),
                      child: const Text('Order Details'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          _ => [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: studioBlush,
                child: Text(
                  demo.artisanName.characters.first,
                  style: studioHeading(40),
                ),
              ),
            ),
            _Heading(demo.artisanName),
            Text(
              demo.artisanLocation.isNotEmpty
                  ? demo.artisanLocation
                  : (demo.studioName.isNotEmpty
                        ? demo.studioName
                        : 'Artisan profile'),
            ),
            _Caption(
              MarketplaceBackend.enabled
                  ? (demo.profile['verificationStatus'] as String? ?? 'pending')
                  : 'GUILD CERTIFIED POTTER',
            ),
            _Card(
              child: Wrap(
                spacing: 28,
                runSpacing: 16,
                children: [
                  _Stat('CREATIONS', '${demo.products.length}'),
                  _Stat('REVIEWS', MarketplaceBackend.enabled ? '' : '4.9'),
                  _Stat(
                    'IN GUILD',
                    MarketplaceBackend.enabled ? '' : '3 years',
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.roleSelection,
                (_) => false,
                arguments: AuthEntry.signIn,
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to roles'),
            ),
            const _Heading('Studio Information'),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Caption('ATELIER NAME'),
                  Text(
                    demo.studioName.isNotEmpty
                        ? demo.studioName
                        : 'Studio name not added',
                  ),
                  SizedBox(height: 18),
                  _Caption('PUBLIC BIO'),
                  Text(
                    demo.artisanBio.isNotEmpty
                        ? demo.artisanBio
                        : 'No public bio has been added yet.',
                  ),
                  SizedBox(height: 18),
                  _Caption('STUDIO LOCATION'),
                  Text(
                    demo.artisanLocation.isNotEmpty
                        ? demo.artisanLocation
                        : 'Location not added',
                  ),
                  SizedBox(height: 18),
                  _Caption('KILN SPECIFICATIONS'),
                  Text(
                    MarketplaceBackend.enabled
                        ? (demo.profile['kilnSpecifications'] as String? ?? '')
                        : 'Wood-Fired Noborigama',
                  ),
                ],
              ),
            ),
            _Card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.verified_outlined,
                  color: AppColors.sage,
                ),
                title: const Text('Verification Status'),
                subtitle: Text(
                  MarketplaceBackend.enabled
                      ? (demo.profile['verificationStatus'] as String? ??
                            'pending')
                      : 'Verified Provenance Seal',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, const ArtisanVerificationScreen()),
              ),
            ),
            const _Card(
              child: Text(
                'Shop status: Accepting orders\nCustom wood-wool crating & compostable wrap',
              ),
            ),
          ],
        },
      ],
    ),
  );

  String get _greeting {
    final hour = DateTime.now().hour;
    return hour < 12
        ? 'GOOD MORNING,'
        : hour < 18
        ? 'GOOD AFTERNOON,'
        : 'GOOD EVENING,';
  }

  Iterable<ArtisanOrder> get _matchingOrders {
    final seen = <String>{};
    return demo.orders.where(
      (o) =>
          '${o.id} ${o.buyer} ${o.product.name} ${o.status}'
              .toLowerCase()
              .contains(_query) &&
          seen.add(o.id),
    );
  }

  Future<void> _refreshDashboard() async {
    try {
      await demo.refreshDashboard();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(marketplaceError(error))));
      }
    }
  }

  Widget _searchBar() => TextField(
    controller: _search,
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(
      hintText: 'Search products, orders, or categories…',
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: _query.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _search.clear()),
            ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFEEDFD5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFF0E8E0)),
      ),
    ),
  );

  List<Widget> _productList({int? limit}) {
    final filtered = demo.products.where((p) {
      final status = demo.catalogRecords[p.id]?.status.name ?? 'active';
      final expected = _filter == 'Drafts' ? 'draft' : _filter.toLowerCase();
      return _matches(p) && (_filter == 'All' || status == expected);
    }).toList();
    return [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in [
              'All',
              'Active',
              'Pending',
              'Drafts',
              'Hidden',
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 16),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: _filter == filter,
                  showCheckmark: false,
                  backgroundColor: const Color(0xFFF1EAE3),
                  selectedColor: studioClay,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  labelStyle: TextStyle(
                    color: _filter == filter ? Colors.white : AppColors.muted,
                  ),
                  onSelected: (_) => setState(() => _filter = filter),
                ),
              ),
          ],
        ),
      ),
      if (demo.productsLoading)
        const Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (demo.productsError != null)
        _Card(
          child: Column(
            children: [
              Text(demo.productsError!),
              TextButton(
                onPressed: _refreshDashboard,
                child: const Text('Try again'),
              ),
            ],
          ),
        )
      else if (filtered.isEmpty)
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: studioClay,
                  size: 32,
                ),
                const SizedBox(height: 10),
                Text(
                  _query.isNotEmpty
                      ? 'No products match your search.'
                      : 'No ${_filter == 'All' ? '' : _filter.toLowerCase()} products yet.',
                  textAlign: TextAlign.center,
                ),
                if (_filter == 'All' && _query.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Add your first creation to start your collection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
              ],
            ),
          ),
        )
      else
        ...filtered
            .take(limit ?? filtered.length)
            .map(
              (p) => ArtisanStudioProductTile(
                product: p,
                demo: demo,
                photo: _Photo(p.images.first),
                onView: () => _open(
                  context,
                  ArtisanProductScreen(demo: demo, productId: p.id),
                ),
                onEdit: () =>
                    _open(context, ArtisanProductForm(demo: demo, product: p)),
              ),
            ),
    ];
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.children,
    this.footer,
    this.navigation,
    this.back,
    this.actions,
    this.hideAppBar = false,
    this.onRefresh,
  });
  final String title;
  final bool hideAppBar;
  final Future<void> Function()? onRefresh;
  final List<Widget> children;
  final Widget? footer, navigation;
  final VoidCallback? back;
  final List<Widget>? actions;
  Widget _refreshable(Widget child) => onRefresh == null
      ? child
      : RefreshIndicator(onRefresh: onRefresh!, child: child);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: studioCream,
    appBar: hideAppBar
        ? null
        : AppBar(
            backgroundColor: AppColors.background,
            leading: back == null ? null : BackButton(onPressed: back),
            title: Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(fontSize: 25),
            ),
            actions: actions,
          ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _refreshable(
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              key: ValueKey(title),
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: children,
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: footer == null
        ? navigation
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: footer,
            ),
          ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(text, style: Theme.of(context).textTheme.headlineLarge),
  );
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.terracotta,
      fontSize: 11,
      letterSpacing: .6,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      _Caption(label),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 20)),
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

class _Photo extends StatelessWidget {
  const _Photo(this.index, {this.height});
  final int index;
  final double? height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: artisanRemotePhotos.containsKey(index)
        ? Image.network(
            artisanRemotePhotos[index]!,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => SizedBox(
              height: height,
              child: const Icon(Icons.image_not_supported_outlined),
            ),
          )
        : index < 0
        ? SizedBox(
            height: height,
            child: const Icon(Icons.add_photo_alternate_outlined),
          )
        : Image.memory(
            artisanLocalPhotos[index] ?? artisanPhotos[index],
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: index >= 100
                ? 'Product photo'
                : const [
                    'Terracotta vase',
                    'Stoneware mug',
                    'Clay planter',
                    'Glazed bowl',
                    'Artisan portrait',
                  ][index],
          ),
  );
}

class ArtisanProductForm extends StatefulWidget {
  const ArtisanProductForm({super.key, required this.demo, this.product});
  final ArtisanDemo demo;
  final ArtisanProduct? product;
  @override
  State<ArtisanProductForm> createState() => _ArtisanProductFormState();
}

class _ArtisanProductFormState extends State<ArtisanProductForm> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.product?.name ?? '');
  late final price = TextEditingController(
    text: widget.product?.price.toStringAsFixed(2) ?? '',
  );
  late final description = TextEditingController(
    text: widget.product?.description ?? '',
  );
  late final images = List<int>.of(
    widget.product?.images ?? (MarketplaceBackend.enabled ? [] : [0]),
  );
  late String? category = widget.product?.category;
  int step = 0;
  bool get editing => widget.product != null;
  @override
  void dispose() {
    name.dispose();
    price.dispose();
    description.dispose();
    super.dispose();
  }

  ArtisanProduct draft() => ArtisanProduct(
    id: widget.product?.id ?? '',
    name: name.text.trim(),
    category: category!,
    price: double.parse(price.text.trim()),
    description: description.text.trim(),
    images: List.unmodifiable(images),
    stock: widget.product?.stock ?? 1,
  );
  void back() {
    if (step > 0) {
      setState(() => step--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> next() async {
    if (widget.demo.saving) return;
    if (step == 0 && images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one product image.')),
      );
      return;
    }
    if (step == 1 && !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (step < 2) {
      setState(() => step++);
      return;
    }
    final p = draft();
    var saved = ArtisanProduct(
      id: editing ? p.id : widget.demo.nextProductId(),
      name: p.name,
      category: p.category,
      price: p.price,
      description: p.description,
      images: p.images,
      stock: p.stock,
    );
    try {
      saved = await widget.demo.persist(saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(marketplaceError(e))));
      }
      return;
    }
    if (!mounted) return;
    if (editing) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              ArtisanPublishedScreen(demo: widget.demo, productId: saved.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: step == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) back();
    },
    child: _Page(
      title: editing ? 'Edit Product' : 'Add Product',
      back: back,
      footer: CustomButton(
        label: step == 0
            ? 'Next: Product Details'
            : step == 1
            ? 'Next: Preview & Review'
            : editing
            ? 'Save Changes'
            : 'Publish Product',
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
                    foregroundColor: i <= step ? Colors.white : AppColors.muted,
                    child: i < step
                        ? const Icon(Icons.check)
                        : Text('${i + 1}'),
                  ),
                  const SizedBox(height: 6),
                  Text(const ['Images', 'Details', 'Preview'][i]),
                ],
              ),
            ),
          ),
        ),
        _Heading(
          'Step ${step + 1} of 3 — ${const ['Images', 'Product Details', 'Preview'][step]}',
        ),
        if (step == 0) ...[
          const _Caption('COVER PHOTO'),
          if (images.isNotEmpty) _Photo(images.first, height: 270),
          const SizedBox(height: 14),
          const Text(
            'Select product photos. The first selected image is the cover.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              4,
              (i) => SizedBox(
                width: 140,
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () async {
                      if (MarketplaceBackend.enabled) {
                        try {
                          final photo = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (photo == null) return;
                          final bytes = await photo.readAsBytes();
                          if (!mounted) return;
                          setState(() {
                            final id = registerArtisanPhoto(bytes: bytes);
                            if (i < images.length) {
                              images[i] = id;
                            } else {
                              images.add(id);
                            }
                          });
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Unable to select this image. Please try again.',
                                ),
                              ),
                            );
                          }
                        }
                        return;
                      }
                      setState(() {
                        if (images.contains(i)) {
                          images.remove(i);
                        } else {
                          images.add(i);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          _Photo(
                            MarketplaceBackend.enabled
                                ? (i < images.length ? images[i] : -1)
                                : i,
                            height: 100,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                images.contains(i)
                                    ? Icons.check_circle
                                    : Icons.add_circle_outline,
                                color: AppColors.terracotta,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${MarketplaceBackend.enabled ? 'Photo' : 'Sample'} ${i + 1}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
        if (step == 1)
          Form(
            key: form,
            child: Column(
              children: [
                CustomTextField(
                  label: 'Product name',
                  controller: name,
                  icon: Icons.inventory_2_outlined,
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Enter a product name.'
                      : null,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  hint: const Text('Select category'),
                  icon: const Icon(Icons.expand_more),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  items: artisanCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => category = v),
                  validator: (v) => v == null ? 'Select a category.' : null,
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Price (USD)',
                  controller: price,
                  icon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final amount = double.tryParse(v?.trim() ?? '');
                    return amount == null || !amount.isFinite || amount <= 0
                        ? 'Enter a price greater than zero.'
                        : null;
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: description,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Describe your piece.'
                      : null,
                ),
              ],
            ),
          ),
        if (step == 2) ...[
          const Text('Review your piece before publishing.'),
          ..._productInformation(draft()),
          TextButton(
            onPressed: () => setState(() => step = 1),
            child: const Text('Edit details'),
          ),
          TextButton(
            onPressed: () => setState(() => step = 0),
            child: const Text('Edit images'),
          ),
        ],
        if (step > 0)
          TextButton.icon(
            onPressed: back,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
      ],
    ),
  );
}

List<Widget> _productInformation(ArtisanProduct p) => [
  const SizedBox(height: 16),
  _Photo(p.images.first, height: 300),
  if (p.images.length > 1)
    Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: p.images
            .skip(1)
            .map((i) => SizedBox(width: 90, child: _Photo(i, height: 90)))
            .toList(),
      ),
    ),
  _Heading(p.name),
  Text(
    artisanMoney(p.price),
    style: const TextStyle(fontSize: 24, color: AppColors.terracotta),
  ),
  _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Caption('PRODUCT INFORMATION'),
        const SizedBox(height: 12),
        Text('Category: ${p.category}'),
        Text('Studio stock: ${p.stock}'),
        const SizedBox(height: 12),
        Text(p.description),
      ],
    ),
  ),
];

class ArtisanPublishedScreen extends StatelessWidget {
  const ArtisanPublishedScreen({
    super.key,
    required this.demo,
    required this.productId,
  });
  final ArtisanDemo demo;
  final String productId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (_, _) {
      final p = demo.products.where((p) => p.id == productId).firstOrNull;
      if (p == null) {
        return const _Page(
          title: 'Product',
          children: [Text('This product is no longer available.')],
        );
      }
      return _Page(
        title: 'Product Published',
        children: [
          const Icon(Icons.check_circle, color: AppColors.sage, size: 72),
          const _Heading('Your product successfully added!'),
          const Text('Your handcrafted piece is now in your catalog.'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Photo(p.images.first, height: 180),
                _Heading(p.name),
                Text('${artisanMoney(p.price)} · LIVE · ${p.id}'),
              ],
            ),
          ),
          CustomButton(
            label: 'View Product',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    ArtisanProductScreen(demo: demo, productId: productId),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                _open(context, ArtisanProductForm(demo: demo, product: p)),
            child: const Text('Edit Product'),
          ),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ArtisanProductForm(demo: demo),
              ),
            ),
            child: const Text('Add Another Product'),
          ),
          TextButton(
            onPressed: () => _dashboard(context),
            child: const Text('Back to Dashboard'),
          ),
        ],
      );
    },
  );
}

class ArtisanProductScreen extends StatelessWidget {
  const ArtisanProductScreen({
    super.key,
    required this.demo,
    required this.productId,
  });
  final ArtisanDemo demo;
  final String productId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (_, _) {
      final p = demo.products.where((p) => p.id == productId).firstOrNull;
      if (p == null) {
        return const _Page(
          title: 'Product',
          children: [Text('This product is no longer available.')],
        );
      }
      return _Page(
        title: 'View Product',
        footer: CustomButton(
          label: 'Edit Product',
          onPressed: () =>
              _open(context, ArtisanProductForm(demo: demo, product: p)),
        ),
        children: [
          _Caption('LIVE CATALOG · ${p.id}'),
          ..._productInformation(p),
          _Card(
            child: Text(
              '${demo.artisanName}'
              '${demo.studioName.isNotEmpty ? ' · ${demo.studioName}' : ''}\n'
              '${(demo.profile['verificationStatus'] as String?) ?? 'Verification pending'}'
              '${demo.artisanLocation.isNotEmpty ? ' · ${demo.artisanLocation}' : ''}',
            ),
          ),
          TextButton(
            onPressed: () => _dashboard(context),
            child: const Text('Back to Dashboard'),
          ),
        ],
      );
    },
  );
}

class ArtisanOrderDetails extends StatelessWidget {
  const ArtisanOrderDetails({
    super.key,
    required this.demo,
    required this.orderId,
  });
  final ArtisanDemo demo;
  final String orderId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (_, _) {
      final record = demo.dashboardOrders
          .where((o) => o.id == orderId)
          .firstOrNull;
      if (record != null) {
        return _Page(
          title: 'Order Details',
          children: [
            ArtisanStudioOrderCard(
              order: record,
              showAction: false,
              onOpen: () {},
            ),
            Text('Payment: ${record.paymentMethod}'),
            Text(
              'Delivery fee: ${studioOrderMoney(record, record.deliveryFee)}',
            ),
            Text(
              'Order total: ${studioOrderMoney(record, record.total)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (record.recipientPhone.isNotEmpty)
              Text('Contact: ${record.recipientPhone}'),
            if (record.deliveryInstructions.isNotEmpty)
              Text('Delivery instructions: ${record.deliveryInstructions}'),
            Text(
              'Courier: ${record.courierId ?? 'Awaiting courier assignment'}',
            ),
            const SizedBox(height: 16),
            const _Heading('Studio Packaging'),
            const _Card(
              child: Text(
                'Protect with wood-wool wrapping.\nInclude the signed Certificate of Kiln Provenance.\nSeal and label the fragile crate.',
              ),
            ),
            if (record.status.name == 'pending')
              CustomButton(
                label: demo.saving ? 'Updating order...' : 'Mark as Packed',
                onPressed: demo.saving
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Mark this order as packed?'),
                            content: const Text(
                              'Confirm the packaging checklist is complete and this order is ready for dispatch.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Mark as Packed'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true &&
                            demo.dashboardOrders.any(
                              (o) =>
                                  o.id == orderId && o.status.name == 'pending',
                            )) {
                          demo.markPacked(orderId);
                        }
                      },
              ),
          ],
        );
      }
      final o = demo.orders.where((o) => o.id == orderId).firstOrNull;
      if (o == null) {
        return const _Page(
          title: 'Order Details',
          children: [Text('This order is no longer available.')],
        );
      }
      return _Page(
        title: 'Order Details',
        children: [
          _Caption('#${o.id} · DEMO ORDER'),
          _Heading(o.status),
          _Photo(o.product.images.first, height: 240),
          _Heading(o.product.name),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buyer: ${o.buyer}'),
                Text('Destination: ${o.location}'),
                Text('Delivery: ${o.delivery}'),
                const Divider(),
                Text(
                  'Quantity: ${o.quantity} × ${artisanMoney(o.product.price)}',
                ),
                Text(
                  'Order total: ${artisanMoney(o.total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const _Heading('Studio Packaging'),
          const _Card(
            child: Text(
              'Protect with wood-wool wrapping.\nInclude the signed Certificate of Kiln Provenance.\nSeal and label the fragile crate.',
            ),
          ),
          if (o.status == 'Needs packing')
            CustomButton(
              label: 'Mark as Packed',
              onPressed: () => demo.markPacked(o.id),
            ),
          if (o.status == 'Ready for dispatch')
            const Text('Packed & sealed · Ready for courier collection'),
          if (o.status == 'In transit')
            const _Card(
              child: Text(
                'Studio Departure ✓\nRegional Hub · In transit\nDoorstep · Pending',
              ),
            ),
        ],
      );
    },
  );
}

class ArtisanVerificationScreen extends StatelessWidget {
  const ArtisanVerificationScreen({super.key});
  @override
  Widget build(BuildContext context) => MarketplaceBackend.enabled
      ? StreamBuilder(
          stream: CommunityRepository().profile(CommunityRepository().uid),
          builder: (context, snapshot) {
            final p = snapshot.data?.data() ?? {};
            final artisanName =
                [
                      p['fullName'],
                      p['displayName'],
                      p['artisanName'],
                      p['name'],
                      p['userName'],
                    ]
                    .whereType<String>()
                    .map((value) => value.trim())
                    .firstWhere(
                      (value) => value.isNotEmpty,
                      orElse: () => 'Artisan',
                    );
            return _Page(
              title: 'Verification Status',
              children: [
                const Icon(Icons.verified, color: AppColors.sage, size: 80),
                _Heading(p['verificationStatus'] as String? ?? 'pending'),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Caption(p['verificationStatus'] as String? ?? 'pending'),
                      const SizedBox(height: 16),
                      Text(
                        '$artisanName\n${p['studioName'] ?? ''}\n${p['location'] ?? ''}',
                      ),
                      const SizedBox(height: 16),
                      Text(p['bio'] as String? ?? ''),
                    ],
                  ),
                ),
                Text(
                  snapshot.hasError ? marketplaceError(snapshot.error!) : 'Verification is reviewed by the Craftisan administration.',
                ),
              ],
            );
          },
        )
      : const _Page(
          title: 'Verification Status',
          children: [
            Icon(Icons.verified, color: AppColors.sage, size: 80),
            _Heading('Guild Certified Potter'),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Caption('VERIFIED PROVENANCE SEAL · ACTIVE'),
                  SizedBox(height: 16),
                  Text(
                    'Artisan profile\nStudio name not added\nLocation not added',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Digital Seal #ST-IV-88\nCraftisan Guild · St. Ives Chapter',
                  ),
                ],
              ),
            ),
            Text('Demo verification status for the studio preview.'),
          ],
        );
}
