import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/routes/app_routes.dart';
import 'package:artisan_marketplace/routes/route_names.dart';

Future<void> openRoute(WidgetTester tester, String route) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      initialRoute: route,
      routes: AppRoutes.routes,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('New courier sees sign up first and can switch to login', (
    tester,
  ) async {
    await openRoute(tester, RouteNames.roleSelection);
    await tapText(tester, 'Fragile Delivery Courier');
    await tapText(tester, 'Continue');
    expect(find.text('CRAFTISAN DELIVERY'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Create your courier account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Welcome Back'), findsNothing);
    await tapText(tester, 'Sign Up');
    expect(find.text('Enter your name.'), findsOneWidget);
    await tapText(tester, 'Log In');
    expect(find.text('Welcome Back'), findsOneWidget);
    await tapText(tester, 'Log In');
    expect(find.text('Enter your email or phone number.'), findsOneWidget);
    await tapText(tester, 'Quick Track as Guest  →');
    expect(find.text('Guest Courier'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    await tapText(tester, 'Account');
    await tapText(tester, 'Back to role selection');
    expect(find.text('Roles Selection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Demo booking validates addresses and updates only demo orders', (
    tester,
  ) async {
    await openRoute(tester, RouteNames.deliveryHome);
    await tapText(tester, 'Book now →');
    await tapText(tester, 'Create demo request');
    expect(find.text('Please complete this field.'), findsNWidgets(3));
    await tester.enterText(find.byType(TextFormField).at(0), 'Pottery Studio');
    await tester.enterText(find.byType(TextFormField).at(1), 'Collector House');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Test ceramic bowl',
    );
    await tapText(tester, 'Create demo request');
    expect(find.text('My Orders'), findsOneWidget);
    await tapText(tester, 'Test ceramic bowl');
    expect(find.text('Pottery Studio'), findsOneWidget);
    await tapText(tester, 'Accept Delivery');
    await tapText(tester, 'Mark as Picked Up');
    await tapText(tester, 'Start Delivery');
    await tapText(tester, 'Mark as Delivered');
    await tapText(tester, 'Back to My Orders');
    await tester.pumpAndSettle();
    await tapText(tester, 'Completed');
    expect(find.text('Test ceramic bowl'), findsOneWidget);
    await tapText(tester, 'Wallet');
    await tapText(tester, 'Top Up');
    expect(
      find.text(
        'This is a demo wallet. No funds are held and no payments or top-ups can be made.',
      ),
      findsOneWidget,
    );
    await tapText(tester, 'Got it');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Service search filters and resets', (tester) async {
    await openRoute(tester, RouteNames.deliveryHome);
    await tester.enterText(find.byType(TextField), 'unavailable');
    await tester.pumpAndSettle();
    expect(
      find.text('No services found. Try Ride, Transit, Car, Truck or Send.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Truck'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delivery login and tabs fit small screens and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openRoute(tester, RouteNames.deliveryLogin);
    expect(tester.takeException(), isNull);
    await tapText(tester, 'Sign Up');
    expect(tester.takeException(), isNull);
    await tapText(tester, 'Quick Track as Guest  →');
    expect(tester.takeException(), isNull);
    for (final tab in ['Orders', 'Wallet', 'Account', 'Home']) {
      await tester.tap(find.widgetWithText(NavigationDestination, tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
