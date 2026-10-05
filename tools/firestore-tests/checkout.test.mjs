import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, getDocs, collection, query, where, runTransaction, updateDoc, serverTimestamp } from 'firebase/firestore';

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
    for (const [uid, role] of Object.entries({buyer: 'buyer', other: 'buyer', artisan: 'artisan', courier: 'courier', courier2: 'courier'})) {
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
test('four-product checkout stays within rules access limits', async () => {
  await assertSucceeds(checkout(dbFor('buyer'), order('four', 'buyer', 4)));
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
