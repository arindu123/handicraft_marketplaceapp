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
