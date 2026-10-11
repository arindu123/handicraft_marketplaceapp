// Shared domain contracts. Reads accept legacy ISO dates and Firestore timestamps;
// writes retain existing ISO serialization for products and orders.
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

enum UserRole { buyer, artisan, courier, admin }

enum VerificationStatus { pending, verified, rejected }

enum ProductStatus { draft, active, hidden }

enum OrderStatus {
  pending,
  confirmed,
  courierAssigned,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
}

DateTime? documentDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is String) return DateTime.parse(value);
  throw const FormatException('Unsupported document date');
}

DateTime _date(Map<String, dynamic> map, String key) =>
    documentDate(map[key]) ?? (throw FormatException('Missing date: $key'));
double _number(Map<String, dynamic> map, String key) =>
    (map[key] as num).toDouble();
List<String> _strings(Map<String, dynamic> map, String key) =>
    List<String>.from(map[key] as List);

class User {
  const User({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.active,
    required this.createdAt,
  });

  final String id, name, email, phone;
  final UserRole role;
  final String? avatarUrl;
  final bool active;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'role': role.name,
    'name': name,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'active': active,
    'createdAt': createdAt.toIso8601String(),
  };
  Map<String, dynamic> toJson() => toMap();
  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'] as String,
    role: UserRole.values.byName(map['role'] as String),
    name: map['name'] as String,
    email: map['email'] as String,
    phone: map['phone'] as String,
    avatarUrl: map['avatarUrl'] as String?,
    active: map['active'] as bool,
    createdAt: _date(map, 'createdAt'),
  );
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);
}

class ArtisanProfile {
  const ArtisanProfile({
    required this.userId,
    required this.studioName,
    required this.location,
    required this.bio,
    required this.verificationStatus,
    required this.rating,
    required this.reviewCount,
  });

  final String userId, studioName, location, bio;
  final VerificationStatus verificationStatus;
  final double rating;
  final int reviewCount;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'studioName': studioName,
    'location': location,
    'bio': bio,
    'verificationStatus': verificationStatus.name,
    'rating': rating,
    'reviewCount': reviewCount,
  };
  Map<String, dynamic> toJson() => toMap();
  factory ArtisanProfile.fromMap(Map<String, dynamic> map) => ArtisanProfile(
    userId: map['userId'] as String,
    studioName: map['studioName'] as String,
    location: map['location'] as String,
    bio: map['bio'] as String,
    verificationStatus: VerificationStatus.values.byName(
      map['verificationStatus'] as String,
    ),
    rating: _number(map, 'rating'),
    reviewCount: map['reviewCount'] as int,
  );
  factory ArtisanProfile.fromJson(Map<String, dynamic> json) =>
      ArtisanProfile.fromMap(json);
}

class CourierProfile {
  const CourierProfile({
    required this.userId,
    required this.serviceArea,
    required this.vehicleType,
    required this.availability,
    required this.rating,
  });

  final String userId, serviceArea, vehicleType;
  final bool availability;
  final double rating;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'serviceArea': serviceArea,
    'vehicleType': vehicleType,
    'availability': availability,
    'rating': rating,
  };
  Map<String, dynamic> toJson() => toMap();
  factory CourierProfile.fromMap(Map<String, dynamic> map) => CourierProfile(
    userId: map['userId'] as String,
    serviceArea: map['serviceArea'] as String,
    vehicleType: map['vehicleType'] as String,
    availability: map['availability'] as bool,
    rating: _number(map, 'rating'),
  );
  factory CourierProfile.fromJson(Map<String, dynamic> json) =>
      CourierProfile.fromMap(json);
}

class Product {
  Product({
    required this.id,
    required this.artisanId,
    required this.name,
    required this.category,
    required this.price,
    required this.currency,
    required this.description,
    required List<String> imageUrls,
    required this.stock,
    required this.status,
    required this.createdAt,
    this.rating,
    this.reviewCount,
    this.soldCount,
  }) : imageUrls = List.unmodifiable(imageUrls);

  final String id, artisanId, name, category, currency, description;
  final double price;
  final double? rating;
  final int? reviewCount, soldCount;
  final List<String> imageUrls;
  final int stock;
  final ProductStatus status;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'artisanId': artisanId,
    'name': name,
    'category': category,
    'price': price,
    'currency': currency,
    'description': description,
    'imageUrls': imageUrls,
    'stock': stock,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    if (rating != null) 'rating': rating,
    if (reviewCount != null) 'reviewCount': reviewCount,
    if (soldCount != null) 'soldCount': soldCount,
  };
  Map<String, dynamic> toJson() => toMap();

  /// Writable product details exclude values owned by trusted backend writers.
  Map<String, dynamic> toWriteMap() => toMap()
    ..remove('rating')
    ..remove('reviewCount')
    ..remove('soldCount');

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'] as String,
    artisanId: map['artisanId'] as String,
    name: map['name'] as String,
    category: map['category'] as String,
    price: _number(map, 'price'),
    currency: map['currency'] as String,
    description: map['description'] as String,
    imageUrls: _strings(map, 'imageUrls'),
    stock: map['stock'] as int,
    status: ProductStatus.values.byName(map['status'] as String),
    createdAt: _date(map, 'createdAt'),
    rating: (map['rating'] as num?)?.toDouble(),
    reviewCount: (map['reviewCount'] as num?)?.toInt(),
    soldCount: (map['soldCount'] as num?)?.toInt(),
  );
  factory Product.fromJson(Map<String, dynamic> json) => Product.fromMap(json);
}

class CartItem {
  const CartItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final int quantity;
  final double unitPrice;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
  Map<String, dynamic> toJson() => toMap();
  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    productId: map['productId'] as String,
    quantity: map['quantity'] as int,
    unitPrice: _number(map, 'unitPrice'),
  );
  factory CartItem.fromJson(Map<String, dynamic> json) =>
      CartItem.fromMap(json);
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId, productName;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'imageUrl': imageUrl,
    'unitPrice': unitPrice,
    'quantity': quantity,
  };
  Map<String, dynamic> toJson() => toMap();
  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: map['productId'] as String,
    productName: map['productName'] as String,
    imageUrl: map['imageUrl'] as String?,
    unitPrice: _number(map, 'unitPrice'),
    quantity: map['quantity'] as int,
  );
  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      OrderItem.fromMap(json);
}

class Order {
  Order({
    required this.id,
    required this.buyerId,
    required this.artisanId,
    this.courierId,
    required List<OrderItem> items,
    required this.status,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    this.updatedAt,
    this.recipientName = '',
    this.recipientPhone = '',
    this.pickupAddress = '',
    this.pickupName = '',
    this.deliveryInstructions = '',
    this.courierEarnings,
    this.currency = 'USD',
  }) : items = List.unmodifiable(items);

  final String id, buyerId, artisanId, deliveryAddress, paymentMethod;
  final String? courierId;
  final String currency;
  final String recipientName,
      recipientPhone,
      pickupAddress,
      pickupName,
      deliveryInstructions;
  final List<OrderItem> items;
  final OrderStatus status;
  final double subtotal, deliveryFee, total;
  // Set by the trusted payout backend; the customer delivery fee is separate.
  final double? courierEarnings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'buyerId': buyerId,
    'artisanId': artisanId,
    'courierId': courierId,
    'items': items.map((item) => item.toMap()).toList(),
    'status': status.name,
    'deliveryAddress': deliveryAddress,
    'paymentMethod': paymentMethod,
    if (recipientName.isNotEmpty) 'recipientName': recipientName,
    if (recipientPhone.isNotEmpty) 'recipientPhone': recipientPhone,
    if (pickupAddress.isNotEmpty) 'pickupAddress': pickupAddress,
    if (pickupName.isNotEmpty) 'pickupName': pickupName,
    if (deliveryInstructions.isNotEmpty)
      'deliveryInstructions': deliveryInstructions,
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'currency': currency,
    if (courierEarnings != null) 'courierEarnings': courierEarnings,
    'total': total,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
  Map<String, dynamic> toJson() => toMap();
  factory Order.fromMap(Map<String, dynamic> map) => Order(
    id: map['id'] as String,
    buyerId: map['buyerId'] as String,
    artisanId: map['artisanId'] as String,
    courierId: map['courierId'] as String?,
    items: (map['items'] as List)
        .map(
          (item) => OrderItem.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    status: OrderStatus.values.byName(map['status'] as String),
    deliveryAddress: map['deliveryAddress'] as String,
    paymentMethod: map['paymentMethod'] as String,
    recipientName: map['recipientName'] as String? ?? '',
    recipientPhone: map['recipientPhone'] as String? ?? '',
    pickupAddress: map['pickupAddress'] as String? ?? '',
    pickupName: map['pickupName'] as String? ?? '',
    deliveryInstructions: map['deliveryInstructions'] as String? ?? '',
    courierEarnings: (map['courierEarnings'] as num?)?.toDouble(),
    currency: map['currency'] as String? ?? 'USD',
    subtotal: _number(map, 'subtotal'),
    deliveryFee: _number(map, 'deliveryFee'),
    total: _number(map, 'total'),
    createdAt: _date(map, 'createdAt'),
    updatedAt: map['updatedAt'] == null ? null : _date(map, 'updatedAt'),
  );
  factory Order.fromJson(Map<String, dynamic> json) => Order.fromMap(json);
}

class Review {
  const Review({
    required this.id,
    required this.artisanId,
    required this.buyerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id, artisanId, buyerId, comment;
  final double rating;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'artisanId': artisanId,
    'buyerId': buyerId,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };
  Map<String, dynamic> toJson() => toMap();
  factory Review.fromMap(Map<String, dynamic> map) => Review(
    id: map['id'] as String,
    artisanId: map['artisanId'] as String,
    buyerId: map['buyerId'] as String,
    rating: _number(map, 'rating'),
    comment: map['comment'] as String,
    createdAt: _date(map, 'createdAt'),
  );
  factory Review.fromJson(Map<String, dynamic> json) => Review.fromMap(json);
}

class Conversation {
  Conversation({
    required this.id,
    required List<String> participantIds,
    this.lastMessage,
    required this.updatedAt,
  }) : participantIds = List.unmodifiable(participantIds);

  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'participantIds': participantIds,
    'lastMessage': lastMessage,
    'updatedAt': updatedAt.toIso8601String(),
  };
  Map<String, dynamic> toJson() => toMap();
  factory Conversation.fromMap(Map<String, dynamic> map) => Conversation(
    id: map['id'] as String,
    participantIds: _strings(map, 'participantIds'),
    lastMessage: map['lastMessage'] as String?,
    updatedAt: _date(map, 'updatedAt'),
  );
  factory Conversation.fromJson(Map<String, dynamic> json) =>
      Conversation.fromMap(json);
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id, conversationId, senderId, text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
  Map<String, dynamic> toJson() => toMap();
  factory Message.fromMap(Map<String, dynamic> map) => Message(
    id: map['id'] as String,
    conversationId: map['conversationId'] as String,
    senderId: map['senderId'] as String,
    text: map['text'] as String,
    createdAt: _date(map, 'createdAt'),
  );
  factory Message.fromJson(Map<String, dynamic> json) => Message.fromMap(json);
}
