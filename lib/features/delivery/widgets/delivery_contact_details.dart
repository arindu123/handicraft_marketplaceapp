import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/delivery_order.dart';

Uri directionsUri(String address) => Uri.https('www.google.com', '/maps/dir/', {
  'api': '1',
  'destination': address.trim(),
  'travelmode': 'driving',
});

Uri? phoneUri(String phone) {
  final normalized = phone.replaceAll(RegExp(r'[\s()-]'), '');
  if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalized)) return null;
  return Uri(scheme: 'tel', path: normalized);
}

class DeliveryContactDetails extends StatelessWidget {
  const DeliveryContactDetails({super.key, required this.order, this.openUrl});
  final DeliveryOrder order;
  final Future<bool> Function(Uri)? openUrl;

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      final opened =
          await (openUrl?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (opened) return;
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uri.scheme == 'tel'
                ? 'Could not open the phone app. Use the number shown above.'
                : 'Could not open Maps. Use the address shown above.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = phoneUri(order.recipientPhone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (order.pickupName.isNotEmpty)
          Text('Pickup studio: ${order.pickupName}'),
        SelectableText(
          order.recipientName.isEmpty
              ? 'Customer name not provided'
              : 'Customer: ${order.recipientName}',
        ),
        const SizedBox(height: 6),
        SelectableText(
          order.recipientPhone.isEmpty
              ? 'Customer phone not provided'
              : order.recipientPhone,
        ),
        if (order.deliveryFee != null)
          Text('Delivery fee: ${order.currency} ${order.deliveryFee!.toStringAsFixed(2)}'),
        if (order.instructions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Delivery instructions: ${order.instructions}'),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: order.pickup.trim().isEmpty
                  ? null
                  : () => _open(context, directionsUri(order.pickup)),
              icon: const Icon(Icons.directions_outlined),
              label: const Text('Pickup directions'),
            ),
            OutlinedButton.icon(
              onPressed: order.destination.trim().isEmpty
                  ? null
                  : () => _open(context, directionsUri(order.destination)),
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Drop-off directions'),
            ),
            OutlinedButton.icon(
              onPressed: phone == null ? null : () => _open(context, phone),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Call customer'),
            ),
          ],
        ),
      ],
    );
  }
}
