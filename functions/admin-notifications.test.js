const {test} = require('node:test');
const assert = require('node:assert/strict');
const {adminEvent, sendAdminAlerts} = require('./admin-notifications');

test('admin events ignore unchanged records and exclude private complaint details', () => {
  assert.equal(adminEvent('orders', {status: 'pending'}, {status: 'pending'}, 'order'), null);
  assert.equal(adminEvent('applications', {verificationStatus: 'pending'}, {verificationStatus: 'pending'}, 'maker'), null);
  assert.equal(adminEvent('reports', null, null, 'report'), null);
  const notice = adminEvent('reports', null, {notes: 'private customer details'}, 'report');
  assert.equal(notice.category, 'reports');
  assert.equal(JSON.stringify(notice).includes('private customer'), false);
  assert.ok(adminEvent('orders', {status: 'pending'}, {status: 'confirmed'}, 'order'));
  assert.ok(adminEvent('applications', null, {verificationStatus: 'pending'}, 'maker'));
});

test('admin push honors role, active status and per-admin preferences', async () => {
  const sent = [], removed = [];
  const row = (id, data) => ({id, data: () => data, ref: {delete: async () => removed.push(id)}});
  const admins = [row('enabled', {active: true}), row('muted', {active: true}), row('paused', {active: false})];
  const db = {
    doc: path => ({get: async () => row(path, path.endsWith('/muted') ? {reports: false} : {})}),
    collection: name => name === 'notificationDispatches' ? {doc: () => ({create: async () => {}})}
      : {where: (field, op, value) => ({get: async () => ({docs: name === 'users' ? admins : [row(value, {token: 'expired'})]})})},
  };
  await sendAdminAlerts(db, {sendEachForMulticast: async payload => {
    sent.push(payload); return {responses: [{error: {code: 'messaging/registration-token-not-registered'}}]};
  }}, 'event', adminEvent('reports', null, {}, 'report'));
  assert.equal(sent.length, 1);
  assert.deepEqual(removed, ['enabled']);
  assert.equal(sent[0].data.type, 'admin');
});

test('duplicate events do not send another push', async () => {
  const db = {collection: () => ({doc: () => ({create: async () => {throw {code: 6};}})})};
  await sendAdminAlerts(db, {sendEachForMulticast: () => assert.fail('Duplicate push')}, 'event',
    adminEvent('reports', null, {}, 'report'));
});
