import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/auth/models/marketplace_role.dart';
import 'package:artisan_marketplace/features/auth/widgets/auth_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(1280, 900),
  ]) {
    testWidgets('Buyer login fits $size with keyboard and enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            settings: const RouteSettings(arguments: MarketplaceRole.buyer),
            builder: (_) => const AuthForm(isSignUp: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign In to Collection'));
      await tester.tap(find.text('Sign In to Collection'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
