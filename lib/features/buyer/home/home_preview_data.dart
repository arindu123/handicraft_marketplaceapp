import 'package:flutter/material.dart';

/// Local-only catalogue. Replace this source with an adapter to the repository
/// when preview campaigns and prices are ready for production.
class HomePreviewProduct {
  const HomePreviewProduct(
    this.id,
    this.name,
    this.category,
    this.price,
    this.asset,
    this.rating,
    this.sold,
    this.discount,
  );
  final String id, name, category, asset;
  final int price, sold, discount;
  final double rating;
  String get priceLabel =>
      'LKR ${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

abstract interface class HomeCatalogueSource {
  List<HomePreviewProduct> get products;
}

class LocalHomeCatalogue implements HomeCatalogueSource {
  const LocalHomeCatalogue();
  static const vase = 'lib/features/auth/widgets/pottery_vase.png';
  static const mug = 'lib/features/auth/widgets/pottery_mug.png';
  @override
  List<HomePreviewProduct> get products => const [
    HomePreviewProduct(
      'vase',
      'Terracotta Atelier Vase',
      'Pottery',
      4200,
      vase,
      4.9,
      126,
      25,
    ),
    HomePreviewProduct(
      'mug',
      'Morning Ritual Mug',
      'Pottery',
      1850,
      mug,
      4.8,
      84,
      15,
    ),
    HomePreviewProduct(
      'vase-two',
      'Earth & Stem Vessel',
      'Home Decor',
      3600,
      vase,
      4.9,
      62,
      20,
    ),
    HomePreviewProduct(
      'mug-two',
      'Speckled Studio Cup',
      'Home Decor',
      2200,
      mug,
      4.7,
      95,
      10,
    ),
    HomePreviewProduct(
      'vase-three',
      'Quiet Corner Vase',
      'Pottery',
      4800,
      vase,
      4.8,
      41,
      15,
    ),
    HomePreviewProduct(
      'mug-three',
      'Slow Sunday Cup',
      'Pottery',
      1950,
      mug,
      4.9,
      108,
      20,
    ),
  ];
}

const homeCategories = <(String, IconData)>[
  ('Pottery', Icons.coffee_outlined),
  ('Woodcraft', Icons.forest_outlined),
  ('Jewelry', Icons.diamond_outlined),
  ('Textiles', Icons.checkroom_outlined),
  ('Candles', Icons.local_fire_department_outlined),
  ('Home Decor', Icons.chair_outlined),
  ('New', Icons.auto_awesome_outlined),
  ('Free Shipping', Icons.local_shipping_outlined),
];
