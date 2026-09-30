import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/routes/app_routes.dart';
import 'package:artisan_marketplace/routes/route_names.dart';

void main() {
  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Password reset completes locally and returns to sign in', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: RouteNames.signIn,
        routes: AppRoutes.routes,
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'Forgot password?');
    expect(find.text('Recover Your Passcode'), findsOneWidget);
    await tap(tester, 'Send Verification Code');
    expect(find.text('Enter your email address.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'collector@example.com',
    );
    await tap(tester, 'Send Verification Code');
    expect(find.text('Verify Your Identity'), findsOneWidget);
    for (var index = 0; index < 6; index++) {
      await tester.enterText(find.byType(TextField).at(index), '$index');
    }
    await tap(tester, 'Verify & Proceed');
    expect(find.text('Create New Password'), findsOneWidget);
    await tap(tester, 'Reset Password & Continue');
    expect(find.text('Enter a new password.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'craftisan1');
    await tester.enterText(find.byType(TextFormField).at(1), 'different');
    await tap(tester, 'Reset Password & Continue');
    expect(find.text('Passwords do not match.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), 'craftisan1');
    await tap(tester, 'Reset Password & Continue');
    expect(find.text('Password Reset Successful!'), findsOneWidget);
    await tap(tester, 'Back to Sign In');
    expect(find.text('Welcome back to Craftisan'), findsOneWidget);
  });
}
