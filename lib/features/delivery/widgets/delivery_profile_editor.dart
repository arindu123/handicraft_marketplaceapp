import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/data/marketplace_repository.dart';
import '../../../shared/data/profile_repository.dart';

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
          color: const Color(0xFFFFE7D5),
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
  });
  final ProfileRepository repository;
  final Map<String, dynamic> profile;

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
    child: Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ProfileAvatar(
                name: _name.text,
                url: widget.profile['photoUrl'] as String? ?? '',
                bytes: _photo,
                radius: 48,
              ),
            ),
            TextButton.icon(
              onPressed: _busy ? null : _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Choose profile photo'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              enabled: !_busy,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your name.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _area,
              enabled: !_busy,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Delivery area'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Please wait...' : 'Save profile'),
            ),
          ],
        ),
      ),
    ),
  );
}
