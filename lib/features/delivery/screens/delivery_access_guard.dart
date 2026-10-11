import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';
import '../../../shared/models/domain_models.dart' show UserRole;
import 'delivery_home_screen.dart';
import 'delivery_login_screen.dart';

/// Requires a server-verified courier role before creating the live workspace.
class DeliveryAccessGuard extends StatefulWidget {
  const DeliveryAccessGuard({super.key, this.restore});
  final Future<UserRole?> Function()? restore;
  @override
  State<DeliveryAccessGuard> createState() => _DeliveryAccessGuardState();
}

class _DeliveryAccessGuardState extends State<DeliveryAccessGuard> {
  late final _role = (widget.restore ?? AuthSession.restore)();
  @override
  Widget build(BuildContext context) => FutureBuilder<UserRole?>(
    future: _role,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!snapshot.hasError && snapshot.data == UserRole.courier) {
        return const DeliveryHomeScreen();
      }
      return const DeliveryLoginScreen();
    },
  );
}
