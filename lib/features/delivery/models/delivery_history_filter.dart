import 'delivery_order.dart';

class DeliveryHistoryFilter {
  static bool matches(
    DeliveryOrder order, {
    String scope = 'All',
    DeliveryStatus? status,
    DateTime? from,
    DateTime? through,
  }) {
    if (scope == 'Completed' && !order.delivered ||
        scope == 'Active' && order.delivered) {
      return false;
    }
    if (status != null && order.status != status) return false;
    if (from == null && through == null) return true;
    final date = (order.delivered ? order.completedAt : order.createdAt)
        ?.toLocal();
    if (date == null) return false;
    final start = from == null
        ? null
        : DateTime(from.year, from.month, from.day);
    final end = through == null
        ? null
        : DateTime(through.year, through.month, through.day + 1);
    return (start == null || !date.isBefore(start)) &&
        (end == null || date.isBefore(end));
  }
}
