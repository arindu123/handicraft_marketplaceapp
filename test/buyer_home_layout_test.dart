import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/features/buyer/handicraft_navigation_bar.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [(320.0, 1.0), (390.0, 2.0), (768.0, 1.0)]) {
    testWidgets('Home sections scroll above fixed navigation at $size', (
      tester,
    ) async {
      MarketplaceBackend.enabled = false;
      final db = FakeFirebaseFirestore();
      final repository = MarketplaceRepository(
        firestore: db,
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'buyer'),
          signedIn: true,
        ),
        loadRole: () async => UserRole.buyer,
      );
      for (var i = 0; i < 3; i++) {
        final product = Product(
          id: 'piece-$i',
          artisanId: 'maker',
          name: 'Handmade piece $i',
          category: ['Ceramics', 'Textiles', 'Woodwork'][i],
          price: 20 + i.toDouble(),
          currency: 'USD',
          description: 'Made with care',
          imageUrls: [],
          stock: 5,
          status: ProductStatus.active,
          createdAt: DateTime(2026, 10, i + 1),
        );
        await db.collection('products').doc(product.id).set(product.toMap());
      }
      await tester.binding.setSurfaceSize(Size(size.$1, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(size.$2)),
            child: child!,
          ),
          home: BuyerMarketplace(backend: repository),
        ),
      );
      await tester.pumpAndSettle();
      final bottom = tester.getTopLeft(find.byType(HandicraftNavigationBar));
      final vertical = find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      for (final section in [
        'Shop by Category',
        'Featured Collections',
        'Trending Handmade',
        'Special Handmade Finds',
        'New Arrivals',
        'Recommended for You',
      ]) {
        await tester.scrollUntilVisible(
          find.text(section),
          200,
          scrollable: vertical,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getTopLeft(find.byType(HandicraftNavigationBar)), bottom);
      }
      tester.state<ScrollableState>(vertical).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Handmade piece 1');
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(find.widgetWithText(FilledButton, 'Search')),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();
      expect(find.byType(BuyerSearch), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Handmade piece 1',
      );
      expect(find.text('1 pieces found'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
