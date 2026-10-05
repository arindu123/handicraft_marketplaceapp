import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/features/auth/screens/role_selection_screen.dart';
import 'package:artisan_marketplace/features/buyer/buyer_landing_screen.dart';
import 'package:artisan_marketplace/routes/route_names.dart';

void main() {
  testWidgets('Buyer opens landing then login with buyer role', (tester) async {
    Object? role;
    await tester.pumpWidget(
      MaterialApp(
        home: const RoleSelectionScreen(),
        routes: {
          RouteNames.buyerLanding: (_) => const BuyerLandingScreen(),
          RouteNames.signIn: (context) {
            role = ModalRoute.of(context)!.settings.arguments;
            return const Scaffold(body: Text('Buyer login'));
          },
        },
      ),
    );
    await tester.tap(find.text('Buyer / Patron'));
    await tester.pumpAndSettle();
    expect(find.text('Continue to login'), findsOneWidget);
    expect(role, isNull);
    await tester.ensureVisible(find.text('Continue to login'));
    await tester.tap(find.text('Continue to login'));
    await tester.pumpAndSettle();
    expect(role, MarketplaceRole.buyer);
    expect(find.text('Buyer login'), findsOneWidget);
    final context = tester.element(find.text('Buyer login'));
    Navigator.pop(context);
    await tester.pumpAndSettle();
    expect(find.text('Roles Selection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
