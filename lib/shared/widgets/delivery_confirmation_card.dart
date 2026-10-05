import 'package:flutter/material.dart';

import '../data/delivery_workflow_repository.dart';
import '../data/marketplace_repository.dart';

class DeliveryConfirmationCard extends StatefulWidget {
  const DeliveryConfirmationCard({super.key, required this.orderId});
  final String orderId;
  @override
  State<DeliveryConfirmationCard> createState() =>
      _DeliveryConfirmationCardState();
}

class _DeliveryConfirmationCardState extends State<DeliveryConfirmationCard> {
  late Future<String> _code;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _code = DeliveryWorkflowRepository(MarketplaceRepository())
        .confirmationCode(widget.orderId);
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<String>(
        future: _code,
        builder: (context, snapshot) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery confirmation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Share this code with your rider only after receiving your parcel.',
            ),
            const SizedBox(height: 8),
            if (snapshot.hasData)
              SelectableText(
                snapshot.data!,
                style: const TextStyle(
                  fontSize: 28,
                  letterSpacing: 6,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (snapshot.hasError) ...[
              Text(marketplaceError(snapshot.error!)),
              TextButton(
                onPressed: () => setState(_load),
                child: const Text('Retry'),
              ),
            ] else
              const LinearProgressIndicator(),
          ],
        ),
      ),
    ),
  );
}
