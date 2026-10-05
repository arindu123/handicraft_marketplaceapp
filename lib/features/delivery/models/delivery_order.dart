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
    DateTime? createdAt,
    this.completedAt,
    this.earningsConfirmed = true,
    DeliveryStatus status = DeliveryStatus.pending,
    // Keep status read-only to callers so demo actions cannot skip milestones.
    // ignore: prefer_initializing_formals
  }) : _status = status,
       createdAt = createdAt ?? DateTime.now();
  final String id;
  final String title;
  final String pickup;
  final String destination;
  final String service;
  final double earnings;
  final String recipientName, recipientPhone, pickupName, instructions;
  final double? deliveryFee;
  final DateTime createdAt;
  DateTime? completedAt;
  final bool earningsConfirmed;

  bool createdOn(DateTime day) => _sameDay(createdAt.toLocal(), day.toLocal());

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static double earningsBetween(
    Iterable<DeliveryOrder> orders,
    DateTime start,
    DateTime end,
  ) => orders
      .where((order) {
        final completed = order.completedAt;
        return order.delivered &&
            order.earningsConfirmed &&
            completed != null &&
            !completed.isBefore(start) &&
            completed.isBefore(end);
      })
      .fold(0.0, (total, order) => total + order.earnings);

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
      createdAt: order.createdAt,
      completedAt: order.status == domain.OrderStatus.delivered
          ? order.updatedAt
          : null,
      earnings: order.courierEarnings ?? 0,
      earningsConfirmed: order.courierEarnings != null,
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
    if (!delivered) {
      _status = DeliveryStatus.values[_status.index + 1];
      if (delivered) completedAt = DateTime.now();
    }
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
      completedAt: DateTime.now(),
    ),
  ];
}
