import 'dart:io';
import 'dart:ui' as ui;
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  testWidgets('Render implemented home', (tester) async {
    MarketplaceBackend.enabled = false;
    final bytes = File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync();
    await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('preview'),
      child: MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(fontFamily: 'Roboto'), home: const BuyerMarketplace())));
    await tester.runAsync(() async {
      await precacheImage(const AssetImage('lib/features/auth/widgets/pottery_vase.png'), tester.element(find.byType(BuyerMarketplace)));
    });
    await tester.pump(const Duration(milliseconds: 500));
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('preview')));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('tmp/craftisan-home-preview.png').writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
