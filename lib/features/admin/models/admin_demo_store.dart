import '../../../shared/data/community_repository.dart';

import 'dart:async';

import '../../../shared/data/marketplace_repository.dart';
import '../../../shared/models/domain_models.dart' as canonical;

import 'package:flutter/foundation.dart';

class AdminApproval {
  AdminApproval(this.id, this.name, this.type, this.location, this.description);
  final String id, name, type, location, description;
  String status = 'Pending';
}

class AdminOrder {
  AdminOrder(
    this.id,
    this.customer,
    this.product,
    this.studio,
    this.amount,
    this.status,
  );
  final String id, customer, product, studio;
  final int amount;
  String status;
}

class AdminDirectoryItem {
  AdminDirectoryItem(
    this.name,
    this.detail, {
    this.verification = 'Pending',
    this.id = '',
    this.collection = 'users',
  });
  final String name, detail, id, collection;
  bool active = true;
  String verification;
  bool get isArtisan => detail.startsWith('Artisan');
}

// Session-only sample data: no network, account authorization or real payments.
class AdminDemoStore extends ChangeNotifier {
  final _subscriptions = <StreamSubscription<dynamic>>[];
  String? error;
  AdminDemoStore() {
    // Never expose the legacy preview fixtures. When Firebase is unavailable
    // the dashboard must show an empty/error state instead of fake activity.
    orders.clear();
    products.clear();
    users.clear();
    couriers.clear();
    approvals.clear();
    if (!MarketplaceBackend.enabled) {
      error = 'Live marketplace data is unavailable. Sign in to Firebase to load the admin workspace.';
      return;
    }
    // Read the canonical collections. Deployed rules deny these global reads
    // until a trusted administrative authorization mechanism is supplied.
    final repo = MarketplaceRepository();
    _subscriptions.add(
      repo.db.collection('users').snapshots().listen((snapshot) {
        final previous = {for (final u in users) u.id: u};
        users.clear();
        couriers.clear();
        for (final d in snapshot.docs) {
          final data = d.data();
          final role = data['role'] as String? ?? '';
          final item =
              previous[d.id] ??
              AdminDirectoryItem(
                data['displayName'] as String? ?? d.id,
                '${role.isEmpty ? '' : role[0].toUpperCase() + role.substring(1)} ? ${data['email'] ?? ''}',
                id: d.id,
              );
          item.active = data['active'] != false;
          users.add(item);
          if (role == 'courier') couriers.add(item);
        }
        notifyListeners();
      }, onError: _failed),
    );
    _subscriptions.add(
      repo.db.collection('artisanProfiles').snapshots().listen((snapshot) {
        approvals.clear();
        for (final d in snapshot.docs) {
          final data = d.data();
          final status = data['verificationStatus'] as String? ?? 'pending';
          final item = AdminApproval(
            d.id,
            data['studioName'] as String? ?? d.id,
            'Artisan',
            data['location'] as String? ?? '',
            data['bio'] as String? ?? '',
          );
          item.status = status == 'verified'
              ? 'Approved'
              : status == 'rejected'
              ? 'Rejected'
              : 'Pending';
          approvals.add(item);
          for (final u in users.where((u) => u.id == d.id)) {
            u.verification = item.status;
          }
        }
        notifyListeners();
      }, onError: _failed),
    );
    _subscriptions.add(
      repo.db.collection('orders').snapshots().listen((snapshot) {
        orders.clear();
        orders.addAll(
          snapshot.docs.map((d) {
            final o = canonical.Order.fromMap({...d.data(), 'id': d.id});
            return AdminOrder(
              o.id,
              o.buyerId,
              o.items.map((i) => i.productName).join(', '),
              o.artisanId,
              o.total.round(),
              o.status.name,
            );
          }),
        );
        notifyListeners();
      }, onError: _failed),
    );
    _subscriptions.add(
      repo.db.collection('products').snapshots().listen((snapshot) {
        products.clear();
        products.addAll(
          snapshot.docs.map((d) {
            final p = canonical.Product.fromMap({...d.data(), 'id': d.id});
            return AdminDirectoryItem(
              p.name,
              '${p.artisanId} - ${p.price}',
              id: p.id,
              collection: 'products',
            )..active = p.status == canonical.ProductStatus.active;
          }),
        );
        notifyListeners();
      }, onError: _failed),
    );
  }
  void _failed(Object e) {
    error = marketplaceError(e);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  final approvals = <AdminApproval>[
    AdminApproval(
      'AP-108',
      'Earth & Ember Studio',
      'Artisan',
      'Galle, Sri Lanka',
      'Small-batch stoneware made with local clay. Sample application includes a studio profile, six product photographs and a maker statement.',
    ),
    AdminApproval(
      'AP-109',
      'Nila Ceramics',
      'Artisan',
      'Kandy, Sri Lanka',
      'Hand-thrown tableware and decorative vessels. Sample application includes a workshop profile and an eight-piece collection.',
    ),
    AdminApproval(
      'AP-110',
      'Careful Carry',
      'Courier',
      'Colombo, Sri Lanka',
      'Fragile-goods courier application with packaging and handling information. All application details in this preview are illustrative.',
    ),
  ];
  final orders = <AdminOrder>[
    AdminOrder(
      'CR-2048',
      'Amaya Perera',
      'Fluted terracotta vase',
      'Atelier Oread',
      7200,
      'Processing',
    ),
    AdminOrder(
      'CR-2047',
      'Nimal Silva',
      'Stoneware dinner set',
      'Clay House',
      14500,
      'Shipped',
    ),
    AdminOrder(
      'CR-2046',
      'Sachi Fernando',
      'Handmade coffee cups',
      'Kiln & Co',
      3800,
      'Delivered',
    ),
    AdminOrder(
      'CR-2045',
      'Ruwan Jayasuriya',
      'Textured ceramic collection',
      'Atelier Oread',
      12000,
      'Delivered',
    ),
    AdminOrder(
      'CR-2044',
      'Nethmi Dias',
      'Glazed serving bowl',
      'Clay House',
      6400,
      'Pending',
    ),
    AdminOrder(
      'CR-2043',
      'Kavindu De Silva',
      'Decorative amphora',
      'Kiln & Co',
      9500,
      'Processing',
    ),
  ];
  final users = <AdminDirectoryItem>[
    AdminDirectoryItem('Amaya Perera', 'Buyer · Colombo'),
    AdminDirectoryItem('Nimal Silva', 'Buyer · Galle'),
    AdminDirectoryItem('Atelier Oread', 'Artisan · Colombo'),
    AdminDirectoryItem('Clay House', 'Artisan · Nugegoda'),
    AdminDirectoryItem('Kiln & Co', 'Artisan · Kandy'),
  ];
  final products = <AdminDirectoryItem>[
    AdminDirectoryItem('Fluted terracotta vase', 'Atelier Oread · Rs. 7,200'),
    AdminDirectoryItem('Stoneware dinner set', 'Clay House · Rs. 14,500'),
    AdminDirectoryItem('Handmade coffee cups', 'Kiln & Co · Rs. 3,800'),
    AdminDirectoryItem('Glazed serving bowl', 'Clay House · Rs. 6,400'),
  ];
  final couriers = <AdminDirectoryItem>[
    AdminDirectoryItem(
      'Lanka Fragile Express',
      'Colombo · 12 sample deliveries',
    ),
    AdminDirectoryItem(
      'Southern Studio Dispatch',
      'Galle · 8 sample deliveries',
    ),
  ];
  bool applicationNotifications = true;
  bool orderNotifications = true;
  bool productReportResolved = false;
  bool deliveryIssueResolved = false;
  int get pending => approvals.where((item) => item.status == 'Pending').length;
  int get activeArtisans => users
      .where((item) => item.active && item.detail.startsWith('Artisan'))
      .length;
  int get revenue => orders.fold(0, (sum, order) => sum + order.amount);
  int get attentionCount =>
      pending +
      (productReportResolved ? 0 : 1) +
      (deliveryIssueResolved ? 0 : 1);

  void decide(AdminApproval item, bool approved) {
    if (MarketplaceBackend.enabled) {
      CommunityRepository()
          .verify(
            item.id,
            approved
                ? canonical.VerificationStatus.verified
                : canonical.VerificationStatus.rejected,
          )
          .catchError(_failed);
      return;
    }
    if (item.status != 'Pending') return;
    item.status = approved ? 'Approved' : 'Rejected';
    if (approved) {
      final record = AdminDirectoryItem(
        item.name,
        '${item.type} · ${item.location}',
        verification: 'Approved',
      );
      (item.type == 'Courier' ? couriers : users).add(record);
    }
    notifyListeners();
  }

  void updateOrder(AdminOrder order, String status) {
    if (MarketplaceBackend.enabled) {
      final mapped = {
        'Pending': 'pending',
        'Processing': 'confirmed',
        'Shipped': 'onTheWay',
        'Delivered': 'delivered',
      }[status];
      if (mapped != null) {
        MarketplaceRepository().db
            .collection('orders')
            .doc(order.id)
            .update({
              'status': mapped,
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
            })
            .catchError(_failed);
      }
      return;
    }
    order.status = status;
    notifyListeners();
  }

  void toggleItem(AdminDirectoryItem item) {
    if (MarketplaceBackend.enabled) {
      MarketplaceRepository().db
          .collection(item.collection)
          .doc(item.id)
          .update(
            item.collection == 'products'
                ? {'status': item.active ? 'hidden' : 'active'}
                : {'active': !item.active},
          )
          .catchError(_failed);
      return;
    }
    item.active = !item.active;
    notifyListeners();
  }

  void verifyArtisan(AdminDirectoryItem item) {
    if (MarketplaceBackend.enabled) {
      CommunityRepository()
          .verify(item.id, canonical.VerificationStatus.verified)
          .catchError(_failed);
      return;
    }
    if (!users.contains(item) ||
        !item.isArtisan ||
        item.verification == 'Approved') {
      return;
    }
    item.verification = 'Approved';
    notifyListeners();
  }

  void resolveIssue(bool product) {
    if (MarketplaceBackend.enabled) {
      error = 'No persisted issue record is available for this action.';
      notifyListeners();
      return;
    }
    if (product) {
      productReportResolved = true;
    } else {
      deliveryIssueResolved = true;
    }
    notifyListeners();
  }

  void setNotifications({bool? applications, bool? orders}) {
    if (MarketplaceBackend.enabled) {
      error = 'Notification delivery is not configured.';
      notifyListeners();
      return;
    }
    applicationNotifications = applications ?? applicationNotifications;
    orderNotifications = orders ?? orderNotifications;
    notifyListeners();
  }
}

String adminMoney(int amount) =>
    'Rs. ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';
