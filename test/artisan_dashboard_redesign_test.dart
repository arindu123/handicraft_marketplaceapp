import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/artisan/artisan_dashboard_screen.dart';
import 'package:artisan_marketplace/features/artisan/artisan_dashboard_widgets.dart';
import 'package:artisan_marketplace/features/artisan/artisan_orders_widgets.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MarketplaceRepository repository;

  setUp(() async {
    MarketplaceBackend.enabled = false;
    db = FakeFirebaseFirestore();
    repository = MarketplaceRepository(
      firestore: db,
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'maker'), signedIn: true),
      loadRole: () async => UserRole.artisan,
    );
    await db.doc('users/maker').set({
      'displayName': 'Dilini Perera',
      'role': 'artisan',
    });
    for (final entry in [
      ('vase', 'Clay Vessel', 'Terracotta', ProductStatus.active),
      ('bag', 'Woven Tote', 'Woven', ProductStatus.draft),
      ('bowl', 'Hidden Bowl', 'Tableware', ProductStatus.hidden),
    ]) {
      await db
          .doc('products/${entry.$1}')
          .set(
            Product(
              id: entry.$1,
              artisanId: 'maker',
              name: entry.$2,
              category: entry.$3,
              price: 10,
              currency: 'LKR',
              description: 'Handmade',
              imageUrls: [],
              stock: 3,
              status: entry.$4,
              createdAt: DateTime.utc(2026, 10, 12),
            ).toMap(),
          );
    }
    await db
        .doc('orders/order-a')
        .set(
          Order(
            id: 'order-a',
            buyerId: 'buyer',
            artisanId: 'maker',
            items: const [
              OrderItem(
                productId: 'vase',
                productName: 'Clay Vessel',
                unitPrice: 10,
                quantity: 2,
              ),
              OrderItem(
                productId: 'bag',
                productName: 'Woven Tote',
                unitPrice: 25,
                quantity: 1,
              ),
            ],
            status: OrderStatus.delivered,
            deliveryAddress: 'Colombo',
            paymentMethod: 'Cash on delivery',
            subtotal: 45,
            deliveryFee: 14,
            total: 59,
            currency: 'LKR',
            createdAt: DateTime.utc(2026, 10, 12),
          ).toMap(),
        );
  });

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ArtisanDashboardScreen(backend: repository),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label);
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pumpAndSettle();
    }
    if (target.hitTestable().evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target.hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.tap(target.hitTestable().first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'Live statistics count unique orders and exclude delivery fees from sales',
    (tester) async {
      await open(tester);
      expect(find.text('Welcome back,\nDilini Perera'), findsOneWidget);
      final stats = find.byType(ArtisanStudioStats);
      await tester.scrollUntilVisible(
        stats,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(stats);
      expect(
        find.descendant(of: stats, matching: find.text('LKR 45.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stats, matching: find.text('1')),
        findsOneWidget,
      );
      await db.doc('orders/order-a').update({'status': 'pending'});
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: stats, matching: find.text('No sales yet')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stats, matching: find.text('1 pending')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Product filters use actual status and category search uses live data',
    (tester) async {
      await open(tester);
      await tap(tester, 'Products');
      await tap(tester, 'Drafts');
      expect(find.text('Woven Tote'), findsOneWidget);
      expect(find.text('Clay Vessel'), findsNothing);
      await tap(tester, 'Hidden');
      expect(find.text('Hidden Bowl'), findsOneWidget);
      await tap(tester, 'Pending');
      expect(find.text('No pending products yet.'), findsOneWidget);
      await tap(tester, 'All');
      await tester.enterText(find.byType(TextField), 'Terracotta');
      await tester.pumpAndSettle();
      expect(find.text('Clay Vessel'), findsOneWidget);
      expect(find.text('Woven Tote'), findsNothing);
      await tester.tap(find.byTooltip('Manage Clay Vessel'));
      await tester.pumpAndSettle();
      await tap(tester, 'Edit');
      expect(find.text('Edit Product'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Dashboard search also finds orders and notification button opens orders',
    (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'order-a');
      await tester.pumpAndSettle();
      await tap(tester, '#order-a');
      expect(find.text('Order Details'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Order updates'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Order updates'));
      await tester.pumpAndSettle();
      expect(
        find.text('Artisan Orders'),
        findsNothing,
      ); // The branded header replaces the old app bar.
      expect(find.text("Dilini Perera's Studio Orders"), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Orders search, status counts and sorting use complete real orders',
    (tester) async {
      final other = (await db.doc('orders/order-a').get()).data()!;
      await db.doc('orders/order-b').set({
        ...other,
        'id': 'order-b',
        'status': 'pending',
        'recipientName': 'Nadee Fernando',
        'createdAt': '2026-10-13T00:00:00Z',
        'total': 80.0,
      });
      await db.doc('orders/order-a').update({
        'recipientName': 'Tharindi Perera',
      });
      await open(tester);
      await tap(tester, 'Orders');
      expect(find.text('2 orders'), findsOneWidget);
      expect(find.text('Pending (1)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Tharindi');
      await tester.pumpAndSettle();
      expect(find.byType(ArtisanStudioOrderCard), findsOneWidget);
      expect(
        tester
            .widget<ArtisanStudioOrderCard>(find.byType(ArtisanStudioOrderCard))
            .order
            .id,
        'order-a',
      );
      await tester.enterText(find.byType(TextField), 'Woven Tote');
      await tester.pumpAndSettle();
      expect(find.byType(ArtisanStudioOrderCard), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), 'not-found');
      await tester.pumpAndSettle();
      expect(
        find.text('No orders match your search or status filter.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '');
      await tap(tester, 'Filter');
      await tap(tester, 'Oldest first');
      expect(
        tester
            .widgetList<ArtisanStudioOrderCard>(
              find.byType(ArtisanStudioOrderCard),
            )
            .first
            .order
            .id,
        'order-a',
      );
      await tap(tester, 'Pending (1)');
      expect(
        tester
            .widget<ArtisanStudioOrderCard>(find.byType(ArtisanStudioOrderCard))
            .order
            .id,
        'order-b',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Packing cancellation preserves pending and confirmation advances once',
    (tester) async {
      await db.doc('orders/order-a').update({
        'status': 'pending',
        'recipientName': 'Nadee Fernando',
        'deliveryInstructions': 'Call before arrival',
      });
      await open(tester);
      await tap(tester, 'Orders');
      await tap(tester, 'View Order Details');
      expect(find.text('Clay Vessel'), findsOneWidget);
      expect(find.text('Woven Tote'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Delivery instructions: Call before arrival'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Delivery instructions: Call before arrival'),
        findsOneWidget,
      );
      await tap(tester, 'Mark as Packed');
      await tap(tester, 'Cancel');
      expect(
        (await db.doc('orders/order-a').get()).data()!['status'],
        'pending',
      );
      await tap(tester, 'Mark as Packed');
      await tester.tap(
        find.widgetWithText(FilledButton, 'Mark as Packed').last,
      );
      await tester.pumpAndSettle();
      expect(
        (await db.doc('orders/order-a').get()).data()!['status'],
        'confirmed',
      );
      expect(find.text('Mark as Packed'), findsNothing);
      expect(find.text('Ready for Dispatch'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(find.text('Pending (0)'), findsOneWidget);
      expect(find.text('Ready for Dispatch (1)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('Order status labels retain backend semantics', () {
    expect(studioOrderStatus(OrderStatus.confirmed), 'Ready for Dispatch');
    expect(studioOrderStatus(OrderStatus.courierAssigned), 'Courier Assigned');
    expect(studioOrderStatus(OrderStatus.pickedUp), 'On the Way');
    expect(studioOrderStatus(OrderStatus.onTheWay), 'On the Way');
    expect(studioOrderStatus(OrderStatus.cancelled), 'Cancelled');
  });

  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(768, 1024),
  ]) {
    testWidgets('All dashboard tabs fit $size at 200 percent text', (
      tester,
    ) async {
      await open(tester, size: size, scale: 2);
      for (final label in ['Dashboard', 'Products', 'Orders', 'Profile']) {
        await tap(tester, label);
        if (label == 'Orders') {
          await tap(tester, 'Filter');
          expect(tester.takeException(), isNull);
          Navigator.of(tester.element(find.text('Sort orders'))).pop();
          await tester.pumpAndSettle();
        }
        await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
