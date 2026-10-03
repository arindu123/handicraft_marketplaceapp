import '../../shared/data/community_repository.dart';

import 'dart:async';

import '../../shared/data/marketplace_repository.dart';
import '../../shared/models/domain_models.dart' as canonical;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'artisan_demo_images.dart';

final artisanRemotePhotos = <int, String>{};
final artisanLocalPhotos = <int, Uint8List>{};
int _photoId = 100;
int registerArtisanPhoto({String? url, Uint8List? bytes}) {
  final id = _photoId++;
  if (url != null) artisanRemotePhotos[id] = url;
  if (bytes != null) artisanLocalPhotos[id] = bytes;
  return id;
}

ArtisanProduct artisanProduct(canonical.Product p) => ArtisanProduct(
  id: p.id,
  name: p.name,
  category: p.category,
  price: p.price,
  description: p.description,
  stock: p.stock,
  images: p.imageUrls.isEmpty
      ? [-1]
      : p.imageUrls.map((url) => registerArtisanPhoto(url: url)).toList(),
);
final artisanPhotos = artisanDemoImages.map(base64Decode).toList();
String artisanMoney(num amount) => '\$${amount.toStringAsFixed(2)}';
const artisanCategories = ['Terracotta', 'Stoneware', 'Planters', 'Tableware'];

class ArtisanProduct {
  const ArtisanProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.images,
    this.stock = 1,
  });
  final String id, name, category, description;
  final double price;
  final List<int> images;
  final int stock;
}

const _products = [
  ArtisanProduct(
    id: 'TFV-04',
    name: 'Terracotta Fluted Vase',
    category: 'Terracotta',
    price: 120,
    stock: 4,
    images: [0],
    description: 'Natural terracotta clay with hand-carved fluting. Wheel-thrown and kiln-fired, each vessel has its own warm, tactile character.',
  ),
  ArtisanProduct(
    id: 'SSM-18',
    name: 'Speckled Studio Mug',
    category: 'Stoneware',
    price: 48,
    stock: 18,
    images: [1],
    description: 'Toasty iron-flecked clay with a soft oatmeal glaze. A comfortable, hand-finished cup for slow mornings.',
  ),
  ArtisanProduct(
    id: 'ECP-02',
    name: 'Earth Clay Planter',
    category: 'Planters',
    price: 85,
    stock: 2,
    images: [2],
    description: 'Rough-textured stoneware with a natural exterior and drainage hole. Made for a sunny studio windowsill.',
  ),
  ArtisanProduct(
    id: 'WAB-09',
    name: 'Wood-Ash Glazed Bowl',
    category: 'Tableware',
    price: 62,
    stock: 9,
    images: [3],
    description: 'A wheel-thrown bowl with a rich wood-ash glaze. Small variations celebrate the journey through the kiln.',
  ),
];

class ArtisanOrder {
  const ArtisanOrder(
    this.id,
    this.buyer,
    this.location,
    this.product,
    this.quantity,
    this.status,
    this.delivery,
  );
  final String id, buyer, location, status, delivery;
  final ArtisanProduct product;
  final int quantity;
  double get total => product.price * quantity;
}

/// One session's local UI data. No persistence or cross-role connections.
class ArtisanDemo extends ChangeNotifier {
  MarketplaceRepository? repository;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  String? error;
  bool _disposed = false;
  bool saving = false;
  Map<String, dynamic> profile = {};
  ArtisanDemo() {
    if (!MarketplaceBackend.enabled) return;
    products.clear();
    orders.clear();
    repository = MarketplaceRepository();
    try {
      CommunityRepository().ensureArtisanProfile().catchError(_failed);
      _subscriptions.add(
        CommunityRepository().profile(repository!.uid).listen((snapshot) {
          profile = snapshot.data() ?? {};
          notifyListeners();
        }, onError: _failed),
      );
      _subscriptions.add(
        repository!.products(own: true).listen((rows) {
          products.clear();
          products.addAll(rows.map(artisanProduct));
          notifyListeners();
        }, onError: _failed),
      );
      _subscriptions.add(
        repository!.orders('artisanId').listen((rows) {
          orders.clear();
          for (final order in rows) {
            for (final item in order.items) {
              orders.add(
                ArtisanOrder(
                  order.id,
                  order.buyerId,
                  order.deliveryAddress,
                  ArtisanProduct(
                    id: item.productId,
                    name: item.productName,
                    category: '',
                    price: item.unitPrice,
                    description: '',
                    images: item.imageUrl == null
                        ? [-1]
                        : [registerArtisanPhoto(url: item.imageUrl)],
                  ),
                  item.quantity,
                  switch (order.status) {
                    canonical.OrderStatus.pending => 'Needs packing',
                    canonical.OrderStatus.confirmed => 'Ready for dispatch',
                    _ => order.status.name,
                  },
                  order.courierId ?? 'Awaiting courier assignment',
                ),
              );
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

  Future<ArtisanProduct> persist(ArtisanProduct product) async {
    if (saving) throw const MarketplaceFailure('Your product is being saved.');
    saving = true;
    try {
      if (repository == null) {
        save(product);
        return product;
      }
      final draft = canonical.Product(
        id: product.id,
        artisanId: '',
        name: product.name,
        category: product.category,
        price: product.price,
        currency: 'USD',
        description: product.description,
        imageUrls: product.images
            .where(artisanRemotePhotos.containsKey)
            .map((i) => artisanRemotePhotos[i]!)
            .toList(),
        stock: product.stock,
        status: canonical.ProductStatus.active,
        createdAt: DateTime.now().toUtc(),
      );
      final stored = await repository!.saveProduct(
        draft,
        product.images
            .where(artisanLocalPhotos.containsKey)
            .map((i) => artisanLocalPhotos[i]!)
            .toList(),
      );
      final result = artisanProduct(stored);
      save(result);
      return result;
    } finally {
      saving = false;
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

  final products = List<ArtisanProduct>.of(_products);
  final orders = [
    ArtisanOrder(
      'ORD-9821',
      'Clara Vance',
      'Kyoto, Japan',
      _products[0],
      1,
      'Ready for dispatch',
      'Express Courier',
    ),
    ArtisanOrder(
      'ORD-9820',
      'Marcus Chen',
      'Seattle, USA',
      _products[1],
      2,
      'Needs packing',
      'Standard Ground',
    ),
    ArtisanOrder(
      'ORD-9815',
      'Sofia Alverez',
      'Austin, USA',
      _products[3],
      1,
      'In transit',
      'Standard Ground',
    ),
  ];
  int _nextId = 1;
  String nextProductId() => repository != null
      ? repository!.db.collection('products').doc().id
      : 'STUDIO-${_nextId++}';
  ArtisanProduct product(String id) => products.firstWhere((p) => p.id == id);
  void save(ArtisanProduct product) {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index < 0) {
      products.insert(0, product);
    } else {
      products[index] = product;
    }
    if (!_disposed) notifyListeners();
  }

  void markPacked(String id) {
    if (repository != null) {
      repository!.advanceOrder(id).catchError(_failed);
      return;
    }
    final index = orders.indexWhere((o) => o.id == id);
    final o = orders[index];
    orders[index] = ArtisanOrder(
      o.id,
      o.buyer,
      o.location,
      o.product,
      o.quantity,
      'Ready for dispatch',
      o.delivery,
    );
    notifyListeners();
  }
}
