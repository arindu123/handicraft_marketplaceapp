import 'dart:async';
 import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../shared/data/community_repository.dart';
import '../../shared/data/marketplace_repository.dart';
import '../../shared/models/domain_models.dart' as canonical;
import 'artisan_demo_images.dart';

final artisanRemotePhotos = <int, String>{};
final artisanLocalPhotos = <int, Uint8List>{};

int _photoId = 100;

int registerArtisanPhoto({String? url, Uint8List? bytes}) {
  final id = _photoId++;

  if (url != null) {
    artisanRemotePhotos[id] = url;
  }

  if (bytes != null) {
    artisanLocalPhotos[id] = bytes;
  }

  return id;
}

ArtisanProduct artisanProduct(canonical.Product product) {
  return ArtisanProduct(
    id: product.id,
    name: product.name,
    category: product.category,
    price: product.price,
    description: product.description,
    stock: product.stock,
    images: product.imageUrls.isEmpty
        ? [-1]
        : product.imageUrls
              .map((url) => registerArtisanPhoto(url: url))
              .toList(),
  );
}

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

  final String id;
  final String name;
  final String category;
  final String description;
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

  final String id;
  final String buyer;
  final String location;
  final String status;
  final String delivery;
  final ArtisanProduct product;
  final int quantity;

  double get total => product.price * quantity;
}

/// Artisan dashboard state.
///
/// In backend mode, the current artisan's user document and artisan profile
/// are loaded separately. The registered user's name is used as a fallback
/// when the artisan profile does not contain a name.
class ArtisanDemo extends ChangeNotifier {
  MarketplaceRepository? repository;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  String? error;

  bool _disposed = false;
  bool saving = false;
  bool profileLoading = false;

  Map<String, dynamic> profile = {};
  Map<String, dynamic> userProfileData = {};

  ArtisanDemo() {
    if (!MarketplaceBackend.enabled) return;

    products.clear();
    orders.clear();

    repository = MarketplaceRepository();
    profileLoading = true;

    try {
      final communityRepository = CommunityRepository();
      final artisanUid = repository!.uid;

      // Ensure that the signed-in artisan has a profile document.
      communityRepository.ensureArtisanProfile().catchError(_failed);

      // Listen to the artisan-specific profile.
      _subscriptions.add(
        communityRepository
            .profile(artisanUid)
            .listen(
              (snapshot) {
                profile = snapshot.data() ?? {};
                _updateProfileLoading();
              },
              onError: (Object e) {
                profileLoading = false;
                _failed(e);
              },
            ),
      );

      // Listen to the registered user's document.
      // This is the fallback source for the user's actual name.
      _subscriptions.add(
        communityRepository
            .userProfile(artisanUid)
            .listen(
              (snapshot) {
                userProfileData = snapshot.data() ?? {};
                _updateProfileLoading();
              },
              onError: (Object e) {
                profileLoading = false;
                _failed(e);
              },
            ),
      );

      // Listen to the current artisan's products.
      _subscriptions.add(
        repository!.products(own: true).listen((rows) {
          if (_disposed) return;

          products
            ..clear()
            ..addAll(rows.map(artisanProduct));

          notifyListeners();
        }, onError: _failed),
      );

      // Listen to the artisan's orders.
      _subscriptions.add(
        repository!.orders('artisanId').listen((rows) {
          if (_disposed) return;

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
      profileLoading = false;
      _failed(e);
    }
  }

  void _updateProfileLoading() {
    if (_disposed) return;

    profileLoading = false;
    error = null;
    notifyListeners();
  }

  /// Registered name first, then artisan profile name, then Firebase Auth
  /// display name, with "Artisan" as the final fallback.
  String get artisanName {
    final registeredName = CommunityRepository.readName(userProfileData);
    if (registeredName.isNotEmpty) return registeredName;

    final profileName = CommunityRepository.readName(profile);
    if (profileName.isNotEmpty) return profileName;

    return 'Artisan';
  }

  /// Returns the current artisan's studio name, if available.
  String get studioName {
    final value = profile['studioName'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return '';
  }

  /// Returns the current artisan's profile location, if available.
  String get artisanLocation {
    final value = profile['location'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return '';
  }

  /// Returns the current artisan's profile biography, if available.
  String get artisanBio {
    final value = profile['bio'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return '';
  }

  void _failed(Object e) {
    if (_disposed) return;

    error = marketplaceError(e);
    notifyListeners();
  }

  Future<ArtisanProduct> persist(ArtisanProduct product) async {
    if (saving) {
      throw const MarketplaceFailure('Your product is being saved.');
    }

    saving = true;
    notifyListeners();

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
            .map((id) => artisanRemotePhotos[id]!)
            .toList(),
        stock: product.stock,
        status: canonical.ProductStatus.active,
        createdAt: DateTime.now().toUtc(),
      );

      final stored = await repository!.saveProduct(
        draft,
        product.images
            .where(artisanLocalPhotos.containsKey)
            .map((id) => artisanLocalPhotos[id]!)
            .toList(),
      );

      final result = artisanProduct(stored);
      save(result);

      return result;
    } finally {
      saving = false;

      if (!_disposed) {
        notifyListeners();
      }
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

  final List<ArtisanProduct> products = List<ArtisanProduct>.of(_products);

  final List<ArtisanOrder> orders = [
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

  String nextProductId() {
    if (repository != null) {
      return repository!.db.collection('products').doc().id;
    }

    return 'STUDIO-${_nextId++}';
  }

  ArtisanProduct product(String id) {
    return products.firstWhere((product) => product.id == id);
  }

  void save(ArtisanProduct product) {
    final index = products.indexWhere((item) => item.id == product.id);

    if (index < 0) {
      products.insert(0, product);
    } else {
      products[index] = product;
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  void markPacked(String id) {
    if (repository != null) {
      repository!.advanceOrder(id).catchError(_failed);
      return;
    }

    final index = orders.indexWhere((order) => order.id == id);

    if (index < 0) return;

    final order = orders[index];

    orders[index] = ArtisanOrder(
      order.id,
      order.buyer,
      order.location,
      order.product,
      order.quantity,
      'Ready for dispatch',
      order.delivery,
    );

    notifyListeners();
  }
}
