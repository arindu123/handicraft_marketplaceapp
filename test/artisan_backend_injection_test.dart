import 'package:artisan_marketplace/features/artisan/artisan_demo.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:artisan_marketplace/shared/models/domain_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Artisan profile uses the supplied backend without a global Firebase app',
    (tester) async {
      MarketplaceBackend.enabled = false;
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'artisan'),
        signedIn: true,
      );
      await db.doc('users/artisan').set({
        'displayName': 'Registered maker',
        'role': 'artisan',
      });
      final demo = ArtisanDemo(
        backend: MarketplaceRepository(
          firestore: db,
          auth: auth,
          loadRole: () async => UserRole.artisan,
        ),
      );
      addTearDown(demo.dispose);
      await tester.pumpAndSettle();
      expect(demo.error, isNull);
      expect(demo.userProfileData['displayName'], 'Registered maker');
      expect(demo.profile['studioName'], 'Registered maker');
      expect(demo.profile['userId'], 'artisan');
      await db.doc('artisanProfiles/artisan').update({
        'studioName': 'Updated studio',
      });
      await tester.pumpAndSettle();
      expect(demo.profile['studioName'], 'Updated studio');
    },
  );
}
