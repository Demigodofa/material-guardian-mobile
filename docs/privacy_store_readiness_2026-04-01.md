# Privacy And Store Readiness

Date: 2026-04-01

This note separates **current shipped wording** from **future backend-account wording** so Material Guardian does not accidentally ship account-backed behavior with old local-only statements.

## Current truth vs future truth

### Current shipped Android truth

The currently shipped Android app is still described correctly as:

- offline-first
- no required account
- local jobs/media/signatures on device
- no developer-operated cloud sync for jobs/media

That wording should remain true for the current shipped Android release until backend-backed account features are actually live in the released app.

### Future backend-account truth

Once the Flutter/mobile release includes account-backed features, the product wording must change.

At that point, Material Guardian will need wording that says, in substance:

- users may create or use an app account
- the backend stores account, session, organization, seat, trial, entitlement, and purchase-verification data
- if cloud recovery or document retrieval is enabled, user files and metadata may be stored on backend-managed infrastructure
- local exports/share actions still only go where the user chooses
- users must have a path to request account deletion and associated backend data deletion where store rules require it

## App/privacy wording buckets to keep separate

Use separate wording for these categories instead of collapsing them together:

### Account and identity

- email address
- display name if collected
- login code / magic-link handling
- organization membership and seat assignment

### Subscription and entitlement

- plan selection
- purchase verification
- subscription/entitlement status
- trial usage counters

### Device/session security

- active device/session tracking
- session replacement when the same user signs in elsewhere
- fraud/abuse prevention logs if used

### User content

- jobs
- receiving reports
- photos
- scans/documents
- signatures
- exports

### Support/operations

- error logs
- support contact flows
- admin-only audit fields where relevant

## Store-facing checklist for future account-backed releases

Before shipping backend-backed account features in the mobile app, verify:

1. privacy policy no longer says "Material Guardian does not require an account" if account creation/sign-in exists anywhere in the app experience
2. privacy policy explains what account/session/entitlement data is stored by the backend
3. store disclosure forms are updated for the actual collected/shared data categories
4. if users can create an account, the app includes an account deletion path and the public policy/help flow also reflects it
5. if cloud file retrieval exists, the privacy policy clearly separates account data from user-generated files/documents
6. if business/admin seat management exists, org/admin wording reflects that account/member metadata may be visible to authorized org admins
7. if usage-metered Pro features exist later, billing/accounting language explains what usage is measured

## Safe wording direction for the first backend-backed release

For the first release that adds account/entitlement backend features but **not yet** full document sync, the privacy policy should say the backend is used for:

- account authentication
- session management
- organization/admin/seat management
- trial enforcement
- subscription and entitlement recognition across platforms

It should also say, if still true, that:

- jobs, reports, photos, scans, signatures, and exports remain local on the device unless or until a cloud sync/recovery feature is explicitly enabled in a later release

That distinction matters.

Do not imply cloud storage of inspection files before it actually exists.

## Future wording direction for Pro cloud storage

If Material Guardian later adds Pro cloud document storage/retrieval, the privacy/data wording must expand to cover:

- what files are uploaded
- where they are stored
- who can access them
- how deletion works
- whether files are used only for storage/retrieval or also for processing features
- retention expectations

## Operational rule

Every time backend scope changes materially, update all of these together:

- mobile repo `README.md`
- this file
- public privacy policy text used by the app/site/store listing
- store disclosure forms
- backend repo environment/config docs if new data categories are introduced
