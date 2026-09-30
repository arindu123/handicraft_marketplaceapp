import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'artisan_demo_images.dart';

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
  String nextProductId() => 'STUDIO-${_nextId++}';
  ArtisanProduct product(String id) => products.firstWhere((p) => p.id == id);
  void save(ArtisanProduct product) {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index < 0) {
      products.insert(0, product);
    } else {
      products[index] = product;
    }
    notifyListeners();
  }

  void markPacked(String id) {
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
