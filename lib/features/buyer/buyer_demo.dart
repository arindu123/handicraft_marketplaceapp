import 'dart:async';

import '../../shared/data/marketplace_repository.dart';
import '../../shared/models/domain_models.dart' as canonical;
import '../../shared/models/delivery_fee_policy.dart';

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
    this.imageUrls = const [],
    this.currency = 'LKR',
    this.stock,
    this.createdAt,
    this.isVerified = false,
    this.rating,
    this.reviewCount,
    this.soldCount,
  });
  final String id;
  final DateTime? createdAt;
  final String? imageUrl;
  final List<String> imageUrls;
  final String currency;
  final int? stock;
  final bool isVerified;
  final double? rating;
  final int? reviewCount, soldCount;
  String priceLabel([int quantity = 1]) => money(price * quantity, currency);
  factory DemoProduct.fromProduct(
    canonical.Product p, {
    String studio = '',
    String location = '',
    bool isVerified = false,
  }) => DemoProduct(
    p.name,
    p.category,
    p.price,
    p.artisanId,
    studio,
    p.description,
    location,
    0,
    id: p.id,
    imageUrl: p.imageUrls.firstOrNull,
    imageUrls: p.imageUrls,
    currency: p.currency,
    stock: p.stock,
    createdAt: p.createdAt,
    isVerified: isVerified,
    rating: p.rating,
    reviewCount: p.reviewCount,
    soldCount: p.soldCount,
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

String money(num value, [String currency = 'LKR']) => currency == 'USD'
    ? '\$${value.toStringAsFixed(2)}'
    : '$currency ${value.toStringAsFixed(2)}';

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
  String get currency => primaryProduct.currency;
  int get count => items.values.fold(0, (total, quantity) => total + quantity);
}

/// Ephemeral UI state, owned and disposed by the Buyer marketplace.
class BuyerDemo extends ChangeNotifier {
  DeliveryFeePolicy _deliveryPolicy = const DeliveryFeePolicy();
  bool get isSignedIn =>
      repository?.auth.currentUser != null &&
      repository?.auth.currentUser?.isAnonymous == false;

  final _subscriptions = <StreamSubscription<dynamic>>[];
  MarketplaceRepository? repository;
  List<DemoProduct> products = [];
  List<canonical.Product> _records = [];
  Map<String, Map<String, dynamic>> _studios = {};
  Iterable<String> get unavailableCartIds =>
      _cartIds.keys.where((id) => !products.any((p) => p.id == id));
  bool loading = true;
  String? catalogError;
  List<Map<String, dynamic>> addresses = [];
  bool addressesLoading = true;
  String? addressError;
  String? selectedAddressId;
  String? error;
  bool _disposed = false;
  Map<String, int> _cartIds = {};
  bool cartLoading = true;
  String? cartError;
  Set<String> _favoriteIds = {};
  final List<String> orderAlerts = [];
  List<Map<String, dynamic>> notifications = [];
  String? notificationError;
  int get unreadNotifications =>
      notifications.where((n) => n['read'] != true).length;

  Future<void> readNotification(String id) async {
    await repository!.userCollection('notifications').doc(id).update({
      'read': true,
    });
  }

  static String statusMessage(BuyerOrderStatus status) => switch (status) {
    BuyerOrderStatus.confirmed => 'Your artisan has confirmed your order.',
    BuyerOrderStatus.courierAssigned =>
      'A courier has been assigned to your order.',
    BuyerOrderStatus.pickedUp =>
      'Your order has been picked up by the courier.',
    BuyerOrderStatus.onTheWay => 'Your order is on the way to you.',
    BuyerOrderStatus.delivered => 'Your order has been delivered.',
    BuyerOrderStatus.cancelled => 'Your order has been cancelled.',
    BuyerOrderStatus.pending => 'Your order is awaiting confirmation.',
  };
  BuyerDemo({MarketplaceRepository? backend}) {
    if (!MarketplaceBackend.enabled && backend == null) {
      loading = false;
      addressesLoading = false;
      catalogError = 'The marketplace connection is unavailable.';
      cartLoading = false;
      return;
    }
    name = '';
    address = '';
    city = '';
    postalCode = '';
    country = '';
    phone = '';
    products.clear();
    favorites.clear();
    orders.clear();
    try {
      repository = backend ?? MarketplaceRepository();
      _subscriptions.add(repository!.db.collection('marketplaceSettings')
          .doc('deliveryLkr').snapshots().listen((snapshot) {
        if (_disposed) return;
        try {
          _deliveryPolicy = DeliveryFeePolicy.fromMap(snapshot.data());
          notifyListeners();
        } catch (error) { _failed(error); }
      }, onError: _failed));
      _subscriptions.add(
        repository!.products().listen(
          (rows) {
            loading = false;
            catalogError = null;
            _records = rows;
            _resolve();
          },
          onError: (Object e) {
            loading = false;
            catalogError = marketplaceError(e);
            _failed(e);
          },
        ),
      );
      _subscriptions.add(
        repository!.db.collection('artisanProfiles').snapshots().listen((
          snapshot,
        ) {
          _studios = {for (final doc in snapshot.docs) doc.id: doc.data()};
          _resolve();
        }, onError: _failed),
      );
      if (!isSignedIn) {
        cartLoading = false;
        addressesLoading = false;
        return;
      }
      _subscriptions.add(
        repository!
            .userCollection('addresses')
            .snapshots()
            .listen(
              (snapshot) {
                addressesLoading = false;
                addressError = null;
                addresses = snapshot.docs
                    .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
                    .toList();
                if (selectedAddressId != null) {
                  final selected = addresses
                      .where((a) => a['id'] == selectedAddressId)
                      .firstOrNull;
                  if (selected != null) {
                    selectAddress(selected);
                  } else {
                    selectedAddressId = null;
                    address = '';
                  }
                } else if (addresses.isNotEmpty) {
                  selectAddress(addresses.first);
                }
                notifyListeners();
              },
              onError: (Object e) {
                addressesLoading = false;
                addressError = marketplaceError(e);
                notifyListeners();
              },
            ),
      );
      _subscriptions.add(
        repository!
            .userCollection('cart')
            .snapshots()
            .listen(
              (s) {
                cartLoading = false;
                cartError = null;
                _cartIds = {
                  for (final d in s.docs) d.id: d.data()['quantity'] as int,
                };
                _resolve();
              },
              onError: (Object e) {
                cartLoading = false;
                cartError = marketplaceError(e);
                _failed(e);
              },
            ),
      );
      _subscriptions.add(
        repository!.userCollection('favorites').snapshots().listen((s) {
          _favoriteIds = s.docs.map((d) => d.id).toSet();
          _resolve();
        }, onError: _failed),
      );
      _subscriptions.add(
        repository!
            .userCollection('notifications')
            .snapshots()
            .listen(
              (s) {
                if (_disposed) return;
                notificationError = null;
                notifications =
                    s.docs
                        .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
                        .toList()
                      ..sort(
                        (a, b) =>
                            (b['createdAt']?.toDate() as DateTime? ??
                                    DateTime(1970))
                                .compareTo(
                                  a['createdAt']?.toDate() as DateTime? ??
                                      DateTime(1970),
                                ),
                      );
                notifyListeners();
              },
              onError: (Object e) {
                if (_disposed) return;
                notificationError = marketplaceError(e);
                notifyListeners();
              },
            ),
      );
      _subscriptions.add(
        repository!.orders('buyerId').listen((rows) {
          if (_disposed) return;
          final previous = {for (final o in orders) o.id: o};
          orders.clear();
          for (final row in rows) {
            final order = fromOrder(row);
            final old = previous[row.id];
            if (old != null) {
              if (old.status != order.status) {
                orderAlerts.add(
                  'Order #${order.id}: ${statusMessage(order.status)}',
                );
              }
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
      catalogError = marketplaceError(e);
      addressesLoading = false;
      _failed(e);
    }
  }
  void _failed(Object e) {
    if (_disposed) return;
    loading = false;
    error = marketplaceError(e);
    notifyListeners();
  }

  void _resolve() {
    products = _records
        .map(
          (p) => DemoProduct.fromProduct(
            p,
            studio: _studios[p.artisanId]?['studioName'] as String? ?? '',
            location: _studios[p.artisanId]?['location'] as String? ?? '',
            isVerified:
                _studios[p.artisanId]?['verificationStatus'] == 'verified',
          ),
        )
        .toList();
    final byId = {for (final p in products) p.id: p};
    cart.clear();
    cart.addAll({
      for (final e in _cartIds.entries)
        if (byId.containsKey(e.key)) byId[e.key]!: e.value,
    });
    favorites.clear();
    favorites.addAll(
      _favoriteIds.where(byId.containsKey).map((id) => byId[id]!),
    );
    notifyListeners();
  }

  Future<void> refreshCatalog() async {
    if (repository == null) return;
    loading = true;
    catalogError = null;
    error = null;
    notifyListeners();
    try {
      _records = await repository!.fetchProducts();
      loading = false;
      _resolve();
    } catch (e) {
      loading = false;
      catalogError = marketplaceError(e);
      notifyListeners();
    }
  }

  Future<void> removeUnavailable(String id) async {
    try {
      await repository!.cartQuantity(id, 0);
    } catch (e) {
      _failed(e);
    }
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
          currency: o.currency,
        ): i.quantity,
    },
    status: BuyerOrderStatus.values.byName(o.status.name),
    address: o.deliveryAddress,
    payment: o.paymentMethod,
    deliveryFee: o.deliveryFee,
  );
  String? _checkoutId;
  bool checkingOut = false;
  Future<void> validateCheckout() async {
    if (repository == null) {
      throw const MarketplaceFailure(
        'The marketplace connection is unavailable.',
      );
    }
    await repository!.validateCheckout(destination, payment);
  }

  Future<BuyerDemoOrder> checkout() async {
    if (checkingOut) {
      throw const MarketplaceFailure('Your order is being submitted.');
    }
    checkingOut = true;
    notifyListeners();
    try {
      if (repository == null) {
        throw const MarketplaceFailure(
          'Connect to the marketplace before placing an order.',
        );
      }
      _checkoutId ??= repository!.db.collection('orders').doc().id;
      final result = await repository!.checkout(
        _checkoutId!,
        '$address\n$city, $postalCode\n$country',
        payment,
        recipientName: name,
        recipientPhone: phone,
        deliveryInstructions: instructions,
        expectedDeliveryFee: delivery,
      );
      _checkoutId = null;
      final receipt =
          orders.where((o) => o.id == result.id).firstOrNull ??
          fromOrder(result);
      if (!orders.any((o) => o.id == result.id)) orders.insert(0, receipt);
      return receipt;
    } finally {
      checkingOut = false;
      if (!_disposed) notifyListeners();
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
  final Set<DemoProduct> favorites = {};
  final Set<String> followedArtisans = {};
  final List<BuyerDemoOrder> orders = [];
  String name = '';
  String address = '';
  String city = '';
  String postalCode = '';
  String country = '';
  String phone = '';
  String instructions = '';
  String payment = 'Cash on delivery';
  int get count => cart.values.fold(0, (a, b) => a + b);
  double get subtotal =>
      cart.entries.fold(0, (a, e) => a + e.key.price * e.value);
  double get delivery =>
      cart.isEmpty ? 0 : MarketplaceRepository.deliveryFeeFor(subtotal,
          currency: currency, policy: _deliveryPolicy);
  double get total => subtotal + delivery;
  String get currency => cart.keys.firstOrNull?.currency ?? 'LKR';
  String get destination =>
      '$name\n$address\n$city, $postalCode\n$country\n$phone';

  Future<void> add(DemoProduct product, [int quantity = 1]) async {
    if (cart.keys.any((item) => item.currency != product.currency)) {
      throw const MarketplaceFailure(
        'Check out or clear your cart before adding a different currency.',
      );
    }
    if (repository == null) {
      throw const MarketplaceFailure(
        'The marketplace connection is unavailable.',
      );
    }
    await repository!.cartQuantity(product.id, quantity, increment: true);
    error = null;
    notifyListeners();
  }

  Future<void> quantity(DemoProduct product, int value) async {
    try {
      if (repository == null) {
        throw const MarketplaceFailure(
          'The marketplace connection is unavailable.',
        );
      }
      await repository!.cartQuantity(product.id, value);
      error = null;
      notifyListeners();
    } catch (e) {
      _failed(e);
    }
  }

  Future<void> favorite(DemoProduct product) async {
    try {
      if (repository == null) {
        throw const MarketplaceFailure(
          'The marketplace connection is unavailable.',
        );
      }
      await repository!.favorite(product.id, !favorites.contains(product));
      error = null;
      notifyListeners();
    } catch (e) {
      _failed(e);
    }
  }

  void selectAddress(Map<String, dynamic> value) {
    selectedAddressId = value['id'] as String;
    name = value['name'] as String;
    address = value['address'] as String;
    city = value['city'] as String;
    postalCode = value['postalCode'] as String;
    country = value['country'] as String;
    phone = value['phone'] as String;
    notifyListeners();
  }

  Future<void> saveAddress(Map<String, String> value, {String? id}) async {
    if (repository == null) {
      throw const MarketplaceFailure(
        'The marketplace connection is unavailable.',
      );
    }
    final ref = repository!.userCollection('addresses').doc(id);
    await ref.set(value);
    selectAddress({...value, 'id': ref.id});
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
    throw const MarketplaceFailure('Orders must be validated by the backend.');
  }
}
