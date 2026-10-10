const { test } = require('node:test');
const assert = require('node:assert/strict');
const { buyerUpdate, sendBuyerAlert } = require('./buyer');

test('each confirmation and delivery milestone targets the buyer', () => {
  const stages = ['pending', 'confirmed', 'courierAssigned', 'pickedUp', 'onTheWay', 'delivered'];
  for (let i = 1; i < stages.length; i++) {
    const update = buyerUpdate({ status: stages[i - 1] },
      { status: stages[i], buyerId: 'buyer' });
    assert.equal(update.buyerId, 'buyer');
    assert.equal(update.status, stages[i]);
    assert.ok(update.body.length > 0);
  }
});

test('creation, deletion and unrelated edits do not notify', () => {
  assert.equal(buyerUpdate(null, { status: 'pending', buyerId: 'buyer' }), null);
  assert.equal(buyerUpdate({ status: 'confirmed' }, null), null);
  assert.equal(buyerUpdate({ status: 'confirmed' }, { status: 'confirmed', buyerId: 'buyer' }), null);
  assert.equal(buyerUpdate({ status: 'pending' }, { status: 'confirmed' }), null);
});

test('retried trigger preserves read inbox entry and removes invalid token', async () => {
  let stored;
  let removed = false;
  const ref = { create: async data => {
    if (stored) throw { code: 6 };
    stored = data;
  } };
  const db = {
    doc: path => path === 'users/buyer'
      ? { get: async () => ({ data: () => ({ role: 'buyer' }) }) } : ref,
    collection: () => ({ where: () => ({ get: async () => ({ docs: [
      { data: () => ({ token: 'device' }), ref: { delete: async () => { removed = true; } } },
    ] }) }) }),
  };
  const messaging = { sendEachForMulticast: async payload => {
    assert.deepEqual(payload.tokens, ['device']);
    assert.equal(payload.data.type, 'buyerOrder');
    return { responses: [{ error: { code: 'messaging/registration-token-not-registered' } }] };
  } };
  const update = buyerUpdate({ status: 'pending' }, { status: 'confirmed', buyerId: 'buyer' });
  await sendBuyerAlert(db, messaging, 'order', update, 'time');
  stored.read = true;
  await sendBuyerAlert(db, messaging, 'order', update, 'time');
  assert.equal(stored.read, true);
  assert.equal(removed, true);
});
