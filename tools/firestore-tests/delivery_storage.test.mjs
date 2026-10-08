import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc } from 'firebase/firestore';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';

let env;
const bucket = 'gs://demo-craftisan.appspot.com';
const photo = new Uint8Array([0xff, 0xd8, 0xff]);
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-craftisan',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
    storage: { rules: readFileSync(new URL('../../storage.rules', import.meta.url), 'utf8') } });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async ctx => {
    for (const [uid, role] of Object.entries({ buyer: 'buyer', artisan: 'artisan', courier: 'courier', other: 'courier', admin: 'admin' })) {
      await setDoc(doc(ctx.firestore(), 'users', uid), { uid, role });
    }
    await setDoc(doc(ctx.firestore(), 'orders/o1'), {
      buyerId: 'buyer', artisanId: 'artisan', courierId: 'courier', status: 'courierAssigned' });
  });
});
const file = (uid, stage = 'pickup', courier = 'courier') =>
  ref(env.authenticatedContext(uid).storage(bucket), `delivery_proofs/o1/${courier}/${stage}.jpg`);

test('proof files are private to order participants and admins', async () => {
  await assertSucceeds(uploadBytes(file('courier'), photo, { contentType: 'image/jpeg' }));
  for (const uid of ['buyer', 'artisan', 'courier', 'admin']) await assertSucceeds(getBytes(file(uid)));
  await assertFails(getBytes(file('other')));
  await assertFails(getBytes(ref(env.unauthenticatedContext().storage(bucket), 'delivery_proofs/o1/courier/pickup.jpg')));
  await assertFails(deleteObject(file('courier')));
});

test('uploads reject other couriers, invalid stages and non-JPEG content', async () => {
  await assertFails(uploadBytes(file('other', 'pickup', 'other'), photo, { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(file('buyer'), photo, { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(file('courier', 'dropoff'), photo, { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(file('courier', 'unknown'), photo, { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(file('courier'), photo, { contentType: 'text/plain' }));
  await assertFails(uploadBytes(file('courier'), new Uint8Array(), { contentType: 'image/jpeg' }));
});

test('dropoff proof is allowed after completion while pickup is locked', async () => {
  await env.withSecurityRulesDisabled(async ctx => {
    await updateDoc(doc(ctx.firestore(), 'orders/o1'), { status: 'delivered' });
  });
  await assertSucceeds(uploadBytes(file('courier', 'dropoff'), photo, { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(file('courier'), photo, { contentType: 'image/jpeg' }));
});
