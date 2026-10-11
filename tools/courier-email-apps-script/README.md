This is the selected free email flow. It replaces the pending SMTP/Blaze plan. Sender: `ksathsara378@gmail.com`. No Gmail App Password, public web app, service-account private key or paid Firebase extension is needed.

Owner setup (Google requires the sender's authorization):

1. Open https://script.google.com/ while signed in as **ksathsara378@gmail.com**, then create a new project named **Craftisan Courier Emails**.
2. Paste `Code.gs` into the project's Code.gs file. In Project Settings, enable **Show appsscript.json manifest file in editor**, then copy this folder's `appsscript.json` into that manifest.
3. In **Project Settings → Script Properties**, add the four names and values from the private local file `build/courier-email-worker.private.json`: `FIREBASE_API_KEY`, `WORKER_EMAIL`, `WORKER_PASSWORD`, `WORKER_UID`. Do not post its contents in chat or commit it. Do not share edit access to this Apps Script project.
4. Select **installCourierEmailTrigger**, click Run, and authorize email sending with the sender account. Then run **sendCourierDecisionEmails** once to check a genuine queued decision. The trigger checks every five minutes thereafter.

The Firebase worker can read the decision queue and change delivery metadata, but cannot create emails, redirect recipients, change approval decisions or write orders. It has no profile in the app's user directory. Server-only `emailWorkers/{workerUid}.enabled=false` disables its queue access.

MailApp's consumer-account quota currently permits 100 recipients/day. Each run processes at most 20 messages, respects the remaining quota, and uses a script lock plus Firestore document-version preconditions. Jobs are claimed before sending. SENT, FAILED and PROCESSING jobs are never automatically resent. A crash after Gmail accepts an email but before status persistence can leave PROCESSING; review it manually before retrying to avoid duplicates. SENT means MailApp accepted the send, not proof of inbox delivery; also check the recipient's inbox/spam folder.

Do not run the SMTP extension and this script on the same queue. The script also handles existing unsent records, so initial authorization may send previously queued admin decisions.

References:

- https://developers.google.com/apps-script/reference/mail/mail-app
- https://developers.google.com/apps-script/guides/services/quotas
- https://developers.google.com/apps-script/guides/triggers/installable
- https://firebase.google.com/docs/firestore/use-rest-api
