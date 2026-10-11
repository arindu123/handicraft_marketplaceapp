# Google sign-in (Android)

The existing Google buttons now authenticate using google_sign_in and Firebase Auth.
Both sign-in and sign-up use the same flow. Profiles are created transactionally in
users/{Firebase UID} only when absent. Existing roles and profile data are preserved.
New profiles use the selected Buyer, Artisan or Courier role; new Admin profiles
cannot be created. Failed Firebase/profile setup signs out without deleting accounts.
Canceling the account picker returns to the form. Form buttons are disabled during
sign-in. Other platforms remain unsupported by the app's Firebase configuration.

## Firebase Console steps still required

1. Open Firebase project **craftisan-we114-2026**, Authentication, Sign-in method,
   Google. Enable it, choose the project support email and save.
2. Project settings, Your apps, Android **com.example.artisan_marketplace**:
   add the local debug signing certificate fingerprints below.
3. Download the updated google-services.json and replace
   android/app/google-services.json. The current file has no OAuth client entries;
   the new file must include a web OAuth client (client_type: 3). No fabricated
   client ID or client secret is included in Dart.
4. Fully rebuild/reinstall with flutter run. Hot reload cannot register the new
   native plugin/configuration. Test on Android with Google Play services.
5. Before release, register the actual release and Google Play app-signing SHA
   fingerprints as appropriate; debug fingerprints do not cover release builds.

Local debug certificate, read with keytool on 11 October 2026:

```text
SHA-1:   9E:25:46:FD:F0:59:09:19:25:55:D7:73:41:00:44:B6:C4:17:19:F9
SHA-256: 89:8B:86:01:54:35:98:48:E5:BF:44:39:81:29:1B:FF:F7:B0:34:0D:E1:AD:CA:09:06:A7:62:63:DB:BD:F4:D0
```

No Firebase settings or rules were deployed by this change. Verify account picker,
new account role/profile, returning user, logout/reopen, cancellation, offline
failure/retry and existing email/password accounts with the same email on a device.
Mocked tests do not verify real OAuth credentials or provider configuration.

## Local validation

- `flutter test --no-pub`: all 178 tests passed, including 9 Google-auth tests.
- `dart analyze lib test`: no issues found.
- `flutter build apk --debug --no-pub`: succeeded; app-debug.apk generated.
- Test coverage includes new buyer/artisan/courier profiles, repeated login,
  existing Admin/profile preservation, blocked new Admin, cancellation,
  invalid stored role, Firebase failure and missing Google configuration.
- Captured local logs: google-auth-final-tests.log, google-auth-analysis.log and
  google-auth-build.log. Existing Gradle/AGP/Kotlin future-support warnings remain;
  toolchain upgrades were outside this authentication change.

References:
- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://pub.dev/packages/google_sign_in_android
