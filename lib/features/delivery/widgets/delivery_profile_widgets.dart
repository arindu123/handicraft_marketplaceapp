import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'delivery_widgets.dart';

class DeliveryProfileHeading extends StatelessWidget {
  const DeliveryProfileHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontFamily: 'CormorantGaramond',
          fontSize: 29,
          height: 1.15,
          color: DeliveryStyle.ink,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: DeliveryStyle.muted,
        ),
      ),
    ],
  );
}

class DeliveryProfilePortrait extends StatelessWidget {
  const DeliveryProfilePortrait({super.key, required this.avatar, this.onEdit});
  final Widget avatar;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.surface, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: DeliveryStyle.ink.withValues(alpha: .08),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(padding: const EdgeInsets.all(4), child: avatar),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton.filled(
              tooltip: 'Choose profile photo',
              onPressed: onEdit,
              style: IconButton.styleFrom(
                backgroundColor: DeliveryStyle.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: DeliveryStyle.orange.withValues(
                  alpha: .35,
                ),
                disabledForegroundColor: Colors.white,
                side: const BorderSide(color: AppColors.background, width: 3),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
            ),
          ),
        ],
      ),
    ),
  );
}

class DeliveryProfileField extends StatelessWidget {
  const DeliveryProfileField({
    super.key,
    required this.label,
    required this.icon,
    this.controller,
    this.value,
    this.readOnly = false,
    this.enabled = true,
    this.maxLength,
    this.validator,
    this.onChanged,
  });
  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final String? value;
  final bool readOnly, enabled;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: DeliveryStyle.orange),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: DeliveryStyle.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? value : null,
          readOnly: readOnly,
          enabled: enabled,
          maxLength: maxLength,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: DeliveryStyle.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            hintText: readOnly ? 'Not provided' : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: readOnly
                ? const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: DeliveryStyle.muted,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surface),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surface),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DeliveryStyle.orange),
            ),
          ),
        ),
      ],
    ),
  );
}

class DeliveryCompletedSummary extends StatelessWidget {
  const DeliveryCompletedSummary({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DeliveryStyle.peach,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_shipping_outlined,
            color: DeliveryStyle.orange,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count ${count == 1 ? 'delivery' : 'deliveries'} completed',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DeliveryStyle.ink,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Your completed delivery history',
                style: TextStyle(fontSize: 11, color: DeliveryStyle.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
