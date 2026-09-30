import 'package:flutter/material.dart';

import '../models/delivery_order.dart';
import 'delivery_widgets.dart';

class DeliveryStatusPill extends StatelessWidget {
  const DeliveryStatusPill({super.key, required this.status});
  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DeliveryStatus.pending => const Color(0xFF70665E),
      DeliveryStatus.delivered => const Color(0xFF458269),
      _ => DeliveryStyle.orange,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class DeliveryStatusTracker extends StatelessWidget {
  const DeliveryStatusTracker({super.key, required this.status});
  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (status == DeliveryStatus.accepted)
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: DeliveryStyle.peach.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            children: [
              Icon(Icons.check_circle, color: DeliveryStyle.orange, size: 44),
              SizedBox(height: 10),
              Text(
                'Delivery Accepted',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'Your delivery successfully accepted.\nNext: collect the parcel from the pickup location.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DeliveryStyle.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Milestone Progress · Step ${status.index} of 4',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (final stage in DeliveryStatus.values.skip(1))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Semantics(
                  selected: status == stage,
                  child: Row(
                    children: [
                      Icon(
                        stage.index <= status.index
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: stage.index <= status.index
                            ? DeliveryStyle.orange
                            : DeliveryStyle.muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          stage.label,
                          style: TextStyle(
                            fontWeight: stage == status
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: stage == status
                                ? DeliveryStyle.orange
                                : DeliveryStyle.ink,
                          ),
                        ),
                      ),
                      if (stage == status)
                        const Text(
                          'Current',
                          style: TextStyle(
                            color: DeliveryStyle.orange,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
