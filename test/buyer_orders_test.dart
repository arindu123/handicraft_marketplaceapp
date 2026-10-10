import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Disconnected checkout cannot fabricate a confirmed order', () {
    final demo = BuyerDemo();
    expect(
      () => demo.createOrder({demoProducts.first: 1}, 134),
      throwsA(isA<MarketplaceFailure>()),
    );
    expect(demo.orders, isEmpty);
    demo.dispose();
  });
}
