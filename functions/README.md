# Delivery notifications and proof setup

## Buyer order alerts

The buyer marketplace displays a live alert when an existing order changes status.
The notification bell lists saved confirmation, courier assignment, pickup, on-the-way,
delivery and cancellation updates. Opening an entry marks it read and opens that order.
Initial order snapshots and unrelated edits do not generate live alerts.

Deploy the buyer trigger and updated rules from the repository root:

```powershell
firebase.cmd deploy --only firestore:rules,functions:delivery:notifyBuyerOrderUpdates --project craftisan-we114-2026
```

Android buyers are asked for notification permission when their signed-in marketplace
opens. The bell screen also provides **Enable phone alerts** to retry registration.
Web and desktop receive live in-app alerts and the saved inbox; Android background
alerts use FCM. Notification taps open the buyer inbox. Notification history is written
only by the function; buyers can only read their own entries and mark them read.
One entry is saved per order milestone, and trigger retries preserve its read state.
FCM may redeliver a push on a retry; the Android tag replaces the same milestone alert.

No Firebase deployment is performed by these code changes. After deployment, test
on a physical Android device with an artisan account and a courier account advancing
the buyer's order through every stage, including while the buyer app is backgrounded.
See [Firebase message handling](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
and [Firestore trigger delivery semantics](https://firebase.google.com/docs/functions/firestore-events).

The app changes are limited to delivery features. The existing Firebase configuration supports Android; web and iOS push are not configured by this change.

## Activate on Firebase

From the repository root:

```powershell
cd functions
npm.cmd ci
cd ..
firebase.cmd deploy --only firestore:rules,storage,functions:delivery --project craftisan-we114-2026
```

Review and deploy these changes when ready. No production deployment was performed as part of implementation. Enable Cloud Storage for the configured bucket if necessary; the first deployment of Storage rules that read Firestore may ask to enable cross-service permissions. Cloud Functions and Storage require the appropriate Firebase billing plan. See [Firebase Functions setup](https://firebase.google.com/docs/functions/get-started) and [Storage cross-service rules](https://firebase.google.com/docs/storage/security/rules-conditions#enhance_with_firestore).

Rebuild the Android app after adding the native Firebase packages. Sign in as a courier, allow Android notification permission, and turn Online on to receive new available delivery requests. Assigned deliveries notify the selected courier even when offline. The Profile notification toggle persists across sessions. The Cloud Function checks current order assignment, notification preference and account availability before sending; invalid device tokens are removed. Tapping an alert opens the active Orders tab when the authenticated delivery screen loads.

FCM displays notification payloads while the app is in the background. Existing in-app delivery alerts handle the open delivery screen. Android force-stop and device notification settings can suppress delivery alerts; verify background reception on a physical device. See [Firebase Flutter messaging](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages).

## Photos and failed attempts

Open an accepted delivery to add a pickup photo. Delivery photos can be added while On The Way or after completion. Take a camera photo or select a JPEG from the gallery (up to 10 MB). Photos are stored at `delivery_proofs/{orderId}/{courierId}/{stage}.jpg` with access restricted to the buyer, artisan, assigned courier and admins. Replacing a stage photo replaces its previous image; confirmation codes remain required for completion.

Failed delivery / reschedule records a reason, notes and an optional future retry time. Failed and rescheduled deliveries stay on hold until Resume delivery; scheduled retries cannot resume before their time. Attempts persist in an immutable history. Return requested stays on hold and directs the rider to support; support/admin must arrange the return and clear the plan through trusted administration. This feature does not create a refund or change the existing order status milestones. Demo photos and plans remain in memory for the current screen session only.

## Verification

```powershell
flutter analyze
flutter test test/delivery_extras_test.dart test/delivery_flow_test.dart test/delivery_workflow_test.dart test/delivery_status_test.dart test/delivery_contact_details_test.dart test/marketplace_repository_test.dart
node --test functions/delivery.test.js
firebase.cmd emulators:exec --only firestore --project demo-craftisan "node --test tools/firestore-tests/checkout.test.mjs"
firebase.cmd emulators:exec --only firestore,storage --project demo-craftisan "node --test tools/firestore-tests/delivery_storage.test.mjs"
```

The Firestore emulator verifies access checks and existing checkout behavior. A real Android device and deployed Firebase resources are required to verify notification delivery, the image picker and Storage upload end to end.
