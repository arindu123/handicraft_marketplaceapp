import '../../../shared/models/domain_models.dart' as domain;

enum DeliveryStatus {
  pending('Pending', 'Accept Delivery'),
  accepted('Accepted', 'Mark as Picked Up'),
  pickedUp('Picked Up', 'Start Delivery'),
  onTheWay('On The Way', 'Mark as Delivered'),
  delivered('Delivered', null);

  const DeliveryStatus(this.label, this.action);
  final String label;
  final String? action;
}

class DeliveryOrder {
  DeliveryOrder({
    required this.id,
    required this.title,
    required this.pickup,
    required this.destination,
    required this.service,
    this.earnings = 0,
    this.recipientName = '',
    this.recipientPhone = '',
    this.pickupName = '',
    this.instructions = '',
    this.deliveryFee,
    DeliveryStatus status = DeliveryStatus.pending,
    // Keep status read-only to callers so demo actions cannot skip milestones.
    // ignore: prefer_initializing_formals
  }) : _status = status;
  final String id;
  final String title;
  final String pickup;
  final String destination;
  final String service;
  final double earnings;
  final String recipientName, recipientPhone, pickupName, instructions;
  final double? deliveryFee;

  factory DeliveryOrder.fromOrder(domain.Order order) {
    final lines = order.deliveryAddress.split('\n');
    final legacy =
        order.recipientName.isEmpty &&
        order.recipientPhone.isEmpty &&
        lines.length >= 5 &&
        RegExp(r'^\+?[\d ()-]{7,40}$').hasMatch(lines.last.trim());
    return DeliveryOrder(
      id: order.id,
      title: order.items
          .map((item) => '${item.productName} × ${item.quantity}')
          .join(', '),
      pickup: order.pickupAddress,
      pickupName: order.pickupName,
      destination: legacy
          ? lines.sublist(1, lines.length - 1).join('\n')
          : order.deliveryAddress,
      recipientName: legacy ? lines.first : order.recipientName,
      recipientPhone: legacy ? lines.last : order.recipientPhone,
      instructions: order.deliveryInstructions,
      deliveryFee: order.deliveryFee,
      service: 'Fragile parcel',
      status: switch (order.status) {
        domain.OrderStatus.courierAssigned => DeliveryStatus.accepted,
        domain.OrderStatus.pickedUp => DeliveryStatus.pickedUp,
        domain.OrderStatus.onTheWay => DeliveryStatus.onTheWay,
        domain.OrderStatus.delivered => DeliveryStatus.delivered,
        _ => DeliveryStatus.pending,
      },
    );
  }
  DeliveryStatus _status;
  DeliveryStatus get status => _status;
  void syncStatus(DeliveryStatus value) => _status = value;
  bool get delivered => _status == DeliveryStatus.delivered;

  /// Advances one milestone only; completion is terminal for this demo session.
  void advance() {
    if (!delivered) _status = DeliveryStatus.values[_status.index + 1];
  }

  static List<DeliveryOrder> demoOrders() => [
    DeliveryOrder(
      id: 'CR-2048',
      title: 'Handcrafted ceramic vase',
      pickup: 'Oread Pottery Studio, Colombo 07',
      destination: '42 Flower Road, Colombo 03',
      service: 'Fragile parcel',
      earnings: 850,
    ),
    DeliveryOrder(
      id: 'CR-2047',
      title: 'Stoneware dinner set',
      pickup: 'Clay House, Nugegoda',
      destination: '18 Lake Road, Rajagiriya',
      service: 'Truck',
      earnings: 1200,
    ),
    DeliveryOrder(
      id: 'CR-2046',
      title: 'Artisan coffee cups',
      pickup: 'Kiln & Co, Colombo 05',
      destination: '8 Park Avenue, Colombo 06',
      service: 'Ride',
      earnings: 650,
      status: DeliveryStatus.delivered,
    ),
  ];
}
