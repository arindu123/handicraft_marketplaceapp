# Checkout and delivery verification

Run from the repository root with Node.js and Java 21 available:

```powershell
cd tools/firestore-tests
npm ci
cd ../..
firebase emulators:exec --only firestore --project demo-craftisan "node --test tools/firestore-tests/checkout.test.mjs"
```

These isolated tests do not create production users or orders.

## Real application flow

1. Buyer adds products from one artisan (up to four distinct products), enters delivery contact details, and selects cash on delivery.
2. Checkout atomically creates the order, reserves stock, and clears the cart. Retrying the same request does not create another order.
3. Artisan opens Orders, selects the order, and presses Mark as Packed.
4. Signed-in couriers see confirmed, unassigned delivery requests. The first successful Accept Delivery transaction owns the assignment; another courier cannot claim it.
5. The assigned courier marks Picked Up, then starts delivery. Buyer tracking updates from Firestore.
6. Buyer shows the six-digit confirmation code in tracking. Courier enters it to complete delivery.

The tested firestore.rules must be deployed to the configured Firebase project before using this updated app against production. A hot reload alone does not deploy rules. No production deployment was completed by this change.

Available confirmed orders are visible to courier accounts; assigned orders are private to their buyer, artisan, assigned courier and admins. Card payments and geographic courier matching are not implemented.


## Complete architecture/integration rule checks

Use Node.js and Java 21. The Firestore and Storage emulator ports are configured
in the root firebase.json; no production deployment is involved.

Run from the repository root:

```powershell
firebase emulators:exec --only firestore,storage --project demo-craftisan "npm --prefix tools/firestore-tests run test:all"
```

The test:all script runs all four existing rule suites sequentially so their
shared demo project and clearFirestore calls do not interfere. Coverage includes
checkout and the order lifecycle, trusted product aggregate protection, buyer
notifications, follow ownership, and delivery proof Storage access.

See docs/architecture-api-integration-review.md for the final validation evidence
and the production deployment/device checks that still require approval or access.
