import { readFileSync } from 'node:fs';
import { after, before, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-craftisan',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') } });
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(), 'users/buyer'), { role: 'buyer' });
    await setDoc(doc(ctx.firestore(), 'users/other'), { role: 'buyer' });
    await setDoc(doc(ctx.firestore(), 'users/courier'), { role: 'courier' });
    await setDoc(doc(ctx.firestore(), 'users/buyer/notifications/update'), {
      orderId: 'order', body: 'Confirmed', read: false,
    });
  });
});
after(async () => env?.cleanup());

test('buyer owns inbox but cannot forge or edit update content', async () => {
  const db = env.authenticatedContext('buyer').firestore();
  const ref = doc(db, 'users/buyer/notifications/update');
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref, { read: true }));
  await assertFails(updateDoc(ref, { body: 'Forged' }));
  await assertFails(setDoc(doc(db, 'users/buyer/notifications/new'), { read: false }));
  await assertFails(getDoc(doc(env.authenticatedContext('other').firestore(), 'users/buyer/notifications/update')));
});

test('only buyers register devices for themselves', async () => {
  const data = { buyerId: 'buyer', token: 'token', updatedAt: serverTimestamp() };
  await assertSucceeds(setDoc(doc(env.authenticatedContext('buyer').firestore(), 'buyerDevices/token'), data));
  await assertFails(setDoc(doc(env.authenticatedContext('other').firestore(), 'buyerDevices/token'), data));
  await assertFails(setDoc(doc(env.authenticatedContext('courier').firestore(), 'buyerDevices/courier'),
    { buyerId: 'courier', token: 'courier', updatedAt: serverTimestamp() }));
});
