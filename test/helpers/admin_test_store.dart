import 'package:artisan_marketplace/features/admin/models/admin_demo_store.dart';

// Explicit widget-test fixtures. Production constructors remain empty offline;
// these records never bypass Firebase authorization or enter a running app.
AdminDemoStore adminTestStore() {
  final store = AdminDemoStore()..error = null;
  store.approvals.addAll(<AdminApproval>[
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
  ]);
  store.orders.addAll(<AdminOrder>[
    AdminOrder(
      'CR-2048',
      'Amaya Perera',
      'Fluted terracotta vase',
      null,
      'Atelier Oread',
      7200,
      'Processing',
    ),
    AdminOrder(
      'CR-2047',
      'Nimal Silva',
      'Stoneware dinner set',
      null,
      'Clay House',
      14500,
      'Shipped',
    ),
    AdminOrder(
      'CR-2046',
      'Sachi Fernando',
      'Handmade coffee cups',
      null,
      'Kiln & Co',
      3800,
      'Delivered',
    ),
    AdminOrder(
      'CR-2045',
      'Ruwan Jayasuriya',
      'Textured ceramic collection',
      null,
      'Atelier Oread',
      12000,
      'Delivered',
    ),
    AdminOrder(
      'CR-2044',
      'Nethmi Dias',
      'Glazed serving bowl',
      null,
      'Clay House',
      6400,
      'Pending',
    ),
    AdminOrder(
      'CR-2043',
      'Kavindu De Silva',
      'Decorative amphora',
      null,
      'Kiln & Co',
      9500,
      'Processing',
    ),
  ]);
  store.users.addAll(<AdminDirectoryItem>[
    AdminDirectoryItem('Amaya Perera', 'Buyer · Colombo'),
    AdminDirectoryItem('Nimal Silva', 'Buyer · Galle'),
    AdminDirectoryItem('Atelier Oread', 'Artisan · Colombo'),
    AdminDirectoryItem('Clay House', 'Artisan · Nugegoda'),
    AdminDirectoryItem('Kiln & Co', 'Artisan · Kandy'),
  ]);
  store.products.addAll(<AdminDirectoryItem>[
    AdminDirectoryItem('Fluted terracotta vase', 'Atelier Oread · Rs. 7,200'),
    AdminDirectoryItem('Stoneware dinner set', 'Clay House · Rs. 14,500'),
    AdminDirectoryItem('Handmade coffee cups', 'Kiln & Co · Rs. 3,800'),
    AdminDirectoryItem('Glazed serving bowl', 'Clay House · Rs. 6,400'),
  ]);
  store.couriers.addAll(<AdminDirectoryItem>[
    AdminDirectoryItem(
      'Lanka Fragile Express',
      'Colombo · 12 sample deliveries',
    ),
    AdminDirectoryItem(
      'Southern Studio Dispatch',
      'Galle · 8 sample deliveries',
    ),
  ]);
  return store;
}
