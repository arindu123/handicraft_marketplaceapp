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

      final avatar = Semantics(
        label: 'Change profile photo',
        button: true,
        child: InkWell(
          onTap: guest || data != null ? edit : null,
          customBorder: const CircleBorder(),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x180B4545),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ProfileAvatar(
                  name: name,
                  url: data?['photoUrl'] as String? ?? '',
                  radius: 54,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B4545),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 21,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      final details = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              '?  COLLECTOR',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.4,
                color: Color(0xFF0B4545),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B4545),
            ),
          ),
          if (data?['email'] is String) ...[
            const SizedBox(height: 6),
            Text(
              data!['email'] as String,
              style: const TextStyle(fontSize: 13, color: Color(0xFF676760)),
            ),
          ],
          const SizedBox(height: 12),
          if (snapshot.hasError)
            const Text(
              'Could not load your profile. Check your connection.',
              style: TextStyle(color: Color(0xFF923B24)),
            ),
          if (!guest && data == null && !snapshot.hasError)
            const LinearProgressIndicator(),
          OutlinedButton.icon(
            onPressed: guest || data != null ? edit : null,
            icon: Icon(guest ? Icons.login : Icons.edit_outlined, size: 18),
            label: Text(guest ? 'Sign in to personalise' : 'Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B4545),
              minimumSize: const Size(48, 48),
              side: const BorderSide(color: Color(0xFF0B4545)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: const _CollectorPattern(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth < 285 ||
                    MediaQuery.textScalerOf(context).scale(14) > 20;
                return stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [avatar, const SizedBox(height: 20), details],
                      )
                    : Row(
                        children: [
                          avatar,
                          const SizedBox(width: 24),
                          Expanded(child: details),
                        ],
                      );
              },
            ),
          ),
        ),
      );
    },
  );
}

/// Reuse the existing editor for the account-settings entry too.
Future<void> openCollectorProfileEditor(
  BuildContext context,
  ProfileRepository repository,
) async {
  try {
    final snapshot = await repository.db
        .collection('users')
        .doc(repository.uid)
        .get();
    final data = snapshot.data();
    if (data == null) throw StateError('Profile is missing');
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<bool>(
        builder: (_) =>
            DeliveryProfileEditor(repository: repository, profile: data),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open your profile. Check your connection and try again.',
          ),
        ),
      );
    }
  }
}

class _CollectorPattern extends CustomPainter {
  const _CollectorPattern();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF0E4D5),
    );
    canvas.drawCircle(
      const Offset(-12, -16),
      size.width * .26,
      Paint()..color = const Color(0xFFE4C49E),
    );
    canvas.drawCircle(
      Offset(size.width + 12, -12),
      size.width * .18,
      Paint()..color = const Color(0xFF87967A),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .72,
        size.height * .72,
        size.width * .4,
        size.height * .5,
      ),
      Paint()..color = const Color(0xFFE4C49E),
    );
    canvas.drawCircle(
      Offset(-20, size.height + 48),
      100,
      Paint()..color = const Color(0xFFB44A2C).withValues(alpha: .7),
    );
    final stem = Paint()
      ..color = const Color(0xFF0B4545).withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final origin in [
      Offset(14, size.height * .35),
      Offset(size.width - 14, size.height * .6),
    ]) {
      canvas.drawLine(origin, origin + const Offset(-16, -90), stem);
      for (var i = 0; i < 4; i++) {
        final y = origin.dy - i * 22;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(origin.dx + 6, y - 10),
            width: 25,
            height: 10,
          ),
          stem,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CollectorPattern oldDelegate) => false;
}
