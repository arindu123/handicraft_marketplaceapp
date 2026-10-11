Courier accounts require `users/{uid}.courierApproval == approved` and an active account to access the delivery workspace and orders. New email/password and Google accounts start as pending. Missing approval fields also deny delivery access.

Admin reviews courier details in the existing Approvals list. Approve/reject writes the decision, audit record and corresponding approval/rejection email atomically. Both decisions queue one document at `courierApprovalEmails/{uid}` addressed to the courier's signup email. The app does not mark this email as sent.

Selected email flow: Google Apps Script + MailApp, sender `ksathsara378@gmail.com`. No billing account, SMTP App Password or Firebase email extension is used. The Apps Script owner must authorize sending with that Google account before real delivery can start.

Implementation and owner setup: `tools/courier-email-apps-script/README.md`. Run `node tools/provision-courier-email-worker.cjs --apply` only as part of the authorized setup. The script creates a restricted internal Firebase Authentication worker and a private, ignored Script Properties handoff in `build/courier-email-worker.private.json`. It does not use the exposed service-account key or change billing.

The worker's Firestore writes are limited to delivery status metadata. It cannot approve couriers, modify recipient/content, create emails or write orders. Incomplete sends require manual review; no automatic resend of claimed jobs is allowed.

2026-10-11: Free email-worker rules deployed and internal worker provisioned. Live checks confirmed worker sign-in and queue reads succeed while private orders/users reads are denied. Worker credentials are in the ignored private handoff file. Billing was not changed. No Gmail message has been sent; Apps Script creation, sender consent and trigger installation remain owner steps.

2026-10-11: Courier approval rules were deployed to `craftisan-we114-2026`, preserving unrelated live buyer notification permissions. Three existing courier profiles were reset to pending with individual audit records. No Authentication accounts were deleted. There are no live Storage rule releases; the local Storage rules also include approval checks for future deployment. Sender authorization and a scheduled Apps Script trigger remain required for email delivery. Production notification Functions remain undeployed.

`node tools/courier-review-reset.cjs` prepares a snapshot of existing courier profiles in the ignored build directory. `node tools/courier-review-reset.cjs --apply` resets only those courier records to pending, with update-time preconditions and an audit record. It never deletes Firebase Authentication accounts, user records, order history, or non-courier accounts. Treat the backup as private account data.
