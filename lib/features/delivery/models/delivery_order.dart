class DeliveryOrder {
  DeliveryOrder({
    required this.id,
    required this.title,
    required this.pickup,
    required this.destination,
    required this.service,
    this.delivered = false,
  });
  final String id;
  final String title;
  final String pickup;
  final String destination;
  final String service;
  bool delivered;

  static List<DeliveryOrder> demoOrders() => [
    DeliveryOrder(
      id: 'CR-2048',
      title: 'Handcrafted ceramic vase',
      pickup: 'Oread Pottery Studio, Colombo 07',
      destination: '42 Flower Road, Colombo 03',
      service: 'Fragile parcel',
    ),
    DeliveryOrder(
      id: 'CR-2047',
      title: 'Stoneware dinner set',
      pickup: 'Clay House, Nugegoda',
      destination: '18 Lake Road, Rajagiriya',
      service: 'Truck',
    ),
    DeliveryOrder(
      id: 'CR-2046',
      title: 'Artisan coffee cups',
      pickup: 'Kiln & Co, Colombo 05',
      destination: '8 Park Avenue, Colombo 06',
      service: 'Ride',
      delivered: true,
    ),
  ];
}
