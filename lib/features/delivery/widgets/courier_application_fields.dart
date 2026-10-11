import 'package:flutter/material.dart';

const courierVehicleTypes = ['Bike', 'Three-wheeler', 'Van'];

class CourierApplicationFields extends StatelessWidget {
  const CourierApplicationFields({
    super.key,
    required this.phone,
    required this.area,
    required this.vehicleType,
    required this.onVehicleChanged,
  });

  final TextEditingController phone;
  final TextEditingController area;
  final String? vehicleType;
  final ValueChanged<String?> onVehicleChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: phone,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.telephoneNumber],
        decoration: const InputDecoration(
          hintText: 'Mobile number',
          prefixIcon: Icon(Icons.phone_outlined, size: 19),
        ),
        validator: (value) {
          final phone = value?.trim() ?? '';
          if (phone.isEmpty) return 'Enter your mobile number.';
          final digits = phone.replaceAll(RegExp(r'\D'), '');
          if (phone.length > 40 ||
              !RegExp(r'^\+?[0-9 ()-]+$').hasMatch(phone) ||
              digits.length < 7 ||
              digits.length > 15) {
            return 'Enter a valid mobile number.';
          }
          return null;
        },
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: area,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          hintText: 'Delivery area',
          prefixIcon: Icon(Icons.location_on_outlined, size: 19),
        ),
        validator: (value) {
          final area = value?.trim() ?? '';
          if (area.isEmpty) return 'Enter your delivery area.';
          return area.length > 100 ? 'Use at most 100 characters.' : null;
        },
      ),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        initialValue: vehicleType,
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: 'Vehicle type',
          prefixIcon: Icon(Icons.two_wheeler_outlined, size: 19),
        ),
        items: courierVehicleTypes
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: onVehicleChanged,
        validator: (value) =>
            value == null ? 'Select your vehicle type.' : null,
      ),
    ],
  );
}
