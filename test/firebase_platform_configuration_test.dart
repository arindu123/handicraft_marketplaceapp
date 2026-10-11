import 'package:artisan_marketplace/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test('Android Firebase configuration points to the existing project', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      DefaultFirebaseOptions.currentPlatform,
      DefaultFirebaseOptions.android,
    );
    expect(
      DefaultFirebaseOptions.currentPlatform.projectId,
      'craftisan-we114-2026',
    );
  });
  for (final platform in TargetPlatform.values.where(
    (p) => p != TargetPlatform.android,
  )) {
    test(
      'Unconfigured $platform fails explicitly instead of reusing Android credentials',
      () {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsUnsupportedError,
        );
      },
    );
  }
}
