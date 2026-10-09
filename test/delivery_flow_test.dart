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
  testWidgets('System back from delivery opens roles instead of welcome', (
    tester,
  ) async {
    await openRoute(tester, RouteNames.deliveryHome);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Roles Selection'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard opened as the root can return to role selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: AppRoutes.routes,
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: RouteNames.deliveryHome),
            builder: AppRoutes.routes[RouteNames.deliveryHome]!,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    await tester.tap(find.byTooltip('Back to role selection'));
    await tester.pumpAndSettle();
    expect(find.text('Roles Selection'), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Role selection works after signup clears navigation history', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: AppRoutes.routes,
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: RouteNames.deliveryHome),
            builder: AppRoutes.routes[RouteNames.deliveryHome]!,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Profile');
    await tester.scrollUntilVisible(
      find.text('Back to role selection'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    await tapText(tester, 'Back to role selection');
    expect(find.text('Roles Selection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
    expect(find.text('Enter your email address.'), findsOneWidget);
    await tapText(tester, 'Quick Track as Guest  →');
    expect(find.text('Kasun Perera'), findsOneWidget);
    expect(find.text("Today's orders"), findsOneWidget);
    await tapText(tester, 'Profile');
    await tester.scrollUntilVisible(
      find.text('Back to role selection'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    await tapText(tester, 'Back to role selection');
    expect(find.text('Roles Selection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rider views, accepts and completes an order with earnings', (
    tester,
  ) async {
    await openRoute(tester, RouteNames.deliveryHome);
    expect(find.text('2 deliveries\nwaiting today'), findsOneWidget);
    expect(find.text('Book now'), findsNothing);
    await tapText(tester, 'View orders');
    expect(find.text('My Orders'), findsOneWidget);
    await tapText(tester, 'Handcrafted ceramic vase');
    await tapText(tester, 'Accept Delivery');
    await tapText(tester, 'Mark as Picked Up');
    await tapText(tester, 'Start Delivery');
    await tapText(tester, 'Mark as Delivered');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Delivery code'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm delivery'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Back to My Orders');
    await tapText(tester, 'Completed');
    expect(find.text('Handcrafted ceramic vase'), findsOneWidget);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Earnings'));
    await tester.pumpAndSettle();
    expect(find.text('Rs. 1500.00'), findsNWidgets(2));
    await tapText(tester, 'Cash out');
    expect(
      find.text('Payouts are not connected yet. No cash out has been made.'),
      findsOneWidget,
    );
    await tapText(tester, 'Got it');
    await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
    await tester.pumpAndSettle();
    expect(find.text('1 delivery\nwaiting today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Order ID search filters and resets', (tester) async {
    await openRoute(tester, RouteNames.deliveryHome);
    await tester.enterText(find.byType(TextField), 'unavailable');
    await tester.pumpAndSettle();
    expect(find.text('No orders found for this ID.'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('CR-2048'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'cr-2047');
    await tester.pumpAndSettle();
    expect(find.text('CR-2047'), findsOneWidget);
    expect(find.text('CR-2048'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Availability is shared between home and profile', (
    tester,
  ) async {
    await openRoute(tester, RouteNames.deliveryHome);
    expect(find.text('Online'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Offline'), findsOneWidget);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Kasun Perera'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
    await tester.pumpAndSettle();
    expect(find.text('Online'), findsOneWidget);
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
    for (final tab in ['Orders', 'Earnings', 'Profile', 'Home']) {
      await tester.tap(find.widgetWithText(NavigationDestination, tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
