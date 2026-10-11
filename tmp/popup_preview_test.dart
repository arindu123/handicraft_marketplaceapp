import 'dart:io';
import 'dart:ui' as ui;
import 'package:artisan_marketplace/core/theme/app_theme.dart';
import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:artisan_marketplace/shared/widgets/craftisan_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
 testWidgets('Profile preview', (tester) async {
  final fontBytes = File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync();
  await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(fontBytes)))).load();
  await (FontLoader('sans-serif')..addFont(Future.value(ByteData.sublistView(fontBytes)))).load();
  await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  await (FontLoader('CormorantGaramond')..addFont(rootBundle.load('lib/core/theme/cormorant_garamond.ttf'))).load();
  tester.view.physicalSize = const Size(390,844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db=FakeFirebaseFirestore();
  await db.doc('users/buyer').set({'displayName':'Nimal Perera','email':'nimal@example.com','role':'buyer'});
  final demo=BuyerDemo(backend: MarketplaceRepository(firestore:db,auth:MockFirebaseAuth(mockUser:MockUser(uid:'buyer'),signedIn:true),loadRole:()async=>UserRole.buyer));
  final key=GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,theme:AppTheme.light,home:BuyerProfile(demo:demo))));
  await tester.pumpAndSettle();
  final profileContext = tester.element(find.byType(BuyerProfile));
  showDialog<void>(context: profileContext, builder: (context) => CraftisanDialog(
    icon: Icons.logout_rounded,
    title: const Text('Log out of Craftisan?'),
    content: const Text('Your saved pieces and orders will be here when you return.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () {}, child: const Text('Log Out'))],
  ));
  await tester.pumpAndSettle();
  final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final img=await boundary.toImage(pixelRatio:2);
    final bytes=await img.toByteData(format:ui.ImageByteFormat.png);
    await File('tmp/craftisan-popup-preview.png').writeAsBytes(bytes!.buffer.asUint8List());
  });
  await tester.pumpWidget(const SizedBox());
  demo.dispose();
 });
}
