// Apply an explicitly selected admin decision using the existing CLI operator.
// Never selects a target automatically and never sends mail directly.
const path = require('node:path');
const crypto = require('node:crypto');
const request = require('node:module').createRequire(path.join(__dirname, '../functions/package.json'));
const {initializeApp} = request('firebase-admin/app');
const {getAuth} = request('firebase-admin/auth');
const cli = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
const project = 'craftisan-we114-2026';
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;

async function main() {
  const args = process.argv.slice(2);
  const uid = args[args.indexOf('--uid') + 1];
  const decision = args[args.indexOf('--decision') + 1];
  if (!args.includes('--uid') || !args.includes('--decision') || !/^[A-Za-z0-9_-]+$/.test(uid) || !['approved','rejected'].includes(decision)) {
    throw new Error('Specify --uid and --decision approved|rejected.');
  }
  const account = cli.getGlobalDefaultAccount();
  if (!account) throw new Error('Firebase CLI login is required.');
  const token = await cli.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const headers = {Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json'};
  const app = initializeApp({projectId: project, credential: {getAccessToken: async () => ({access_token: token.access_token, expires_in: 3600})}});
  const user = await getAuth(app).getUser(uid);
  if (user.disabled) throw new Error('This Authentication account is disabled.');
  const profileResponse = await fetch(`${base}/users/${uid}`, {headers});
  const profile = await profileResponse.json();
  if (!profileResponse.ok || profile.fields.role?.stringValue !== 'courier') throw new Error('Courier profile not found.');
  const before = profile.fields;
  if ((before.courierApproval?.stringValue ?? 'pending') !== 'pending') throw new Error('The application has already been reviewed.');
  if (!user.email || user.email !== before.email?.stringValue) throw new Error('The signup email and Authentication account do not match.');
  const queueResponse = await fetch(`${base}/courierApprovalEmails/${uid}`, {headers});
  if (queueResponse.status !== 404) throw new Error('An email already exists or the queue could not be checked.');
  const actor = `maintenance:${account.user.email}`;
  const after = {...before, courierApproval: {stringValue: decision}, courierReviewedBy: {stringValue: actor}};
  delete after.courierReviewedAt;
  const message = decision === 'approved'
    ? {subject: 'Your Craftisan courier account is verified', text: 'Your courier account has been verified and approved by admin. You can now log in to Craftisan Delivery.'}
    : {subject: 'Your Craftisan courier application was not approved', text: 'Your courier application was reviewed and rejected by admin. Delivery access is not enabled. Please contact the Craftisan admin team for more information.'};
  const audit = `projects/${project}/databases/(default)/documents/adminActivity/courier-review-${crypto.randomUUID()}`;
  const response = await fetch(`${base}:commit`, {method: 'POST', headers, body: JSON.stringify({writes: [
    {update: {name: profile.name, fields: after}, currentDocument: {updateTime: profile.updateTime},
      updateTransforms: [{fieldPath:'courierReviewedAt',setToServerValue:'REQUEST_TIME'}]},
    {update: {name: `projects/${project}/databases/(default)/documents/courierApprovalEmails/${uid}`, fields: {
      to: {stringValue:user.email}, message: {mapValue:{fields:{subject:{stringValue:message.subject},text:{stringValue:message.text}}}},
    }}, currentDocument:{exists:false}, updateTransforms:[{fieldPath:'createdAt',setToServerValue:'REQUEST_TIME'}]},
    {update: {name:audit, fields:{actorId:{stringValue:actor}, action:{stringValue:decision==='approved'?'Courier approved':'Courier rejected'},
      collection:{stringValue:'users'}, targetId:{stringValue:uid}, before:{mapValue:{fields:before}},after:{mapValue:{fields:after}}}},
      currentDocument:{exists:false}, updateTransforms:[{fieldPath:'createdAt',setToServerValue:'REQUEST_TIME'},{fieldPath:'after.courierReviewedAt',setToServerValue:'REQUEST_TIME'}]},
  ]})});
  if (!response.ok) throw new Error(`Decision not applied (${response.status}); profile may have changed.`);
  console.log(JSON.stringify({uid,decision,emailQueued:true,operator:'Firebase CLI maintenance',emailSent:false}));
}
main().catch(error => {console.error(error.code ? `Request could not be reviewed (${error.code}).` : error.message);process.exitCode=1;});
