import 'package:artisan_marketplace/features/delivery/screens/delivery_access_guard.dart';
import 'package:artisan_marketplace/features/delivery/screens/delivery_home_screen.dart';
import 'package:artisan_marketplace/features/delivery/screens/delivery_login_screen.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final role in <UserRole?>[
    null,
    UserRole.buyer,
    UserRole.artisan,
    UserRole.admin,
  ]) {
    testWidgets('$role cannot open the delivery workspace', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DeliveryAccessGuard(restore: () async => role)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DeliveryLoginScreen), findsOneWidget);
      expect(find.byType(DeliveryHomeScreen), findsNothing);
      expect(find.textContaining('Quick Track as Guest'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Server verification failure prevents delivery entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeliveryAccessGuard(
          restore: () async => throw Exception('Offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DeliveryLoginScreen), findsOneWidget);
    expect(find.byType(DeliveryHomeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Verified courier can enter delivery workspace', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeliveryAccessGuard(restore: () async => UserRole.courier),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DeliveryHomeScreen), findsOneWidget);
    expect(find.byType(DeliveryLoginScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
