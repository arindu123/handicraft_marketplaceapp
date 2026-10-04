import 'dart:async';

import '../../shared/data/marketplace_repository.dart';
import '../../shared/models/domain_models.dart' as canonical;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'demo_product_images.dart';

class DemoProduct {
  const DemoProduct(
    this.name,
    this.category,
    this.price,
    this.artisan,
    this.studio,
    this.description,
    this.location,
    this.imageIndex, {
    this.id = '',
    this.imageUrl,
  });
  final String id;
  final String? imageUrl;
  factory DemoProduct.fromProduct(canonical.Product p) => DemoProduct(
    p.name,
    p.category,
    p.price,
    p.artisanId,
    '',
    p.description,
    '',
    0,
    id: p.id,
    imageUrl: p.imageUrls.firstOrNull,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (id.isNotEmpty && other is DemoProduct && other.id == id);
  @override
  int get hashCode => id.isEmpty ? identityHashCode(this) : id.hashCode;
  final String name, category, artisan, studio, description, location;
  final double price;
  final int imageIndex;
  Uint8List get image => _images[imageIndex];
}

class BuyerReview {
  const BuyerReview(this.reviewer, this.rating, this.comment, this.date);
  final String reviewer, comment, date;
  final double rating;
}

class BuyerArtisan {
  const BuyerArtisan({
    required this.name,
    required this.studio,
    required this.location,
    required this.bio,
    required this.rating,
    required this.reviewCount,
    required this.reviews,
  });
  final String name, studio, location, bio;
  final double rating;
  final int reviewCount;
  final List<BuyerReview> reviews;
}

final _images = demoProductImages.map(base64Decode).toList();

const demoProducts = [
  DemoProduct(
    'Handcrafted Terracotta Ribbed Vase',
    'Terracotta',
    120,
    'Elena Rostova',
    'Oaxaca Traditional Atelier',
    'Thrown using local red clay, each groove is carved by hand before firing. '
        'A warm, sculptural vessel for small sprigs and quiet corners.',
    'Colombo',
    0,
  ),
  DemoProduct(
    'Speckled Studio Stoneware Mug',
    'Stoneware',
    48,
    'Kobo Pottery',
    'Kyoto Studio',
    'High-fired stoneware with an iron-flecked oatmeal glaze. '
        'A tactile 350ml cup made for slow mornings.',
    'Kandy',
    1,
  ),
  DemoProduct(
    'Wood-Ash Glazed Chawan Tea Bowl',
    'Ceramics',
    68,
    'Master Kenji',
    'Mashiko Kiln',
    'Natural pine ash crystallizes in the wood-fired kiln, giving each '
        'tea bowl its own rich surface and character.',
    'Galle',
    2,
  ),
];

const buyerArtisans = [
  BuyerArtisan(
    name: 'Elena Rostova',
    studio: 'Oaxaca Traditional Atelier',
    location: 'Oaxaca Valley, Mexico',
    bio: 'Elena works with locally harvested red clay, hand-carving quiet, tactile forms inspired by the riverbanks and earthen architecture of Oaxaca.',
    rating: 4.9,
    reviewCount: 38,
    reviews: [
      BuyerReview(
        'Maya L.',
        5,
        'The vase feels even more special in person. Beautifully packed with a maker note.',
        'May 2026',
      ),
      BuyerReview(
        'Noah R.',
        5,
        'A thoughtful, sculptural piece with such lovely hand-carved detail.',
        'April 2026',
      ),
      BuyerReview(
        'Clara V.',
        4.8,
        'Warm clay colour and a beautiful story behind it. I will treasure it.',
        'March 2026',
      ),
    ],
  ),
  BuyerArtisan(
    name: 'Kobo Pottery',
    studio: 'Kyoto Studio',
    location: 'Kyoto, Japan',
    bio: 'A small Kyoto pottery studio making tactile daily ware in high-fired stoneware and quiet mineral glazes.',
    rating: 5,
    reviewCount: 42,
    reviews: [
      BuyerReview(
        'Aya M.',
        5,
        'A wonderfully balanced mug for slow mornings.',
        'May 2026',
      ),
    ],
  ),
  BuyerArtisan(
    name: 'Master Kenji',
    studio: 'Mashiko Kiln',
    location: 'Mashiko, Japan',
    bio: 'Wood-fired tea ware shaped through long kiln firings and natural pine ash.',
    rating: 4.9,
    reviewCount: 19,
    reviews: [
      BuyerReview(
        'Rina T.',
        5,
        'The glaze is rich and entirely unique.',
        'February 2026',
      ),
    ],
  ),
];

BuyerArtisan artisanFor(String name) => buyerArtisans.firstWhere(
  (artisan) => artisan.name == name,
  orElse: () => BuyerArtisan(
    name: name,
    studio: '',
    location: '',
    bio: '',
    rating: 0,
    reviewCount: 0,
    reviews: const [],
  ),
);

String money(num value) => '\$${value.toStringAsFixed(2)}';

enum BuyerOrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  courierAssigned('Courier Assigned'),
  pickedUp('Picked Up'),
  onTheWay('On The Way'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const BuyerOrderStatus(this.label);
  final String label;
}

class BuyerDemoOrder {
  BuyerDemoOrder({
    required this.id,
    required this.items,
    required this.date,
    required this.status,
    required this.address,
    required this.payment,
    required this.deliveryFee,
  });
  final String id, date, address, payment;
  final Map<DemoProduct, int> items;
  BuyerOrderStatus status;
  final double deliveryFee;
  double get subtotal => items.entries.fold(
    0,
    (total, item) => total + item.key.price * item.value,
  );
  double get total => subtotal + deliveryFee;
  DemoProduct get primaryProduct => items.keys.first;
  int get count => items.values.fold(0, (total, quantity) => total + quantity);
}

/// Ephemeral UI state, owned and disposed by the Buyer marketplace.
class BuyerDemo extends ChangeNotifier {
  final _subscriptions = <StreamSubscription<dynamic>>[];
  MarketplaceRepository? repository;
  List<DemoProduct> products = List.of(demoProducts);
  String? error;
  bool _disposed = false;
  Map<String, int> _cartIds = {};
  Set<String> _favoriteIds = {};
  BuyerDemo() {
    if (!MarketplaceBackend.enabled) return;
    products.clear();
    favorites.clear();
    orders.clear();
    repository = MarketplaceRepository();
    try {
      _subscriptions.add(
        repository!.products().listen((rows) {
          products = rows.map(DemoProduct.fromProduct).toList();
          _resolve();
        }, onError: _failed),
      );
      _subscriptions.add(
        repository!.userCollection('cart').snapshots().listen((s) {
          _cartIds = {
            for (final d in s.docs) d.id: d.data()['quantity'] as int,
          };
          _resolve();
        }, onError: _failed),
      );
      _subscriptions.add(
        repository!.userCollection('favorites').snapshots().listen((s) {
          _favoriteIds = s.docs.map((d) => d.id).toSet();
          _resolve();
        }, onError: _failed),
      );
      _subscriptions.add(
        repository!.orders('buyerId').listen((rows) {
          final previous = {for (final o in orders) o.id: o};
          orders.clear();
          for (final row in rows) {
            final order = fromOrder(row);
            final old = previous[row.id];
            if (old != null) {
              old.status = order.status;
              orders.add(old);
            } else {
              orders.add(order);
            }
          }
          notifyListeners();
        }, onError: _failed),
      );
    } catch (e) {
      _failed(e);
    }
  }
  void _failed(Object e) {
    if (_disposed) return;
    error = marketplaceError(e);
    notifyListeners();
  }

  void _resolve() {
    DemoProduct resolve(String id) =>
        products.where((p) => p.id == id).firstOrNull ??
        DemoProduct('Unavailable product', '', 0, '', '', '', '', 0, id: id);
    cart.clear();
    cart.addAll({for (final e in _cartIds.entries) resolve(e.key): e.value});
    favorites.clear();
    favorites.addAll(_favoriteIds.map(resolve));
    notifyListeners();
  }

  static BuyerDemoOrder fromOrder(canonical.Order o) => BuyerDemoOrder(
    id: o.id,
    date: o.createdAt.toLocal().toString().split(' ').first,
    items: {
      for (final i in o.items)
        DemoProduct(
          i.productName,
          '',
          i.unitPrice,
          o.artisanId,
          '',
          '',
          '',
          0,
          id: i.productId,
          imageUrl: i.imageUrl,
        ): i.quantity,
    },
    status: BuyerOrderStatus.values.byName(o.status.name),
    address: o.deliveryAddress,
    payment: o.paymentMethod,
    deliveryFee: o.deliveryFee,
  );
  String? _checkoutId;
  bool checkingOut = false;
  Future<BuyerDemoOrder> checkout() async {
    if (checkingOut) {
      throw const MarketplaceFailure('Your order is being submitted.');
    }
    checkingOut = true;
    try {
      if (repository == null) {
        final result = createOrder(Map.of(cart), total);
        clearCart();
        return result;
      }
      _checkoutId ??= repository!.db.collection('orders').doc().id;
      final result = await repository!.checkout(
        _checkoutId!,
        destination,
        payment,
      );
      _checkoutId = null;
      final receipt =
          orders.where((o) => o.id == result.id).firstOrNull ??
          fromOrder(result);
      if (!orders.any((o) => o.id == result.id)) orders.insert(0, receipt);
      return receipt;
    } finally {
      checkingOut = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  final Map<DemoProduct, int> cart = {};
  final Set<DemoProduct> favorites = {demoProducts.first};
  final Set<String> followedArtisans = {};
  late final List<BuyerDemoOrder> orders = [
    BuyerDemoOrder(
      id: 'CS-2048',
      items: {demoProducts[0]: 1},
      date: 'May 28, 2026',
      status: BuyerOrderStatus.onTheWay,
      address: '742 Evergreen Pottery Lane, Apt 4B\nPortland, OR 97201',
      payment: 'Demo Visa ending in 4092',
      deliveryFee: 14,
    ),
    BuyerDemoOrder(
      id: 'CS-2041',
      items: {demoProducts[1]: 2},
      date: 'May 14, 2026',
      status: BuyerOrderStatus.delivered,
      address: '742 Evergreen Pottery Lane, Apt 4B\nPortland, OR 97201',
      payment: 'Cash on delivery',
      deliveryFee: 0,
    ),
  ];
  int _nextOrder = 2049;
  String name = 'Clara Lindqvist';
  String address = '742 Evergreen Pottery Lane, Apt 4B';
  String city = 'Portland';
  String postalCode = '97201';
  String country = 'United States';
  String phone = '+1 (503) 555-0192';
  String instructions = '';
  String payment = 'Cash on delivery';
  int get count => cart.values.fold(0, (a, b) => a + b);
  double get subtotal =>
      cart.entries.fold(0, (a, e) => a + e.key.price * e.value);
  double get delivery => cart.isEmpty || subtotal >= 250 ? 0 : 14;
  double get total => subtotal + delivery;
  String get destination =>
      '$name\n$address\n$city, $postalCode\n$country\n$phone';

  void add(DemoProduct product, [int quantity = 1]) {
    if (repository != null) {
      repository!
          .cartQuantity(product.id, quantity, increment: true)
          .catchError(_failed);
      return;
    }
    cart[product] = (cart[product] ?? 0) + quantity;
    notifyListeners();
  }

  void quantity(DemoProduct product, int value) {
    if (repository != null) {
      repository!.cartQuantity(product.id, value).catchError(_failed);
      return;
    }
    if (value <= 0) {
      cart.remove(product);
    } else {
      cart[product] = value;
    }
    notifyListeners();
  }

  void favorite(DemoProduct product) {
    if (repository != null) {
      repository!
          .favorite(product.id, !favorites.contains(product))
          .catchError(_failed);
      return;
    }
    if (!favorites.remove(product)) favorites.add(product);
    notifyListeners();
  }

  void followArtisan(BuyerArtisan artisan) {
    if (!followedArtisans.remove(artisan.name)) {
      followedArtisans.add(artisan.name);
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  BuyerDemoOrder createOrder(Map<DemoProduct, int> items, double total) {
    final subtotal = items.entries.fold<double>(
      0,
      (sum, item) => sum + item.key.price * item.value,
    );
    final order = BuyerDemoOrder(
      id: 'CS-${_nextOrder++}',
      items: Map.unmodifiable(items),
      date: 'Today',
      status: BuyerOrderStatus.confirmed,
      address: '$address\n$city, $postalCode',
      payment: payment,
      deliveryFee: total - subtotal,
    );
    orders.insert(0, order);
    notifyListeners();
    return order;
  }
}
