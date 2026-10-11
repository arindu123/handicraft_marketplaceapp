// Uses the existing Firebase CLI login. Never deletes Authentication accounts.
const fs = require('node:fs');
const path = require('node:path');
const auth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
const project = 'craftisan-we114-2026';
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
const backupPath = path.join(__dirname, '../build/courier-review-reset.json');

async function main() {
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Sign in with Firebase CLI first.');
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const headers = {Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json'};
  async function request(url, body) {
    const response = await fetch(url, {method: 'POST', headers, body: JSON.stringify(body)});
    const result = await response.json();
    if (!response.ok) throw new Error(`Firestore request failed (${response.status}).`);
    return result;
  }
  if (!process.argv.includes('--apply')) {
    const rows = await request(`${base}:runQuery`, {structuredQuery: {
      from: [{collectionId: 'users'}],
      where: {fieldFilter: {field: {fieldPath: 'role'}, op: 'EQUAL', value: {stringValue: 'courier'}}},
    }});
    const documents = rows.filter(row => row.document).map(row => row.document);
    if (process.argv.includes('--verify')) {
      console.log(JSON.stringify({couriers: documents.length,
        pending: documents.filter(doc => doc.fields.courierApproval?.stringValue === 'pending').length,
        accountsDeleted: 0}));
      return;
    }
    fs.mkdirSync(path.dirname(backupPath), {recursive: true});
    fs.writeFileSync(backupPath, JSON.stringify({project, preparedAt: new Date().toISOString(), documents}, null, 2));
    console.log(JSON.stringify({couriers: documents.length,
      accounts: documents.map(doc => ({uid: doc.name.split('/').pop(),
        name: doc.fields.displayName?.stringValue ?? '', status: doc.fields.courierApproval?.stringValue ?? 'legacy'}))}));
    return;
  }
  const snapshot = JSON.parse(fs.readFileSync(backupPath, 'utf8'));
  if (snapshot.project !== project) throw new Error('Backup project does not match.');
  let changed = 0;
  for (const document of snapshot.documents) {
    if (document.fields.role?.stringValue !== 'courier' || !document.name.startsWith(`projects/${project}/databases/(default)/documents/users/`)) {
      throw new Error('Unexpected account in backup.');
    }
    if (document.fields.courierApproval?.stringValue === 'pending') continue;
    const uid = document.name.split('/').pop();
    const after = {...document.fields, courierApproval: {stringValue: 'pending'}};
    delete after.courierReviewedBy;
    delete after.courierReviewedAt;
    const activityName = `projects/${project}/databases/(default)/documents/adminActivity/courier-review-reset-${uid}-${Date.now()}`;
    await request(`${base}:commit`, {writes: [
      {update: {name: document.name, fields: {courierApproval: {stringValue: 'pending'}}},
        updateMask: {fieldPaths: ['courierApproval','courierReviewedBy','courierReviewedAt']},
        currentDocument: {updateTime: document.updateTime}},
      {update: {name: activityName, fields: {
        actorId: {stringValue: `maintenance:${account.user.email}`}, action: {stringValue: 'Courier reset for review'},
        collection: {stringValue: 'users'}, targetId: {stringValue: uid},
        before: {mapValue: {fields: document.fields}}, after: {mapValue: {fields: after}},
      }}, currentDocument: {exists: false}, updateTransforms: [{fieldPath:'createdAt',setToServerValue:'REQUEST_TIME'}]},
    ]});
    changed++;
  }
  console.log(JSON.stringify({resetToPending: changed, accountsDeleted: 0}));
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
