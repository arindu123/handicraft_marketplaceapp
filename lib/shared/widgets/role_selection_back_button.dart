import 'package:flutter/material.dart';

import '../../features/auth/models/marketplace_role.dart';
import '../../routes/route_names.dart';

class RoleSelectionBackButton extends StatelessWidget {
  const RoleSelectionBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Back to role selection',
    icon: const Icon(Icons.arrow_back),
    onPressed: () => Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.roleSelection,
      (_) => false,
      arguments: AuthEntry.signIn,
    ),
  );
}
