class DeliveryFeePolicy {
  const DeliveryFeePolicy({this.fee = 14, this.freeDeliveryThreshold = 250});

  final double fee;
  final double freeDeliveryThreshold;

  double feeFor(double subtotal) => subtotal >= freeDeliveryThreshold ? 0 : fee;

  static bool validAmount(double value, double maximum) =>
      value.isFinite &&
      value >= 0 &&
      value <= maximum &&
      (value * 100 - (value * 100).round()).abs() < 0.000001;

  bool get isValid =>
      validAmount(fee, 100000) && validAmount(freeDeliveryThreshold, 10000000);

  factory DeliveryFeePolicy.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const DeliveryFeePolicy();
    if (data['currency'] != 'LKR' ||
        data['fee'] is! num ||
        data['freeDeliveryThreshold'] is! num) {
      throw const FormatException('Invalid delivery fee settings.');
    }
    final policy = DeliveryFeePolicy(
      fee: (data['fee'] as num).toDouble(),
      freeDeliveryThreshold: (data['freeDeliveryThreshold'] as num).toDouble(),
    );
    if (!policy.isValid) {
      throw const FormatException('Invalid delivery fee settings.');
    }
    return policy;
  }
}
