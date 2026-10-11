import { readFileSync } from 'node:fs';
import { after, before, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-craftisan',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') } });
  await env.withSecurityRulesDisabled(async ctx => {
    const db = ctx.firestore();
    for (const uid of ['buyer', 'other']) await setDoc(doc(db, `users/${uid}`), { role: 'buyer' });
    await setDoc(doc(db, 'users/artisan'), { role: 'artisan' });
    await setDoc(doc(db, 'users/guest'), { role: 'buyer' });
    await setDoc(doc(db, 'artisanProfiles/artisan'), { studioName: 'Studio' });
  });
});
after(async () => env?.cleanup());
const data = () => ({ artisanId: 'artisan', addedAt: serverTimestamp() });

test('buyer persists and deletes their own follow; other buyers cannot access it', async () => {
  const db = env.authenticatedContext('buyer').firestore();
  const ref = doc(db, 'users/buyer/followedArtisans/artisan');
  await assertSucceeds(setDoc(ref, data()));
  await assertSucceeds(getDoc(ref));
  const otherRef = doc(env.authenticatedContext('other').firestore(), ref.path);
  await assertFails(getDoc(otherRef));
  await assertFails(setDoc(otherRef, data()));
  await assertFails(deleteDoc(otherRef));
  await assertSucceeds(deleteDoc(ref));
});

test('unauthenticated, anonymous and non-buyer accounts cannot follow', async () => {
  for (const db of [env.unauthenticatedContext().firestore(),
    env.authenticatedContext('artisan').firestore(),
    env.authenticatedContext('guest', { firebase: { sign_in_provider: 'anonymous' } }).firestore()]) {
    await assertFails(setDoc(doc(db, 'users/buyer/followedArtisans/artisan'), data()));
  }
  await assertFails(setDoc(doc(env.authenticatedContext('artisan').firestore(), 'users/artisan/followedArtisans/artisan'), data()));
  await assertFails(setDoc(doc(env.authenticatedContext('guest', { firebase: { sign_in_provider: 'anonymous' } }).firestore(), 'users/guest/followedArtisans/artisan'), data()));
});

test('follow payload and artisan target must be valid', async () => {
  const db = env.authenticatedContext('buyer').firestore();
  await assertFails(setDoc(doc(db, 'users/buyer/followedArtisans/missing'), { artisanId: 'missing', addedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db, 'users/buyer/followedArtisans/artisan'), { ...data(), artisanId: 'other' }));
  await assertFails(setDoc(doc(db, 'users/buyer/followedArtisans/artisan'), { ...data(), buyerId: 'other' }));
  await assertFails(setDoc(doc(db, 'users/buyer/followedArtisans/artisan'), { artisanId: 'artisan' }));
});
