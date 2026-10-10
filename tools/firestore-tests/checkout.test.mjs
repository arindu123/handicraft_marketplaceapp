import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, getDocs, collection, collectionGroup, query, where, runTransaction, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';

let env;
const now = '2026-10-05T00:00:00.000Z';
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-craftisan',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const db = ctx.firestore();
    for (const [uid, role] of Object.entries({admin: 'admin', buyer: 'buyer', other: 'buyer', artisan: 'artisan', courier: 'courier', courier2: 'courier'})) {
      await setDoc(doc(db, 'users', uid), {uid, role});
    }
    for (let i = 0; i < 8; i++) {
      await setDoc(doc(db, 'products', `p${i}`), {
        id: `p${i}`, artisanId: 'artisan', name: 'Mug', category: 'Clay',
        description: '', price: 60, currency: 'USD', stock: 5,
        imageUrls: [], status: 'active', createdAt: now,
      });
    }
  });
});
const dbFor = uid => env.authenticatedContext(uid).firestore();

test('buyers report only their own orders and read only their own resolutions', async () => {
  const buyer = dbFor('buyer'), other = dbFor('other'), admin = dbFor('admin');
  await checkout(buyer, order('buyer-problem'));
  const report = {kind: 'Order', targetId: 'buyer-problem', reporterId: 'buyer', submittedBy: 'buyer',
    reason: 'Damaged item', notes: 'Cracked mug', createdAt: serverTimestamp()};
  await assertSucceeds(getDoc(doc(buyer, 'marketplaceReports/new-report')));
  await assertSucceeds(setDoc(doc(buyer, 'marketplaceReports/new-report'), report));
  await assertSucceeds(getDocs(query(collection(buyer, 'marketplaceReports'), where('submittedBy', '==', 'buyer'), where('reporterId', '==', 'buyer'), where('targetId', '==', 'buyer-problem'))));
  await assertFails(getDoc(doc(other, 'marketplaceReports/new-report')));
  await assertFails(getDocs(collection(buyer, 'marketplaceReports')));
  await assertFails(setDoc(doc(other, 'marketplaceReports/stolen'), {...report, submittedBy: 'other', reporterId: 'other'}));
  await assertFails(setDoc(doc(buyer, 'marketplaceReports/spoofed'), {...report, reporterId: 'other'}));
  await assertFails(setDoc(doc(buyer, 'marketplaceReports/product'), {...report, kind: 'Product', targetId: 'p0'}));
  await assertFails(setDoc(doc(buyer, 'marketplaceReports/unknown'), {...report, reason: 'Unknown'}));
  await assertFails(setDoc(doc(buyer, 'marketplaceReports/blank'), {...report, notes: ''}));
  await assertFails(updateDoc(doc(buyer, 'marketplaceReports/new-report'), {notes: 'Changed'}));
  await assertFails(deleteDoc(doc(buyer, 'marketplaceReports/new-report')));
  const resolutionId = Buffer.from('marketplaceReports/new-report').toString('base64url');
  const resolution = doc(buyer, 'reportResolutions', resolutionId);
  await assertSucceeds(getDoc(resolution));
  await assertSucceeds(adminChange(admin, 'reportResolutions', resolutionId, 'Complaint resolved', {
    sourcePath: 'marketplaceReports/new-report', status: 'Resolved', notes: 'Replacement arranged',
    resolvedBy: 'admin', updatedAt: serverTimestamp(),
  }));
  assert.equal((await assertSucceeds(getDoc(resolution))).data().notes, 'Replacement arranged');
  await assertFails(getDoc(doc(other, 'reportResolutions', resolutionId)));
  await assertFails(updateDoc(resolution, {status: 'Resolved'}));
  await assertFails(setDoc(doc(dbFor('courier'), 'marketplaceReports/courier-report'), {...report, submittedBy: 'courier', reporterId: 'courier'}));
});
async function adminChange(db, collectionName, id, action, changes, actorId = 'admin') {
  const activity = doc(collection(db, 'adminActivity'));
  await runTransaction(db, async transaction => {
    const ref = doc(db, collectionName, id);
    const snapshot = await transaction.get(ref);
    const before = snapshot.exists() ? snapshot.data() : {};
    const after = {...before, ...changes};
    transaction.set(ref, after);
    transaction.set(activity, {actorId, action, collection: collectionName,
      targetId: id, before, after, createdAt: serverTimestamp()});
  });
  return activity;
}
const deliveryPolicy = (fee = 350, freeDeliveryThreshold = 10000) => ({
  currency: 'LKR', fee, freeDeliveryThreshold, updatedBy: 'admin', updatedAt: serverTimestamp(),
});
function order(id, buyer = 'buyer', count = 1, quantity = 2) {
  const subtotal = count * quantity * 60;
  const fee = subtotal >= 250 ? 0 : 14;
  return {
    id, buyerId: buyer, artisanId: 'artisan', courierId: null,
    items: Array.from({length: count}, (_, i) => ({productId: `p${i}`, productName: 'Mug', imageUrl: null, unitPrice: 60, quantity})),
    status: 'pending', deliveryAddress: '42 Flower Road, Colombo',
    recipientName: 'Buyer', recipientPhone: '0771234567',
    pickupAddress: 'Colombo 07', pickupName: 'Clay Studio', deliveryInstructions: 'Ring bell',
    paymentMethod: 'Cash on delivery', subtotal, deliveryFee: fee, total: subtotal + fee,
    createdAt: now, updatedAt: null,
  };
}
async function checkout(db, value, reserve = true) {
  return runTransaction(db, async tx => {
    const ref = doc(db, 'orders', value.id);
    const prior = await tx.get(ref);
    if (prior.exists()) return prior.data();
    const products = [];
    for (const item of value.items) products.push(await tx.get(doc(db, 'products', item.productId)));
    tx.set(ref, value);
    if (reserve) products.forEach((p, i) => tx.update(p.ref, {stock: p.data().stock - value.items[i].quantity, lastOrderId: value.id}));
    for (const item of value.items) tx.delete(doc(db, 'users', value.buyerId, 'cart', item.productId));
    return value;
  });
}
test('checkout persists contact details, reserves stock, clears cart and retries once', async () => {
  const db = dbFor('buyer');
  await setDoc(doc(db, 'users/buyer/cart/p0'), {productId: 'p0', quantity: 2, addedAt: serverTimestamp()});
  await assertSucceeds(checkout(db, order('one')));
  await assertSucceeds(checkout(db, order('one')));
  assert.equal((await getDoc(doc(db, 'products/p0'))).data().stock, 3);
  assert.equal((await getDoc(doc(db, 'users/buyer/cart/p0'))).exists(), false);
  assert.equal((await getDoc(doc(db, 'orders/one'))).data().recipientPhone, '0771234567');
  await assertSucceeds(getDocs(query(collection(db, 'orders'), where('buyerId', '==', 'buyer'))));
});
test('LKR orders preserve currency and cannot buy USD products', async () => {
  const buyer = dbFor('buyer');
  await assertFails(checkout(buyer, {...order('wrong-currency'), currency: 'LKR'}));
  await env.withSecurityRulesDisabled(async ctx => {
    await updateDoc(doc(ctx.firestore(), 'products/p0'), {currency: 'LKR'});
  });
  await assertSucceeds(checkout(buyer, {...order('lkr'), currency: 'LKR'}));
  assert.equal((await getDoc(doc(buyer, 'orders/lkr'))).data().currency, 'LKR');
  await assertFails(updateDoc(doc(dbFor('artisan'), 'products/p0'), {currency: 'USD'}));
});

test('four-product checkout stays within rules access limits', async () => {
  await assertSucceeds(checkout(dbFor('buyer'), order('four', 'buyer', 4)));
});

test('admin notification preferences and read state are private to each admin', async () => {
  const preferences = {applications: true, orders: false, reports: true, updatedAt: serverTimestamp()};
  const admin = dbFor('admin'), buyer = dbFor('buyer');
  await assertSucceeds(setDoc(doc(admin, 'adminPreferences/admin'), preferences));
  await assertFails(getDoc(doc(buyer, 'adminPreferences/admin')));
  await assertFails(setDoc(doc(buyer, 'adminPreferences/buyer'), preferences));
  await assertFails(setDoc(doc(admin, 'adminPreferences/other'), preferences));
  await assertSucceeds(setDoc(doc(admin, 'adminNotificationReads/admin/events/event'), {readAt: serverTimestamp()}));
  await assertFails(getDoc(doc(buyer, 'adminNotificationReads/admin/events/event')));
  await assertSucceeds(setDoc(doc(admin, 'adminDevices/token'), {adminId: 'admin', token: 'token', updatedAt: serverTimestamp()}));
  await assertFails(setDoc(doc(buyer, 'adminDevices/forged'), {adminId: 'admin', token: 'forged', updatedAt: serverTimestamp()}));
  await assertFails(getDoc(doc(admin, 'adminDevices/token')));
});

test('admin can assign/reassign before pickup and old courier loses access', async () => {
  const admin = dbFor('admin');
  await checkout(dbFor('buyer'), order('assignment'));
  await updateDoc(doc(dbFor('artisan'), 'orders/assignment'), {status: 'confirmed', updatedAt: now});
  await assertSucceeds(adminChange(admin, 'orders', 'assignment', 'Courier assigned', {
    courierId: 'courier', status: 'courierAssigned', updatedAt: now,
  }));
  await assertSucceeds(adminChange(admin, 'orders', 'assignment', 'Courier assigned', {
    courierId: 'courier2', status: 'courierAssigned', updatedAt: now,
  }));
  await assertFails(getDoc(doc(dbFor('courier'), 'orders/assignment')));
  await assertFails(updateDoc(doc(dbFor('courier'), 'orders/assignment'), {status: 'pickedUp', updatedAt: now}));
  await assertSucceeds(updateDoc(doc(dbFor('courier2'), 'orders/assignment'), {status: 'pickedUp', updatedAt: now}));
  await assertFails(adminChange(admin, 'orders', 'assignment', 'Courier assigned', {
    courierId: 'courier', status: 'courierAssigned', updatedAt: now,
  }));
});

test('admin assignment rejects unpacked, paused, non-courier and held deliveries', async () => {
  const admin = dbFor('admin');
  await checkout(dbFor('buyer'), order('blocked-assignment'));
  const changes = {courierId: 'courier', status: 'courierAssigned', updatedAt: now};
  await assertFails(adminChange(admin, 'orders', 'blocked-assignment', 'Courier assigned', changes));
  await updateDoc(doc(dbFor('artisan'), 'orders/blocked-assignment'), {status: 'confirmed', updatedAt: now});
  await env.withSecurityRulesDisabled(async ctx => {
    await updateDoc(doc(ctx.firestore(), 'users/courier'), {active: false});
  });
  await assertFails(adminChange(admin, 'orders', 'blocked-assignment', 'Courier assigned', changes));
  await assertFails(adminChange(admin, 'orders', 'blocked-assignment', 'Courier assigned', {...changes, courierId: 'buyer'}));
  await assertFails(adminChange(dbFor('buyer'), 'orders', 'blocked-assignment', 'Courier assigned', {...changes, courierId: 'courier2'}, 'buyer'));
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(), 'orders/blocked-assignment/deliveryPlan/current'), {outcome: 'returnRequested'});
  });
  await assertFails(adminChange(admin, 'orders', 'blocked-assignment', 'Courier assigned', {...changes, courierId: 'courier2'}));
});

test('admin delivery fees are enforced for new LKR orders only', async () => {
  const admin = dbFor('admin'), buyer = dbFor('buyer');
  await assertSucceeds(adminChange(admin, 'marketplaceSettings', 'deliveryLkr', 'Delivery fees updated', deliveryPolicy()));
  await env.withSecurityRulesDisabled(async ctx => {
    for (let i = 0; i < 4; i++) await updateDoc(doc(ctx.firestore(), 'products', `p${i}`), {currency: 'LKR'});
  });
  const stale = {...order('stale'), currency: 'LKR'};
  await assertFails(checkout(buyer, stale));
  const value = {...order('lkr-fee', 'buyer', 4), currency: 'LKR'};
  value.deliveryFee = 350; value.total = value.subtotal + 350;
  await assertSucceeds(checkout(buyer, value));
  await assertSucceeds(adminChange(admin, 'marketplaceSettings', 'deliveryLkr', 'Delivery fees updated', deliveryPolicy(400)));
  assert.equal((await getDoc(doc(buyer, 'orders/lkr-fee'))).data().deliveryFee, 350);
  const usd = order('usd-fee'); usd.items[0].productId = 'p4';
  await assertSucceeds(checkout(buyer, usd));
});

test('non-admins, invalid fees and spoofed audit actors are rejected', async () => {
  await assertFails(setDoc(doc(dbFor('buyer'), 'marketplaceSettings/deliveryLkr'), deliveryPolicy()));
  await assertFails(setDoc(doc(dbFor('admin'), 'marketplaceSettings/deliveryLkr'), deliveryPolicy(-1)));
  await assertFails(adminChange(dbFor('admin'), 'marketplaceSettings', 'deliveryLkr', 'Delivery fees updated', deliveryPolicy(), 'buyer'));
  assert.equal((await getDoc(doc(dbFor('admin'), 'marketplaceSettings/deliveryLkr'))).exists(), false);
  await assertFails(getDocs(collection(dbFor('buyer'), 'adminActivity')));
});

test('audit requires a real atomic change and is immutable', async () => {
  const admin = dbFor('admin');
  const ref = await adminChange(admin, 'products', 'p0', 'Product visibility updated', {status: 'hidden'});
  const activity = (await getDoc(ref)).data();
  assert.equal(activity.before.status, 'active');
  assert.equal(activity.after.status, 'hidden');
  await assertFails(updateDoc(ref, {actorId: 'other'}));
  await assertFails(deleteDoc(ref));
  await assertFails(setDoc(doc(collection(admin, 'adminActivity')), {
    ...activity, createdAt: serverTimestamp(),
  }));
});

test('complaints and courier issues are private and resolution preserves evidence', async () => {
  const admin = dbFor('admin');
  await checkout(dbFor('buyer'), order('reported'));
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(), 'orders/reported/deliveryIssues/issue'), {
      courierId: 'courier', reason: 'Damaged parcel', notes: 'Cracked mug', createdAt: new Date(),
    });
  });
  await assertSucceeds(getDocs(collectionGroup(admin, 'deliveryIssues')));
  await assertFails(getDocs(collectionGroup(dbFor('other'), 'deliveryIssues')));
  const manual = {kind: 'Product', targetId: 'p0', reporterId: 'Buyer', reason: 'Wrong item',
    notes: '', submittedBy: 'admin', createdAt: serverTimestamp()};
  await assertSucceeds(adminChange(admin, 'marketplaceReports', 'manual', 'Complaint recorded', manual));
  await assertFails(getDoc(doc(dbFor('buyer'), 'marketplaceReports/manual')));
  await assertFails(setDoc(doc(dbFor('buyer'), 'marketplaceReports/forged'), {...manual, submittedBy: 'buyer'}));
  const resolution = {sourcePath: 'orders/reported/deliveryIssues/issue', status: 'Resolved',
    notes: 'Replacement arranged', resolvedBy: 'admin', updatedAt: serverTimestamp()};
  await assertSucceeds(adminChange(admin, 'reportResolutions', 'resolution', 'Complaint resolved', resolution));
  assert.equal((await getDoc(doc(admin, resolution.sourcePath))).data().notes, 'Cracked mug');
  await assertFails(setDoc(doc(admin, 'reportResolutions/missing'), {...resolution, sourcePath: 'marketplaceReports/missing'}));
  await assertFails(setDoc(doc(dbFor('courier'), 'reportResolutions/forged'), {...resolution, resolvedBy: 'courier'}));
});
test('order without inventory reservation is rejected', async () => {
  await assertFails(checkout(dbFor('buyer'), order('no-stock'), false));
});
test('forged total and insufficient stock are rejected atomically', async () => {
  const db = dbFor('buyer');
  await assertFails(checkout(db, {...order('cheap'), total: 1}));
  await assertFails(checkout(db, order('too-many', 'buyer', 1, 6)));
  assert.equal((await getDoc(doc(db, 'products/p0'))).data().stock, 5);
  assert.equal((await getDoc(doc(db, 'orders/cheap'))).exists(), false);
});
test('another buyer cannot read the order or reserve stock using an old order', async () => {
  const db = dbFor('buyer');
  await checkout(db, order('private'));
  await assertFails(getDoc(doc(dbFor('other'), 'orders/private')));
  await assertFails(updateDoc(doc(db, 'products/p0'), {stock: 1, lastOrderId: 'private'}));
});
test('buyer to artisan to courier to delivery code is a persisted lifecycle', async () => {
  const buyer = dbFor('buyer'), artisan = dbFor('artisan'), courier = dbFor('courier');
  await checkout(buyer, order('flow'));
  const available = query(collection(courier, 'orders'), where('status', '==', 'confirmed'), where('courierId', '==', null));
  assert.equal((await assertSucceeds(getDocs(available))).size, 0);
  await assertFails(updateDoc(doc(courier, 'orders/flow'), {status: 'courierAssigned', courierId: 'courier', updatedAt: now}));
  await assertSucceeds(updateDoc(doc(artisan, 'orders/flow'), {status: 'confirmed', updatedAt: now}));
  assert.equal((await assertSucceeds(getDocs(available))).size, 1);
  await assertSucceeds(runTransaction(courier, async tx => {
    const ref = doc(courier, 'orders/flow');
    await tx.get(ref);
    tx.update(ref, {status: 'courierAssigned', courierId: 'courier', updatedAt: now});
  }));
  await assertFails(updateDoc(doc(dbFor('courier2'), 'orders/flow'), {courierId: 'courier2', status: 'courierAssigned', updatedAt: now}));
  await assertFails(getDoc(doc(dbFor('courier2'), 'orders/flow')));
  assert.equal((await getDocs(available)).size, 0);
  assert.equal((await getDocs(query(collection(courier, 'orders'), where('courierId', '==', 'courier')))).size, 1);
  await assertFails(updateDoc(doc(courier, 'orders/flow'), {status: 'delivered', updatedAt: now}));
  for (const status of ['pickedUp', 'onTheWay']) {
    await assertSucceeds(updateDoc(doc(courier, 'orders/flow'), {status, updatedAt: now}));
  }
  await assertSucceeds(setDoc(doc(buyer, 'deliveryConfirmations/flow'), {code: '123456', createdAt: serverTimestamp()}));
  await assertFails(getDoc(doc(courier, 'deliveryConfirmations/flow')));
  await assertFails(updateDoc(doc(courier, 'orders/flow'), {status: 'delivered', deliveryConfirmationCode: '999999', updatedAt: now}));
  await assertSucceeds(updateDoc(doc(courier, 'orders/flow'), {status: 'delivered', deliveryConfirmationCode: '123456', updatedAt: now}));
  assert.equal((await getDoc(doc(buyer, 'orders/flow'))).data().status, 'delivered');
});


test('saved addresses are owner-only, validated and editable', async () => {
  const address = {name: 'Test buyer', address: 'Test street', city: 'Test city', postalCode: '12345', country: 'Test country', phone: '0123456789'};
  const path = 'users/buyer/addresses/home';
  await assertSucceeds(setDoc(doc(dbFor('buyer'), path), address));
  await assertSucceeds(updateDoc(doc(dbFor('buyer'), path), {city: 'Updated city'}));
  assert.equal((await getDoc(doc(dbFor('buyer'), path))).data().city, 'Updated city');
  await assertFails(getDoc(doc(dbFor('other'), path)));
  await assertFails(setDoc(doc(dbFor('other'), path), address));
  await assertFails(setDoc(doc(dbFor('buyer'), path), {...address, phone: ''}));
  await assertFails(setDoc(doc(dbFor('buyer'), path), {...address, cardNumber: 'not allowed'}));
  await assertFails(setDoc(doc(dbFor('artisan'), 'users/artisan/addresses/home'), address));
});

async function assignedOrder(id, status = 'onTheWay') {
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(), 'orders', id), { ...order(id), courierId: 'courier', status });
  });
}
const attempt = (outcome = 'failed', retryAt = null) => ({
  courierId: 'courier', outcome, reason: 'Customer unavailable', notes: 'No answer',
  retryAt, createdAt: serverTimestamp(),
});

test('delivery holds block advancement and only assigned couriers can resume', async () => {
  await assignedOrder('held', 'pickedUp');
  const courier = dbFor('courier'), plan = doc(courier, 'orders/held/deliveryPlan/current');
  await assertSucceeds(runTransaction(courier, async tx => {
    const data = attempt();
    tx.set(plan, data);
    tx.set(doc(courier, 'orders/held/deliveryAttempts/a1'), data);
  }));
  await assertFails(updateDoc(doc(courier, 'orders/held'), { status: 'onTheWay', updatedAt: now }));
  await assertFails(updateDoc(doc(dbFor('courier2'), 'orders/held/deliveryPlan/current'), { outcome: 'active', createdAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(dbFor('buyer'), 'orders/held/deliveryPlan/current'), { outcome: 'active', createdAt: serverTimestamp() }));
  await assertSucceeds(getDoc(doc(dbFor('buyer'), 'orders/held/deliveryPlan/current')));
  await assertFails(getDoc(doc(dbFor('other'), 'orders/held/deliveryPlan/current')));
  await assertSucceeds(updateDoc(plan, { outcome: 'active', createdAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(courier, 'orders/held'), { status: 'onTheWay', updatedAt: now }));
  await assertFails(updateDoc(doc(courier, 'orders/held/deliveryAttempts/a1'), { notes: 'Forged' }));
});

test('scheduled retries cannot resume early and returns remain on hold', async () => {
  await assignedOrder('retry');
  const plan = doc(dbFor('courier'), 'orders/retry/deliveryPlan/current');
  await assertFails(setDoc(plan, attempt('rescheduled', new Date(Date.now() - 60000))));
  await assertSucceeds(setDoc(plan, attempt('rescheduled', new Date(Date.now() + 3600000))));
  await assertFails(updateDoc(plan, { outcome: 'active', createdAt: serverTimestamp() }));
  await assertSucceeds(setDoc(plan, attempt('returnRequested')));
  await assertFails(updateDoc(plan, { outcome: 'active', createdAt: serverTimestamp() }));
  await assertFails(setDoc(plan, attempt()));
});

test('a hold cannot be bypassed by advancing the order in the same transaction', async () => {
  await assignedOrder('atomic-hold', 'pickedUp');
  const courier = dbFor('courier');
  await assertFails(runTransaction(courier, async tx => {
    tx.set(doc(courier, 'orders/atomic-hold/deliveryPlan/current'), attempt());
    tx.update(doc(courier, 'orders/atomic-hold'), { status: 'onTheWay', updatedAt: now });
  }));
  assert.equal((await getDoc(doc(courier, 'orders/atomic-hold'))).data().status, 'pickedUp');
});

test('photo metadata enforces assignment, stage, private paths and participant access', async () => {
  await assignedOrder('proof', 'courierAssigned');
  const courier = dbFor('courier');
  const data = stage => ({ courierId: 'courier', stage,
    path: `delivery_proofs/proof/courier/${stage}.jpg`, createdAt: serverTimestamp() });
  await assertSucceeds(setDoc(doc(courier, 'orders/proof/deliveryProofs/pickup'), data('pickup')));
  await assertFails(setDoc(doc(courier, 'orders/proof/deliveryProofs/dropoff'), data('dropoff')));
  await assertFails(setDoc(doc(dbFor('courier2'), 'orders/proof/deliveryProofs/pickup'), data('pickup')));
  await assertFails(setDoc(doc(courier, 'orders/proof/deliveryProofs/pickup'), { ...data('pickup'), path: 'public/photo.jpg' }));
  await assertSucceeds(getDoc(doc(dbFor('buyer'), 'orders/proof/deliveryProofs/pickup')));
  await assertFails(getDoc(doc(dbFor('other'), 'orders/proof/deliveryProofs/pickup')));
  await env.withSecurityRulesDisabled(async ctx => {
    await updateDoc(doc(ctx.firestore(), 'orders/proof'), { status: 'delivered' });
  });
  await assertSucceeds(setDoc(doc(courier, 'orders/proof/deliveryProofs/dropoff'), data('dropoff')));
  await assertFails(setDoc(doc(courier, 'orders/proof/deliveryProofs/pickup'), data('pickup')));
});

test('device registration and notification preferences are courier-only', async () => {
  const courier = dbFor('courier'), device = doc(courier, 'deliveryDevices/device-token');
  await assertSucceeds(setDoc(device, { courierId: 'courier', token: 'device-token', updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(dbFor('other'), 'deliveryDevices/device-token')));
  await assertFails(setDoc(doc(dbFor('buyer'), 'deliveryDevices/buyer-token'), {
    courierId: 'buyer', token: 'buyer-token', updatedAt: serverTimestamp() }));
  await assertFails(setDoc(device, { courierId: 'courier', token: 'wrong-token', updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(courier, 'users/courier'), { deliveryNotifications: false, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(dbFor('other'), 'users/courier'), { deliveryNotifications: true, updatedAt: serverTimestamp() }));
});
