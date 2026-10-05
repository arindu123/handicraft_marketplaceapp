import 'package:flutter/material.dart';

import '../../routes/route_names.dart';
import '../../shared/data/profile_repository.dart';
import '../auth/models/marketplace_role.dart';
import '../delivery/widgets/delivery_profile_editor.dart';

class CollectorProfileIcon extends StatefulWidget {
  const CollectorProfileIcon({super.key, this.repository});
  final ProfileRepository? repository;

  @override
  State<CollectorProfileIcon> createState() => _CollectorProfileIconState();
}

class _CollectorProfileIconState extends State<CollectorProfileIcon> {
  late final Stream<Map<String, dynamic>>? _profile =
      widget.repository?.auth.currentUser == null
      ? null
      : widget.repository!.watch();

  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>>(
    stream: _profile,
    builder: (context, snapshot) {
      final photo = snapshot.data?['photoUrl'] as String? ?? '';
      return Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFCEDBD5)),
        ),
        child: ClipOval(
          child: ColoredBox(
            color: const Color(0xFFE6EFEB),
            child: photo.isEmpty
                ? const Icon(
                    Icons.person_outline,
                    size: 21,
                    color: Color(0xFF10494D),
                  )
                : Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person_outline,
                      size: 21,
                      color: Color(0xFF10494D),
                    ),
                  ),
          ),
        ),
      );
    },
  );
}

class CollectorProfileHeader extends StatefulWidget {
  const CollectorProfileHeader({super.key, this.repository});
  final ProfileRepository? repository;

  @override
  State<CollectorProfileHeader> createState() => _CollectorProfileHeaderState();
}

class _CollectorProfileHeaderState extends State<CollectorProfileHeader> {
  late final Stream<Map<String, dynamic>>? _profile =
      widget.repository?.auth.currentUser == null
      ? null
      : widget.repository!.watch();

  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>>(
    stream: _profile,
    builder: (context, snapshot) {
      final data = snapshot.data;
      final guest = _profile == null;
      final name =
          data?['displayName'] as String? ??
          (guest ? 'Hello, collector' : 'Your collection starts here');
      void edit() {
        if (guest) {
          Navigator.pushNamed(
            context,
            RouteNames.signIn,
            arguments: MarketplaceRole.buyer,
          );
        } else if (data != null) {
          Navigator.push(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => DeliveryProfileEditor(
                repository: widget.repository!,
                profile: data,
              ),
            ),
          );
        }
      }

      return Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE6EFEB), Color(0xFFF7EEE1)],
          ),
        ),
        child: Column(
          children: [
            const Text(
              'YOUR LITTLE WORLD OF CRAFT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.6,
                color: Color(0xFF10494D),
              ),
            ),
            const SizedBox(height: 22),
            Semantics(
              label: 'Change profile photo',
              button: true,
              child: InkWell(
                onTap: guest || data != null ? edit : null,
                customBorder: const CircleBorder(),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10494D)
                                .withValues(alpha: .12),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(
                          fontSize: 36,
                          color: Color(0xFF10494D),
                        ),
                        child: ProfileAvatar(
                          name: name,
                          url: data?['photoUrl'] as String? ?? '',
                          radius: 62,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10494D),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10494D),
              ),
            ),
            if (data?['email'] is String) ...[
              const SizedBox(height: 5),
              Text(
                data!['email'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF687571)),
              ),
            ],
            const SizedBox(height: 12),
            const Chip(
              avatar: Icon(
                Icons.spa_outlined,
                size: 16,
                color: Color(0xFFB8512B),
              ),
              label: Text(
                'Thoughtful collector',
                style: TextStyle(fontSize: 11),
              ),
              side: BorderSide.none,
              backgroundColor: Color(0xFFFCF9F2),
            ),
            const SizedBox(height: 12),
            if (snapshot.hasError)
              const Text(
                'Could not load your profile. Check your connection.',
                textAlign: TextAlign.center,
              ),
            if (!guest && data == null && !snapshot.hasError)
              const LinearProgressIndicator(),
            OutlinedButton.icon(
              onPressed: guest || data != null ? edit : null,
              icon: Icon(guest ? Icons.login : Icons.edit_outlined, size: 16),
              label: Text(
                guest ? 'Sign in to personalise' : 'Edit profile & photo',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10494D),
                side: const BorderSide(color: Color(0xFFB7CBC3)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
