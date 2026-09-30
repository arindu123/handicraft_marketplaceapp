import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/route_names.dart';
import '../../shared/models/craftisan_demo_messages.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/craftisan_messaging.dart';
import 'artisan_demo.dart';

void _open(BuildContext context, Widget page) =>
    Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page));
void _dashboard(BuildContext context) => Navigator.popUntil(
  context,
  (r) => r.settings.name == RouteNames.marketplace || r.isFirst,
);

class ArtisanDashboardScreen extends StatefulWidget {
  const ArtisanDashboardScreen({super.key});
  @override
  State<ArtisanDashboardScreen> createState() => _ArtisanDashboardScreenState();
}

class _ArtisanDashboardScreenState extends State<ArtisanDashboardScreen> {
  final demo = ArtisanDemo();
  int tab = 0;
  @override
  void dispose() {
    demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (context, _) => _Page(
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
      navigation: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      children: switch (tab) {
        0 => [
          const _Caption('CERAMICS & KILN'),
          const _Heading('Welcome back, Elena'),
          _Card(
            color: AppColors.terracotta,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'LIVE CATALOG',
                  style: TextStyle(color: Colors.white70, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Text(
                  '${demo.products.length} handcrafted pieces',
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  '${demo.orders.where((o) => o.status != 'In transit').length} studio orders awaiting dispatch',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Shop status: accepting orders',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          CustomButton(
            label: 'Add Product',
            onPressed: () => _open(context, ArtisanProductForm(demo: demo)),
          ),
          _Card(
            child: Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                _Stat(
                  'DEMO ORDER VALUE',
                  artisanMoney(
                    demo.orders.fold<double>(0, (sum, o) => sum + o.total),
                  ),
                ),
                _Stat('ORDERS', '${demo.orders.length}'),
                const _Stat('STUDIO STATUS', 'Guild certified'),
              ],
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const _Heading('My Products'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => setState(() => tab = 1),
          ),
          ...demo.products
              .take(2)
              .map((p) => _ProductCard(demo: demo, product: p)),
        ],
        1 => [
          const _Caption('STUDIO ATELIER'),
          const _Heading('Ceramic Collection'),
          CustomButton(
            label: 'Add Product',
            onPressed: () => _open(context, ArtisanProductForm(demo: demo)),
          ),
          const SizedBox(height: 12),
          Text('${demo.products.length} pieces · Live Catalog'),
          ...demo.products.map((p) => _ProductCard(demo: demo, product: p)),
        ],
        2 => [
          const _Caption('STUDIO DISPATCH & LOGISTICS'),
          const _Heading('Elena Vance Pottery'),
          Text('${demo.orders.length} demo orders'),
          const _Card(
            child: Text(
              'Studio Packaging Checklist\nPlace the hand-signed Certificate of Kiln Provenance inside the protective crate before sealing.',
            ),
          ),
          ...demo.orders.map(
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
              backgroundImage: MemoryImage(artisanPhotos[4]),
            ),
          ),
          const _Heading('Elena Vance'),
          const Text('@elenavance.ceramics'),
          const _Caption('GUILD CERTIFIED POTTER'),
          _Card(
            child: Wrap(
              spacing: 28,
              runSpacing: 16,
              children: [
                _Stat('CREATIONS', '${demo.products.length}'),
                const _Stat('188 REVIEWS', '4.9 ★'),
                const _Stat('IN GUILD', '3 years'),
              ],
            ),
          ),
          const _Heading('Studio Information'),
          const _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Caption('ATELIER NAME'),
                Text('St. Ives Hearth & Clay'),
                SizedBox(height: 18),
                _Caption('PUBLIC BIO'),
                Text(
                  'Specializing in wheel-thrown fluted terracotta and wood-ash stoneware. Every piece is shaped, fired and finished by hand in our coastal studio.',
                ),
                SizedBox(height: 18),
                _Caption('STUDIO LOCATION'),
                Text('St. Ives, Cornwall, UK'),
                SizedBox(height: 18),
                _Caption('KILN SPECIFICATIONS'),
                Text('Wood-Fired Noborigama · Cone 10 (1280°C)'),
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
              subtitle: const Text('Verified Provenance Seal · Active'),
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
    ),
  );
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.children,
    this.footer,
    this.navigation,
    this.back,
    this.actions,
  });
  final String title;
  final List<Widget> children;
  final Widget? footer, navigation;
  final VoidCallback? back;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
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
          child: ListView(
            key: ValueKey(title),
            padding: const EdgeInsets.all(20),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: children,
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
  const _Card({required this.child, this.color = Colors.white});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Material(
      color: color,
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
    child: Image.memory(
      artisanPhotos[index],
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      semanticLabel: const [
        'Terracotta vase',
        'Stoneware mug',
        'Clay planter',
        'Glazed bowl',
        'Artisan portrait',
      ][index],
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.demo, required this.product});
  final ArtisanDemo demo;
  final ArtisanProduct product;
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => _open(
            context,
            ArtisanProductScreen(demo: demo, productId: product.id),
          ),
          child: _Photo(product.images.first, height: 210),
        ),
        const SizedBox(height: 12),
        _Caption(
          '${product.category.toUpperCase()} · ${product.stock <= 2 ? 'LOW STOCK' : 'LIVE CATALOG'}',
        ),
        _Heading(product.name),
        Text(
          artisanMoney(product.price),
          style: const TextStyle(color: AppColors.terracotta, fontSize: 21),
        ),
        Text('${product.stock} in studio stock · ${product.id}'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _open(
                  context,
                  ArtisanProductScreen(demo: demo, productId: product.id),
                ),
                child: const Text('View Product'),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _open(
                context,
                ArtisanProductForm(demo: demo, product: product),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ],
        ),
      ],
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
  late final images = List<int>.of(widget.product?.images ?? [0]);
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

  void next() {
    if (step == 0 && images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one demo product image.'),
        ),
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
    final saved = ArtisanProduct(
      id: editing ? p.id : widget.demo.nextProductId(),
      name: p.name,
      category: p.category,
      price: p.price,
      description: p.description,
      images: p.images,
      stock: p.stock,
    );
    widget.demo.save(saved);
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
            'Select sample photos for this UI preview. The first selected image is the cover. No files are uploaded.',
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
                    onTap: () => setState(() {
                      if (images.contains(i)) {
                        images.remove(i);
                      } else {
                        images.add(i);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          _Photo(i, height: 100),
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
                              Flexible(child: Text('Sample ${i + 1}')),
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
          const Text(
            'Review your piece before publishing. This demo listing is kept only for the current session.',
          ),
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
      final p = demo.product(productId);
      return _Page(
        title: 'Product Published',
        children: [
          const Icon(Icons.check_circle, color: AppColors.sage, size: 72),
          const _Heading('Your product successfully added!'),
          const Text('Your handcrafted piece is now in your demo catalog.'),
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
      final p = demo.product(productId);
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
          const _Card(
            child: Text(
              'Elena Vance · St. Ives Hearth & Clay\nGuild Certified Potter · St. Ives, Cornwall, UK',
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
      final o = demo.orders.firstWhere((o) => o.id == orderId);
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
  Widget build(BuildContext context) => const _Page(
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
            Text('Elena Vance\nSt. Ives Hearth & Clay\nSt. Ives, Cornwall, UK'),
            SizedBox(height: 16),
            Text('Digital Seal #ST-IV-88\nCraftisan Guild · St. Ives Chapter'),
          ],
        ),
      ),
      Text('Demo verification status for the studio preview.'),
    ],
  );
}
