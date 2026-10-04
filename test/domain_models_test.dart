import 'package:flutter_test/flutter_test.dart';

import 'package:artisan_marketplace/shared/models/domain_models.dart';

void main() {
  test('Order serialization preserves canonical fields and enum values', () {
    final order = Order(
      id: 'order-1',
      buyerId: 'buyer-1',
      artisanId: 'artisan-1',
      items: const [
        OrderItem(
          productId: 'product-1',
          productName: 'Vase',
          unitPrice: 120,
          quantity: 1,
        ),
      ],
      status: OrderStatus.courierAssigned,
      deliveryAddress: '42 Flower Road',
      paymentMethod: 'cashOnDelivery',
      subtotal: 120,
      deliveryFee: 14,
      total: 134,
      createdAt: DateTime.utc(2026, 1, 2),
    );

    final restored = Order.fromJson(order.toJson());

    expect(restored.status, OrderStatus.courierAssigned);
    expect(restored.courierId, isNull);
    expect(restored.items.single.productId, 'product-1');
    expect(restored.createdAt, DateTime.utc(2026, 1, 2));
  });

  test('User and Product maps round-trip', () {
    final user = User(
      id: 'artisan-1',
      role: UserRole.artisan,
      name: 'Elena',
      email: 'elena@example.com',
      phone: '+94 77 000 0000',
      active: true,
      createdAt: DateTime.utc(2026),
    );
    final product = Product(
      id: 'product-1',
      artisanId: user.id,
      name: 'Vase',
      category: 'Terracotta',
      price: 120,
      currency: 'USD',
      description: 'Hand-thrown.',
      imageUrls: const ['https://example.com/vase.jpg'],
      stock: 1,
      status: ProductStatus.active,
      createdAt: DateTime.utc(2026),
    );

    expect(User.fromMap(user.toMap()).role, UserRole.artisan);
    expect(Product.fromJson(product.toJson()).imageUrls, product.imageUrls);
  });
}
