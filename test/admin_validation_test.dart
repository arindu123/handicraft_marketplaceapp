import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/features/admin/models/admin_demo_store.dart';

void main() {
  late AdminDemoStore store;
  setUp(() => store = AdminDemoStore());
  tearDown(() => store.dispose());

  test('Only pending applications in the store can be reviewed', () {
    final application = AdminApproval(
      'a1',
      'Studio',
      'Artisan',
      'Galle',
      'Bio',
    );
    store.decide(application, true);
    expect(application.status, 'Pending');
    store.approvals.add(application);
    store.decide(application, true);
    expect(application.status, 'Approved');
    store.decide(application, false);
    expect(application.status, 'Approved');
    expect(store.users, hasLength(1));
  });

  test('Invalid and completed order updates leave the record unchanged', () {
    final order = AdminOrder('o1', 'Buyer', 'Vase', 'Studio', 100, 'Pending');
    store.orders.add(order);
    store.updateOrder(order, 'invalid');
    expect(order.status, 'Pending');
    store.updateOrder(order, 'Processing');
    expect(order.status, 'Processing');
    store.updateOrder(order, 'Delivered');
    expect(order.status, 'Processing');
    order.status = 'Shipped';
    store.updateOrder(order, 'Delivered');
    store.updateOrder(order, 'Pending');
    expect(order.status, 'Delivered');
  });

  test('Order transitions match admin delivery permissions', () {
    for (final status in AdminOrder.statusLabels.keys) {
      final order = AdminOrder('o1', 'Buyer', 'Vase', 'Studio', 100, status);
      store.orders
        ..clear()
        ..add(order);
      final next = {
        'pending': 'Processing',
        'pickedUp': 'Shipped',
        'onTheWay': 'Delivered',
      }[status];
      for (final target in ['Pending', 'Processing', 'Shipped', 'Delivered']) {
        order.status = status;
        store.updateOrder(order, target);
        expect(order.status, target == next ? target : status);
      }
    }
  });

  test('Invalid document IDs cannot be reviewed', () {
    for (final id in ['', ' ', ' a1', 'a1 ', '.', '..', 'a/b']) {
      final application = AdminApproval(
        id,
        'Studio',
        'Artisan',
        'Galle',
        'Bio',
      );
      store.approvals.add(application);
      store.decide(application, true);
      expect(application.status, 'Pending');
    }
  });

  test('Rejected artisan profiles cannot be directly verified', () {
    final artisan = AdminDirectoryItem(
      'Studio',
      'Artisan',
      verification: 'Rejected',
    );
    store.users.add(artisan);
    store.verifyArtisan(artisan);
    expect(artisan.verification, 'Rejected');
  });

  test('Removed records and unexpected collections cannot be toggled', () {
    final item = AdminDirectoryItem('Buyer', 'Buyer');
    store.toggleItem(item);
    expect(item.active, isTrue);
    store.users.add(item);
    store.toggleItem(item);
    expect(item.active, isFalse);
    final invalid = AdminDirectoryItem(
      'Invalid',
      'Buyer',
      collection: 'orders',
    );
    store.users.add(invalid);
    store.toggleItem(invalid);
    expect(invalid.active, isTrue);
  });

  test('Verification requires an active artisan belonging to the store', () {
    final buyer = AdminDirectoryItem('Buyer', 'Buyer');
    final artisan = AdminDirectoryItem('Studio', 'Artisan');
    store.users.addAll([buyer, artisan]);
    store.verifyArtisan(buyer);
    expect(buyer.verification, 'Pending');
    artisan.active = false;
    store.verifyArtisan(artisan);
    expect(artisan.verification, 'Pending');
    artisan.active = true;
    store.verifyArtisan(artisan);
    expect(artisan.verification, 'Approved');
  });
}
