import 'dart:async';

import 'package:artisan_marketplace/features/buyer/buyer_demo.dart';
import 'package:artisan_marketplace/features/buyer/buyer_marketplace.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ControlledRepository extends MarketplaceRepository {
  ControlledRepository(FakeFirebaseFirestore db, MockFirebaseAuth auth)
    : super(firestore: db, auth: auth, loadRole: () async => UserRole.buyer);
  Completer<void>? write;
  bool fail = false;
  int writes = 0;
  Stream<Set<String>>? followStream;
  @override
  Stream<Set<String>> followedArtisans() =>
      followStream ?? super.followedArtisans();
  @override
  Future<void> followArtisan(String artisanId, bool selected) async {
    writes++;
    if (write != null) await write!.future;
    if (fail) throw const MarketplaceFailure('Follow could not be saved.');
    return super.followArtisan(artisanId, selected);
  }
}

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late ControlledRepository repository;
  setUp(() {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(mockUser: MockUser(uid: 'buyer'), signedIn: true);
    repository = ControlledRepository(db, auth);
  });

  testWidgets('follow and unfollow persist by UID and survive reopening', (
    tester,
  ) async {
    var demo = BuyerDemo(backend: repository);
    expect(demo.followsLoading, isTrue);
    await tester.pumpAndSettle();
    expect(demo.followsLoading, isFalse);
    await demo.followArtisan(buyerArtisans.first, artisanId: 'artisan-uid');
    await tester.pumpAndSettle();
    expect(demo.followedArtisans, {'artisan-uid'});
    expect(
      (await db.doc('users/buyer/followedArtisans/artisan-uid').get())
          .data()!['artisanId'],
      'artisan-uid',
    );
    demo.dispose();
    demo = BuyerDemo(backend: repository);
    addTearDown(demo.dispose);
    await tester.pumpAndSettle();
    expect(demo.followedArtisans, {'artisan-uid'});
    await demo.followArtisan(buyerArtisans.first, artisanId: 'artisan-uid');
    await tester.pumpAndSettle();
    expect(demo.followedArtisans, isEmpty);
    expect(
      (await db.doc('users/buyer/followedArtisans/artisan-uid').get()).exists,
      isFalse,
    );
  });

  testWidgets(
    'pending writes ignore repeated taps and failures preserve state',
    (tester) async {
      final demo = BuyerDemo(backend: repository);
      addTearDown(demo.dispose);
      await tester.pumpAndSettle();
      repository.write = Completer<void>();
      repository.fail = true;
      final write = demo.followArtisan(
        buyerArtisans.first,
        artisanId: 'artisan-uid',
      );
      expect(demo.followingWrites, {'artisan-uid'});
      await demo.followArtisan(buyerArtisans.first, artisanId: 'artisan-uid');
      expect(repository.writes, 1);
      repository.write!.complete();
      await write;
      expect(demo.followedArtisans, isEmpty);
      expect(demo.followingWrites, isEmpty);
      expect(demo.followError, 'Follow could not be saved.');
      repository.write = null;
      repository.fail = false;
      demo.retryFollows();
      await tester.pumpAndSettle();
      await demo.followArtisan(buyerArtisans.first, artisanId: 'artisan-uid');
      repository.fail = true;
      await demo.followArtisan(buyerArtisans.first, artisanId: 'artisan-uid');
      expect(demo.followedArtisans, {'artisan-uid'});
    },
  );

  testWidgets('live changes and sign-out clear the previous buyer follows', (
    tester,
  ) async {
    final demo = BuyerDemo(backend: repository);
    addTearDown(demo.dispose);
    await tester.pumpAndSettle();
    await db.doc('users/buyer/followedArtisans/artisan-uid').set({
      'artisanId': 'artisan-uid',
    });
    await tester.pumpAndSettle();
    expect(demo.followedArtisans, {'artisan-uid'});
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(demo.followedArtisans, isEmpty);
    await demo.followArtisan(buyerArtisans.first, artisanId: 'artisan-uid');
    expect(demo.followError, 'Please sign in to follow artisans.');
    expect(repository.writes, 0);
  });

  testWidgets(
    'read failures disable changes until retry reloads saved follows',
    (tester) async {
      repository.followStream = Stream<Set<String>>.error(
        const MarketplaceFailure('Could not load follows.'),
      );
      final demo = BuyerDemo(backend: repository);
      addTearDown(demo.dispose);
      await tester.pumpAndSettle();
      expect(demo.followsLoading, isFalse);
      expect(demo.followError, 'Could not load follows.');
      await demo.followArtisan(buyerArtisans.first, artisanId: 'artisan-uid');
      expect(repository.writes, 0);
      await db.doc('users/buyer/followedArtisans/artisan-uid').set({
        'artisanId': 'artisan-uid',
      });
      repository.followStream = null;
      demo.retryFollows();
      await tester.pumpAndSettle();
      expect(demo.followError, isNull);
      expect(demo.followedArtisans, {'artisan-uid'});
    },
  );

  testWidgets('another buyer restores only their own follow data', (
    tester,
  ) async {
    await db.doc('users/buyer/followedArtisans/first').set({
      'artisanId': 'first',
    });
    await db.doc('users/other/followedArtisans/second').set({
      'artisanId': 'second',
    });
    final other = MarketplaceRepository(
      firestore: db,
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'other'), signedIn: true),
      loadRole: () async => UserRole.buyer,
    );
    final demo = BuyerDemo(backend: other);
    addTearDown(demo.dispose);
    await tester.pumpAndSettle();
    expect(demo.followedArtisans, {'second'});
    await demo.followArtisan(buyerArtisans.first, artisanId: 'second');
    expect(
      (await db.doc('users/buyer/followedArtisans/first').get()).exists,
      isTrue,
    );
  });

  testWidgets('guest and anonymous users cannot follow', (tester) async {
    auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'guest', isAnonymous: true),
      signedIn: true,
    );
    repository = ControlledRepository(db, auth);
    final demo = BuyerDemo(backend: repository);
    addTearDown(demo.dispose);
    await tester.pumpAndSettle();
    await demo.followArtisan(buyerArtisans.first, artisanId: 'artisan-uid');
    expect(demo.followedArtisans, isEmpty);
    expect(demo.followError, 'Please sign in to follow artisans.');
    expect(repository.writes, 0);
  });

  testWidgets('Follow button tracks live saved state and pending writes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final demo = BuyerDemo(backend: repository);
    addTearDown(demo.dispose);
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        home: BuyerArtisanProfile(
          demo: demo,
          artisan: buyerArtisans.first,
          avatarProduct: demoProducts.first,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final id = demoProducts.first.artisan;
    await db.doc('users/buyer/followedArtisans/$id').set({'artisanId': id});
    await tester.pumpAndSettle();
    expect(find.text('Following'), findsOneWidget);
    repository.write = Completer<void>();
    await tester.ensureVisible(find.text('Following'));
    await tester.tap(find.text('Following'));
    await tester.pump();
    expect(find.text('Please wait...'), findsOneWidget);
    repository.write!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Follow Artisan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
