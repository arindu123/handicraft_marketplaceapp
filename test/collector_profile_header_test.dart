import 'package:artisan_marketplace/features/buyer/collector_profile_header.dart';
import 'package:artisan_marketplace/shared/data/profile_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Collector can edit profile and sees saved name on return', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'buyer'),
      signedIn: true,
    );
    await db.collection('users').doc('buyer').set({
      'displayName': 'Nimal',
      'email': 'nimal@example.com',
      'role': 'buyer',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CollectorProfileHeader(
              repository: ProfileRepository(firestore: db, auth: auth),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nimal'), findsOneWidget);
    await tester.tap(find.text('Edit profile & photo'));
    await tester.pumpAndSettle();
    expect(find.text('Choose profile photo'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Nimal Perera');
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Nimal Perera'), findsOneWidget);
    expect(
      (await db.collection('users').doc('buyer').get()).data()!['role'],
      'buyer',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guest profile fits a small screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: CollectorProfileHeader()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign in to personalise'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
