import 'package:flutter/material.dart';

import '../models/delivery_order.dart';
import '../widgets/delivery_widgets.dart';

class DeliveryRequestScreen extends StatefulWidget {
  const DeliveryRequestScreen({super.key, required this.service});
  final String service;
  @override
  State<DeliveryRequestScreen> createState() => _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState extends State<DeliveryRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _pickup = TextEditingController();
  final _destination = TextEditingController();
  final _parcel = TextEditingController();
  @override
  void dispose() {
    _pickup.dispose();
    _destination.dispose();
    _parcel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DeliveryFrame(
    appBar: AppBar(title: Text('${widget.service} delivery')),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 54,
              color: DeliveryStyle.orange,
            ),
            const SizedBox(height: 18),
            const Text(
              'A careful journey starts here',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Demo booking • No courier will be dispatched and no payment will be taken.',
              style: TextStyle(color: DeliveryStyle.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            _field(_pickup, 'Pickup address', Icons.trip_origin),
            const SizedBox(height: 16),
            _field(
              _destination,
              'Delivery address',
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            _field(
              _parcel,
              'What are you sending?',
              Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 20),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.health_and_safety_outlined,
                color: DeliveryStyle.orange,
              ),
              title: Text('Handle with care'),
              subtitle: Text(
                'Ceramics and stoneware require protective packaging.',
              ),
            ),
            const SizedBox(height: 24),
            DeliveryButton(
              label: 'Create demo request',
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  DeliveryOrder(
                    id: 'DEMO-${DateTime.now().millisecondsSinceEpoch}',
                    title: _parcel.text.trim(),
                    pickup: _pickup.text.trim(),
                    destination: _destination.text.trim(),
                    service: widget.service,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
  ) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.sentences,
    validator: (value) => value == null || value.trim().isEmpty
        ? 'Please complete this field.'
        : null,
  );
}
