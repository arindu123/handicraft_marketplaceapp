import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cloudinary_upload.dart';

import '../models/domain_models.dart' as model;
import '../../features/auth/services/auth_session.dart';

// Enabled by the production entry point. Isolated previews retain their fixtures.
class MarketplaceBackend {
  static bool enabled = false;
}

class MarketplaceFailure implements Exception {
  const MarketplaceFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

String marketplaceError(Object error) {
  if (error is MarketplaceFailure) return error.message;
  if (error is FirebaseException) {
    if (error.code == 'permission-denied' || error.code == 'unauthorized') {
      return 'You do not have permission to perform this action.';
    }
    if ([
      'unavailable',
      'network-request-failed',
      'retry-limit-exceeded',
    ].contains(error.code)) {
      return 'Check your connection and try again.';
    }
  }
  return 'Unable to save your changes. Please try again.';
}

class MarketplaceRepository {
  MarketplaceRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    CloudinaryUpload? imageUploader,
    Future<model.UserRole> Function()? loadRole,
  }) : db = firestore ?? FirebaseFirestore.instance,
       auth = auth ?? FirebaseAuth.instance,
       imageUploader = imageUploader ?? CloudinaryUpload(),
       _loadRole = loadRole ?? AuthSession.loadRole;
  final Future<model.UserRole> Function() _loadRole;
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final CloudinaryUpload imageUploader;
  String get uid =>
      auth.currentUser?.uid ??
      (throw const MarketplaceFailure('Please sign in to continue.'));
  Future<void> requireRole(model.UserRole role) async {
    if (await _loadRole() != role) {
      throw const MarketplaceFailure(
        'This action is not available for your account.',
      );
    }
  }

  CollectionReference<Map<String, dynamic>> userCollection(String name) =>
      db.collection('users').doc(uid).collection(name);
  Stream<List<model.Product>> products({bool own = false}) {
    final query = own
        ? db.collection('products').where('artisanId', isEqualTo: uid)
        : db.collection('products').where('status', isEqualTo: 'active');
    return query.snapshots().map(
      (s) => s.docs
          .map((d) => model.Product.fromMap({...d.data(), 'id': d.id}))
          .toList(),
    );
  }

  Future<List<model.Product>> fetchProducts() async {
    final snapshot = await db
        .collection('products')
        .where('status', isEqualTo: 'active')
        .get(const GetOptions(source: Source.server));
    return snapshot.docs
        .map((d) => model.Product.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  Stream<List<model.Order>> orders(String relationship) => db
      .collection('orders')
      .where(relationship, isEqualTo: uid)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => model.Order.fromMap({...d.data(), 'id': d.id}))
            .toList(),
      );

  Stream<List<model.Order>> availableDeliveries() => db
      .collection('orders')
      .where('status', isEqualTo: 'confirmed')
      .where('courierId', isNull: true)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => model.Order.fromMap({...d.data(), 'id': d.id}))
            .toList(),
      );

  Future<void> acceptDelivery(String id) async {
    await requireRole(model.UserRole.courier);
    final courier = uid;
    final ref = db.collection('orders').doc(id);
    await db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists ||
          snapshot.data()!['status'] != 'confirmed' ||
          snapshot.data()!['courierId'] != null) {
        throw const MarketplaceFailure('This delivery is no longer available.');
      }
      tx.update(ref, {
        'courierId': courier,
        'status': 'courierAssigned',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

  Future<model.Product> saveProduct(
    model.Product draft,
    List<Uint8List> images,
  ) async {
    await requireRole(model.UserRole.artisan);
    if (draft.name.trim().isEmpty ||
        !draft.price.isFinite ||
        draft.price < 0 ||
        draft.stock < 0 ||
        draft.imageUrls.length + images.length > 4) {
      throw const MarketplaceFailure(
        'Check the product details and select at most four images.',
      );
    }
    final owner = uid;
    final ref = draft.id.isEmpty
        ? db.collection('products').doc()
        : db.collection('products').doc(draft.id);
    final existing = await ref.get();
    if (existing.exists && existing.data()!['artisanId'] != owner) {
      throw const MarketplaceFailure('You can edit only your own products.');
    }
    final urls = <String>[...draft.imageUrls];
    try {
      for (var i = 0; i < images.length; i++) {
        if (images[i].length > 10 * 1024 * 1024) {
          throw const MarketplaceFailure('Choose images smaller than 10 MB.');
        }
        urls.add(await imageUploader.upload(images[i]));
      }
    } catch (_) {
      throw const MarketplaceFailure(
        'Image upload failed. Check your connection and try again.',
      );
    }
    final product = model.Product(
      id: ref.id,
      artisanId: owner,
      name: draft.name,
      category: draft.category,
      price: draft.price,
      currency: draft.currency,
      description: draft.description,
      imageUrls: urls,
      stock: draft.stock,
      status: draft.status,
      createdAt: existing.exists
          ? model.Product.fromMap(existing.data()!).createdAt
          : DateTime.now().toUtc(),
    );
    // Uploads complete before any document is written. Do not delete uploaded images
    // after an ambiguous write error: the document may already reference them.
    await ref.set(product.toMap());
    return product;
  }

  Future<void> cartQuantity(
    String productId,
    int quantity, {
    bool increment = false,
  }) async {
    await requireRole(model.UserRole.buyer);
    final ref = userCollection('cart').doc(productId);
    await db.runTransaction((tx) async {
      final current = await tx.get(ref);
      final value = increment
          ? (current.data()?['quantity'] as int? ?? 0) + quantity
          : quantity;
      if (value <= 0) {
        tx.delete(ref);
        return;
      }
      final product = await tx.get(db.collection('products').doc(productId));
      if (!product.exists || product.data()!['status'] != 'active') {
        throw const MarketplaceFailure('This product is no longer available.');
      }
      if (value > (product.data()!['stock'] as int)) {
        throw const MarketplaceFailure(
          'The requested quantity is not available.',
        );
      }
      tx.set(ref, {
        'productId': productId,
        'quantity': value,
        'addedAt': current.data()?['addedAt'] ?? FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> favorite(String productId, bool selected) async {
    final ref = userCollection('favorites').doc(productId);
    if (selected) {
      await ref.set({
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  // Existing USD/COD contract, also enforced by firestore.rules validOrder.
  static double deliveryFeeFor(double subtotal) => subtotal >= 250 ? 0 : 14;

  static model.Order buildOrder(
    String id,
    String buyer,
    List<model.Product> products,
    Map<String, int> quantities,
    String address,
    String payment,
  ) {
    if (products.isEmpty || products.length > 4) {
      throw const MarketplaceFailure(
        'Choose between 1 and 4 different products per order.',
      );
    }
    if (products.map((p) => p.artisanId).toSet().length != 1) {
      throw const MarketplaceFailure(
        'Please check out products from one artisan at a time.',
      );
    }
    if (products.map((p) => p.id).toSet().length != products.length ||
        address.trim().isEmpty ||
        products.any(
          (p) => p.currency != 'USD' || !p.price.isFinite || p.price < 0,
        )) {
      throw const MarketplaceFailure(
        'Please check your products and delivery address.',
      );
    }
    if (payment != 'Cash on delivery') {
      throw const MarketplaceFailure(
        'Only cash on delivery is available at this time.',
      );
    }
    final items = products.map((p) {
      final quantity = quantities[p.id] ?? 0;
      if (p.status != model.ProductStatus.active ||
          quantity < 1 ||
          quantity > p.stock) {
        throw const MarketplaceFailure(
          'A product is unavailable or has insufficient stock. Please update your cart.',
        );
      }
      return model.OrderItem(
        productId: p.id,
        productName: p.name,
        imageUrl: p.imageUrls.firstOrNull,
        unitPrice: p.price,
        quantity: quantity,
      );
    }).toList();
    final subtotal = items.fold<double>(
      0,
      (total, i) => total + i.unitPrice * i.quantity,
    );
    final fee = deliveryFeeFor(subtotal);
    return model.Order(
      id: id,
      buyerId: buyer,
      artisanId: products.first.artisanId,
      items: items,
      status: model.OrderStatus.pending,
      deliveryAddress: address,
      paymentMethod: payment,
      subtotal: subtotal,
      deliveryFee: fee,
      total: subtotal + fee,
      createdAt: DateTime.now().toUtc(),
    );
  }

  /// Refresh the persisted cart and products before advancing checkout.
  /// Final prices, stock, delivery fee and pending status are enforced by rules
  /// in the atomic order transaction; this preflight never creates an order.
  Future<model.Order> validateCheckout(String address, String payment) async {
    await requireRole(model.UserRole.buyer);
    final cart = await userCollection('cart')
        .get(const GetOptions(source: Source.server));
    final products = <model.Product>[];
    final quantities = <String, int>{};
    for (final row in cart.docs) {
      final product = await db
          .collection('products')
          .doc(row.id)
          .get(const GetOptions(source: Source.server));
      if (!product.exists) {
        throw const MarketplaceFailure(
          'A product is no longer available. Update your cart.',
        );
      }
      products.add(model.Product.fromMap(product.data()!));
      quantities[row.id] = row.data()['quantity'] as int;
    }
    return buildOrder('', uid, products, quantities, address, payment);
  }

  Future<model.Order> checkout(
    String requestId,
    String address,
    String payment, {
    String recipientName = '',
    String recipientPhone = '',
    String deliveryInstructions = '',
  }) async {
    await requireRole(model.UserRole.buyer);
    if (recipientName.length > 100 ||
        recipientPhone.length > 40 ||
        deliveryInstructions.length > 1000) {
      throw const MarketplaceFailure('Delivery contact details are too long.');
    }
    final buyer = uid;
    final ref = db.collection('orders').doc(requestId);
    final cart = await userCollection('cart').get();
    return db.runTransaction((tx) async {
      final prior = await tx.get(ref);
      if (prior.exists) {
        final order = model.Order.fromMap(prior.data()!);
        if (order.buyerId != buyer) {
          throw const MarketplaceFailure('Unable to access this order.');
        }
        return order;
      }
      final quantities = <String, int>{};
      final products = <model.Product>[];
      for (final row in cart.docs) {
        final current = await tx.get(row.reference);
        if (!current.exists) {
          throw const MarketplaceFailure(
            'Your cart changed. Please try again.',
          );
        }
        quantities[row.id] = current.data()!['quantity'] as int;
        final product = await tx.get(db.collection('products').doc(row.id));
        if (!product.exists) {
          throw const MarketplaceFailure(
            'A product is no longer available. Please remove it from your cart.',
          );
        }
        products.add(model.Product.fromMap(product.data()!));
      }
      final order = buildOrder(
        ref.id,
        buyer,
        products,
        quantities,
        address,
        payment,
      );
      final studio = products.isEmpty
          ? null
          : await tx.get(
              db.collection('artisanProfiles').doc(products.first.artisanId),
            );
      final data = order.toMap();
      if (recipientName.trim().isNotEmpty) {
        data['recipientName'] = recipientName.trim();
      }
      if (recipientPhone.trim().isNotEmpty) {
        data['recipientPhone'] = recipientPhone.trim();
      }
      if (deliveryInstructions.trim().isNotEmpty) {
        data['deliveryInstructions'] = deliveryInstructions.trim();
      }
      final studioData = studio?.data();
      if (studioData?['location'] is String) {
        data['pickupAddress'] = studioData!['location'];
      }
      if (studioData?['studioName'] is String) {
        data['pickupName'] = studioData!['studioName'];
      }
      tx.set(ref, data);
      for (final product in products) {
        tx.update(db.collection('products').doc(product.id), {
          'stock': product.stock - quantities[product.id]!,
          'lastOrderId': ref.id,
        });
      }
      for (final row in cart.docs) {
        tx.delete(row.reference);
      }
      return model.Order.fromMap(data);
    });
  }

  Future<void> advanceOrder(String id, {String? confirmationCode}) async {
    final user = uid;
    final ref = db.collection('orders').doc(id);
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw const MarketplaceFailure('This order is no longer available.');
      }
      final order = model.Order.fromMap(snap.data()!);
      if (order.status == model.OrderStatus.onTheWay &&
          !RegExp(r'^\d{6}$').hasMatch(confirmationCode ?? '')) {
        throw const MarketplaceFailure(
          'Enter the customer’s six-digit delivery code.',
        );
      }
      final next = switch (order.status) {
        model.OrderStatus.pending when order.artisanId == user =>
          model.OrderStatus.confirmed,
        model.OrderStatus.courierAssigned when order.courierId == user =>
          model.OrderStatus.pickedUp,
        model.OrderStatus.pickedUp when order.courierId == user =>
          model.OrderStatus.onTheWay,
        model.OrderStatus.onTheWay when order.courierId == user =>
          model.OrderStatus.delivered,
        _ => throw const MarketplaceFailure(
          'This order cannot be advanced by your account.',
        ),
      };
      tx.update(ref, {
        'status': next.name,
        if (next == model.OrderStatus.delivered)
          'deliveryConfirmationCode': confirmationCode,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }
}
