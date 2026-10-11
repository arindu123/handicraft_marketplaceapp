// Provision only the email worker. Uses Firebase CLI OAuth; no service-account key.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const functionRequire = require('node:module').createRequire(path.join(__dirname, '../functions/package.json'));
const {initializeApp} = functionRequire('firebase-admin/app');
const {getAuth} = functionRequire('firebase-admin/auth');
const cliAuth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
const project = 'craftisan-we114-2026';
const uid = 'craftisan-courier-email-worker';
const email = `courier-mail-worker@${project}.invalid`;
const handoff = path.join(__dirname, '../build/courier-email-worker.private.json');

async function main() {
  if (!process.argv.includes('--apply')) {
    console.log('Prepared: create a restricted internal email worker and a private Script Properties handoff. No billing or Gmail password needed.');
    return;
  }
  const account = cliAuth.getGlobalDefaultAccount();
  if (!account) throw new Error('Sign in using Firebase CLI first.');
  const access = () => cliAuth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const app = initializeApp({projectId: project, credential: {getAccessToken: async () => {
    const token = await access();
    return {access_token: token.access_token, expires_in: 3600};
  }}});
  const auth = getAuth(app);
  let existing;
  try { existing = await auth.getUser(uid); }
  catch (error) { if (error.code !== 'auth/user-not-found') throw new Error('Could not inspect worker account.'); }
  if (existing && (!fs.existsSync(handoff) || existing.email !== email)) {
    throw new Error('Worker already exists without this private handoff. No existing account was changed.');
  }
  const android = JSON.parse(fs.readFileSync(path.join(__dirname, '../android/app/google-services.json'), 'utf8'));
  const key = android.client.find(client => client.client_info.android_client_info.package_name === 'com.example.artisan_marketplace').api_key[0].current_key;
  const settings = fs.existsSync(handoff) ? JSON.parse(fs.readFileSync(handoff, 'utf8')) : {
    FIREBASE_API_KEY: key, WORKER_UID: uid, WORKER_EMAIL: email,
    WORKER_PASSWORD: crypto.randomBytes(32).toString('base64url'),
  };
  if (settings.WORKER_UID !== uid || settings.WORKER_EMAIL !== email) throw new Error('Unexpected worker handoff.');
  fs.mkdirSync(path.dirname(handoff), {recursive: true});
  // Save privately before the remote create so a partial failure can be retried.
  fs.writeFileSync(handoff, JSON.stringify(settings, null, 2));
  if (!existing) {
    await auth.createUser({uid, email, password: settings.WORKER_PASSWORD,
      displayName: 'Courier email worker (Apps Script)'});
  }
  const token = await access();
  const response = await fetch(`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/emailWorkers/${uid}?updateMask.fieldPaths=enabled`, {
    method: 'PATCH', headers: {Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json'},
    body: JSON.stringify({fields: {enabled: {booleanValue: true}}}),
  });
  if (!response.ok) throw new Error(`Worker permission configuration failed (${response.status}).`);
  console.log(JSON.stringify({workerConfigured: true, privateHandoff: 'build/courier-email-worker.private.json', billingChanged: false}));
}
main().catch(() => {console.error('Worker setup did not complete. No credentials are printed; inspect configuration and retry.'); process.exitCode = 1;});
