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
  AdminDirectoryItem(this.name, this.detail);
  final String name, detail;
  bool active = true;
}

// Session-only sample data: no network, account authorization or real payments.
class AdminDemoStore extends ChangeNotifier {
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
    if (item.status != 'Pending') return;
    item.status = approved ? 'Approved' : 'Rejected';
    if (approved) {
      final record = AdminDirectoryItem(
        item.name,
        '${item.type} · ${item.location}',
      );
      (item.type == 'Courier' ? couriers : users).add(record);
    }
    notifyListeners();
  }

  void updateOrder(AdminOrder order, String status) {
    order.status = status;
    notifyListeners();
  }

  void toggleItem(AdminDirectoryItem item) {
    item.active = !item.active;
    notifyListeners();
  }

  void resolveIssue(bool product) {
    if (product) {
      productReportResolved = true;
    } else {
      deliveryIssueResolved = true;
    }
    notifyListeners();
  }

  void setNotifications({bool? applications, bool? orders}) {
    applicationNotifications = applications ?? applicationNotifications;
    orderNotifications = orders ?? orderNotifications;
    notifyListeners();
  }
}

String adminMoney(int amount) =>
    'Rs. ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';
