const { test } = require('node:test');
const assert = require('node:assert/strict');
const { deliveryAudience, sendDeliveryAlerts } = require('./delivery');

test('only new available requests and changed assignments generate alerts', () => {
  const available = { status: 'confirmed', courierId: null };
  const assigned = { status: 'courierAssigned', courierId: 'rider' };
  assert.equal(deliveryAudience({ status: 'pending' }, available), 'available');
  assert.equal(deliveryAudience(available, available), null);
  assert.equal(deliveryAudience(available, assigned), 'rider');
  assert.equal(deliveryAudience(assigned, assigned), null);
  assert.equal(deliveryAudience(assigned, { ...assigned, courierId: 'other' }), 'other');
  assert.equal(deliveryAudience(assigned, { ...assigned, status: 'pickedUp' }), null);
  assert.equal(deliveryAudience(available, null), null);
});

test('available alerts honor availability and preferences and remove invalid tokens', async () => {
  const removed = [], sent = [];
  const row = (id, data) => ({ id, data: () => data, ref: { delete: async () => removed.push(id) } });
  const users = [row('online', { role: 'courier', deliveryOnline: true }),
    row('offline', { role: 'courier', deliveryOnline: false }),
    row('muted', { role: 'courier', deliveryOnline: true, deliveryNotifications: false }),
    row('disabled', { role: 'courier', deliveryOnline: true, active: false })];
  const db = {
    doc: () => ({ get: async () => row('o1', { status: 'confirmed', courierId: null }) }),
    collection: name => ({ where: (field, op, value) => ({ get: async () => ({ docs:
      name === 'users' ? users : [row(value, { token: 'expired' })] }) }) }),
  };
  await sendDeliveryAlerts(db, { sendEachForMulticast: async payload => {
    sent.push(payload); return { responses: [{ error: { code: 'messaging/registration-token-not-registered' } }] };
  } }, 'o1', 'available');
  assert.equal(sent.length, 1);
  assert.deepEqual(removed, ['online']);
  assert.deepEqual(sent[0].data, { orderId: 'o1', type: 'delivery' });
});

test('stale assignments are ignored before any token lookup', async () => {
  const db = { doc: () => ({ get: async () => ({ data: () => ({ status: 'delivered', courierId: 'rider' }) }) }) };
  await sendDeliveryAlerts(db, { sendEachForMulticast: () => assert.fail('Must not send') }, 'o1', 'rider');
});
