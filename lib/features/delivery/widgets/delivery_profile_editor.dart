import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/data/marketplace_repository.dart';
import '../../../shared/data/profile_repository.dart';
import 'delivery_widgets.dart';
import 'delivery_profile_widgets.dart';
import '../../../core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.url = '',
    this.bytes,
    this.radius = 22,
  });
  final String name;
  final String url;
  final Uint8List? bytes;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final initials = words
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
    final fallback = Center(child: Text(initials.isEmpty ? '?' : initials));
    return ClipOval(
      child: SizedBox.square(
        dimension: radius * 2,
        child: ColoredBox(
          color: DeliveryStyle.peach,
          child: bytes != null
              ? Image.memory(
                  bytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => fallback,
                )
              : url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => fallback,
                )
              : fallback,
        ),
      ),
    );
  }
}

class DeliveryProfileEditor extends StatefulWidget {
  const DeliveryProfileEditor({
    super.key,
    required this.repository,
    required this.profile,
    this.completedDeliveries,
  });
  final ProfileRepository repository;
  final Map<String, dynamic> profile;
  final int? completedDeliveries;

  @override
  State<DeliveryProfileEditor> createState() => _DeliveryProfileEditorState();
}

class _DeliveryProfileEditorState extends State<DeliveryProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.profile['displayName'] as String? ?? '',
  );
  late final _area = TextEditingController(
    text: widget.profile['area'] as String? ?? '',
  );
  Uint8List? _photo;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;
      if (await image.length() > 5 * 1024 * 1024) {
        throw const MarketplaceFailure('Choose a photo smaller than 5 MB.');
      }
      final bytes = await image.readAsBytes();
      if (mounted) setState(() => _photo = bytes);
    } catch (error) {
      if (mounted) setState(() => _error = marketplaceError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.save(
        displayName: _name.text,
        area: _area.text,
        photo: _photo,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = marketplaceError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Theme(
      data: DeliveryStyle.theme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text('My Profile', style: TextStyle(fontSize: 16)),
          leading: IconButton(
            tooltip: 'Back to profile',
            onPressed: _busy ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const DeliveryProfileHeading(
                      title: 'Profile Information',
                      subtitle:
                          'Manage your delivery identity and contact details.',
                    ),
                    const SizedBox(height: 24),
                    DeliveryProfilePortrait(
                      onEdit: _busy ? null : _pickPhoto,
                      avatar: ProfileAvatar(
                        name: _name.text,
                        url: widget.profile['photoUrl'] as String? ?? '',
                        bytes: _photo,
                        radius: 44,
                      ),
                    ),
                    const SizedBox(height: 24),
                    DeliveryProfileField(
                      label: 'Full name',
                      icon: Icons.person_outline,
                      controller: _name,
                      enabled: !_busy,
                      maxLength: 100,
                      onChanged: (_) => setState(() {}),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your name.'
                          : null,
                    ),
                    DeliveryProfileField(
                      label: 'Email address',
                      icon: Icons.mail_outline,
                      value: widget.profile['email'] as String? ?? '',
                      readOnly: true,
                    ),
                    DeliveryProfileField(
                      label: 'Mobile number',
                      icon: Icons.phone_outlined,
                      value:
                          widget.profile['phone'] as String? ??
                          widget.repository.auth.currentUser?.phoneNumber ??
                          '',
                      readOnly: true,
                    ),
                    DeliveryProfileField(
                      label: 'Delivery area',
                      icon: Icons.location_on_outlined,
                      controller: _area,
                      enabled: !_busy,
                      maxLength: 100,
                    ),
                    if (widget.completedDeliveries != null) ...[
                      DeliveryCompletedSummary(
                        count: widget.completedDeliveries!,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: DeliveryStyle.theme.colorScheme.error,
                          ),
                        ),
                      ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: DeliveryStyle.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _busy ? null : _save,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(_busy ? 'Please wait...' : 'Save changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
