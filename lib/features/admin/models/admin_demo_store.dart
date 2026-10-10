
import 'dart:async';

import '../../../shared/data/marketplace_repository.dart';
import '../../../shared/models/domain_models.dart' as canonical;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/delivery_fee_policy.dart';
import '../services/admin_operations_repository.dart';
import 'admin_operations.dart';
import 'admin_notice.dart';

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
    this.status, {
    this.courierId,
    this.updatedAt,
  });
  final String id, customer, product, studio;
  final int amount;
  String status;
  String? courierId;
  final DateTime? updatedAt;
  bool get canAssignCourier => ['confirmed', 'courierAssigned'].contains(status);
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
  final MarketplaceRepository? _repository;
  bool _disposed = false;
  bool get connected => _repository != null;
  DeliveryFeePolicy deliveryPolicy = const DeliveryFeePolicy();
  bool settingsLoaded = false;
  final reports = <AdminReport>[];
  final activity = <AdminActivity>[];
  final readNoticeIds = <String>{};
  bool noticePreferencesLoaded = false;
  bool reportNotifications = true;
  List<AdminNotice> get notifications {
    final notices = <AdminNotice>[
      if (applicationNotifications) for (final approval in approvals.where((item) => item.status == 'Pending'))
        AdminNotice(category: 'applications', targetId: approval.id, title: 'Application awaiting review',
          body: approval.name, revision: 'pending'),
      if (orderNotifications) for (final order in orders)
        AdminNotice(category: 'orders', targetId: order.id, title: 'Order ${order.status}',
          body: order.product, revision: '${order.status}:${order.updatedAt?.toUtc().toIso8601String() ?? ''}', date: order.updatedAt),
      if (reportNotifications) for (final report in reports.where((item) => item.status == 'Open'))
        AdminNotice(category: 'reports', targetId: report.sourcePath, title: '${report.kind} complaint',
          body: report.reason, revision: report.createdAt?.toUtc().toIso8601String() ?? 'open', date: report.createdAt),
    ];
    notices.sort((a, b) => (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)));
    return notices.take(100).toList();
  }
  int get unreadNotifications => notifications.where((notice) => !readNoticeIds.contains(notice.id)).length;
  final _reportSources = <String, Map<String, dynamic>>{};
  final _resolutions = <String, Map<String, dynamic>>{};
  AdminOperationsRepository get operations => AdminOperationsRepository(
    _repository ?? (throw const MarketplaceFailure('Connect to Firebase to save changes.')),
  );
  final _subscriptions = <StreamSubscription<dynamic>>[];
  String? error;
  AdminDemoStore({MarketplaceRepository? backend})
      : _repository = backend ?? (MarketplaceBackend.enabled ? MarketplaceRepository() : null) {
    // Never expose the legacy preview fixtures. When Firebase is unavailable
    // the dashboard must show an empty/error state instead of fake activity.
    orders.clear();
    products.clear();
    users.clear();
    couriers.clear();
    approvals.clear();
    if (!connected) {
      error = 'Live marketplace data is unavailable. Sign in to Firebase to load the admin workspace.';
      return;
    }
    // Read the canonical collections. Deployed rules deny these global reads
    // until a trusted administrative authorization mechanism is supplied.
    final repo = _repository!;
    _subscriptions.add(repo.db.collection('adminPreferences').doc(repo.uid).snapshots().listen((snapshot) {
      if (_disposed) return;
      final preferences = snapshot.data() ?? {};
      applicationNotifications = preferences['applications'] != false;
      orderNotifications = preferences['orders'] != false;
      reportNotifications = preferences['reports'] != false;
      noticePreferencesLoaded = true;
      notifyListeners();
    }, onError: _failed));
    _subscriptions.add(repo.db.collection('adminNotificationReads').doc(repo.uid)
        .collection('events').snapshots().listen((snapshot) {
      if (_disposed) return;
      readNoticeIds.clear();
      readNoticeIds.addAll(snapshot.docs.map((document) => document.id));
      notifyListeners();
    }, onError: _failed));
    _subscriptions.add(repo.db.collection('marketplaceSettings').doc('deliveryLkr')
        .snapshots().listen((snapshot) {
      if (_disposed) return;
      try {
        deliveryPolicy = DeliveryFeePolicy.fromMap(snapshot.data());
        settingsLoaded = true;
        notifyListeners();
      } catch (error) { _failed(error); }
    }, onError: _failed));
    void listenReports(Query<Map<String, dynamic>> query, String prefix) {
      _subscriptions.add(query.snapshots().listen((snapshot) {
        if (_disposed) return;
        _reportSources.removeWhere((path, _) => prefix == 'delivery'
            ? path.startsWith('orders/') : path.startsWith('marketplaceReports/'));
        for (final document in snapshot.docs) {
          _reportSources[document.reference.path] = document.data();
        }
        _refreshReports();
      }, onError: _failed));
    }
    listenReports(repo.db.collectionGroup('deliveryIssues'), 'delivery');
    listenReports(repo.db.collection('marketplaceReports'), 'manual');
    _subscriptions.add(repo.db.collection('reportResolutions').snapshots().listen((snapshot) {
      if (_disposed) return;
      _resolutions.clear();
      for (final document in snapshot.docs) {
        _resolutions[document.data()['sourcePath'] as String] = document.data();
      }
      _refreshReports();
    }, onError: _failed));
    _subscriptions.add(repo.db.collection('adminActivity')
        .orderBy('createdAt', descending: true).limit(100).snapshots().listen((snapshot) {
      if (_disposed) return;
      activity.clear();
      activity.addAll(snapshot.docs.map((document) => AdminActivity.fromMap(document.data())));
      notifyListeners();
    }, onError: _failed));
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
              courierId: o.courierId,
              updatedAt: o.updatedAt ?? o.createdAt,
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
    if (_disposed) return;
    error = marketplaceError(e);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
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
  bool productReportResolved = true;
  bool deliveryIssueResolved = true;
  int get pending => approvals.where((item) => item.status == 'Pending').length;
  int get activeArtisans => users
      .where((item) => item.active && item.detail.startsWith('Artisan'))
      .length;
  int get revenue => orders.fold(0, (total, order) => total + order.amount);
  int get attentionCount =>
      pending + reports.where((report) => report.status == 'Open').length;

  void _refreshReports() {
    reports.clear();
    reports.addAll(_reportSources.entries.map((entry) =>
        AdminReport.fromMap(entry.key, entry.value, _resolutions[entry.key])));
    reports.sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
    productReportResolved = !reports.any((report) => report.kind == 'Product' && report.status == 'Open');
    deliveryIssueResolved = !reports.any((report) => report.kind != 'Product' && report.status == 'Open');
    notifyListeners();
  }

  Future<void> saveDeliveryPolicy(DeliveryFeePolicy policy) => operations.saveDeliveryPolicy(policy);

  void decide(AdminApproval item, bool approved) {
    if (connected) {
      operations.change('artisanProfiles', item.id, approved ? 'Artisan approved' : 'Artisan rejected',
          {'verificationStatus': approved ? 'verified' : 'rejected'}).catchError(_failed);
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
    if (connected) {
      final mapped = {
        'Pending': 'pending',
        'Processing': 'confirmed',
        'Shipped': 'onTheWay',
        'Delivered': 'delivered',
      }[status];
      if (mapped != null) {
        operations.change('orders', order.id, 'Order status updated', {
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
    if (connected) {
      operations.change(item.collection, item.id, item.collection == 'products'
          ? 'Product visibility updated' : 'Account availability updated',
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
    if (connected) {
      operations.change('artisanProfiles', item.id, 'Artisan approved',
          {'verificationStatus': 'verified'}).catchError(_failed);
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

  Future<void> setNotifications({bool? applications, bool? orders, bool? reports}) async {
    final repo = _repository ?? (throw const MarketplaceFailure('Connect to Firebase to save preferences.'));
    await repo.requireRole(canonical.UserRole.admin);
    final reference = repo.db.collection('adminPreferences').doc(repo.uid);
    await repo.db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final before = snapshot.data() ?? {};
      transaction.set(reference, {
        'applications': applications ?? before['applications'] ?? true,
        'orders': orders ?? before['orders'] ?? true,
        'reports': reports ?? before['reports'] ?? true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markNoticeRead(AdminNotice notice) async {
    final repo = _repository ?? (throw const MarketplaceFailure('Connect to Firebase to read notifications.'));
    await repo.requireRole(canonical.UserRole.admin);
    await repo.db.collection('adminNotificationReads').doc(repo.uid).collection('events')
        .doc(notice.id).set({'readAt': FieldValue.serverTimestamp()});
  }
}

String adminMoney(int amount) =>
    'Rs. ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';
