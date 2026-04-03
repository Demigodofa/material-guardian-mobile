# Backend Rollout Status

Date: 2026-04-01

This note keeps the shared mobile repo aligned with the backend repo so Flutter work does not drift from the actual account/entitlement implementation state.

## Current backend status

The backend repo `app-platforms-backend` now has:

- a runnable TypeScript/Fastify scaffold
- normalized Material Guardian plan catalog endpoints
- a real Neon/Postgres dev path for plan catalog, auth challenge/session flow, refresh-token rotation, `GET /me`, entitlement, trial, and org summary endpoints
- a Postgres foundation for the real backend path:
  - migration scripts
  - database connection helper
  - config fields for DB/email/store verification credentials

The backend is no longer docs-only or demo-only.

It now has a live dev database path, but it is still not a finished production backend.

It does **not** yet mean production-ready:

- fully hardened auth
- final production email-delivery approval state
- final session token storage model
- real Apple verification
- real sync/recovery

## What mobile can safely assume now

Shared Flutter should assume the long-term backend model is:

- app account
- one active authenticated session per user
- organization membership
- seat assignment
- normalized plan catalog
- normalized entitlement state
- server-side trial counting
- backend-owned free-job trial limits, with the current intended launch target now `6`

Shared Flutter can now also assume that the backend dev environment is real enough to support the first real account shell, not just mock contracts.

Shared Flutter should **not** assume yet:

- that purchase verification exists end to end
- that document sync exists
- that account-backed cloud storage is active
- that current local-only privacy wording is still valid once backend features ship

## What is done in mobile already

The Flutter repo already has:

- shared shell and donor-aligned workflow base
- local jobs and drafts
- local customization/defaults
- local signatures, photos/scans attachments, and export/share entry points
- Android package identity alignment and first real Samsung validation
- a first real backend account shell:
  - sign-in start and code completion
  - refresh-token-backed session restore
  - bearer-auth `/me` and entitlement hydration
  - membership display plus org access-code redemption
  - simple org-admin invite / resend / seat / remove actions for backend testing
  - backend-typed plan loading
  - signed-in organization creation for business checkout
  - first Google Play purchase shell that maps store purchases back into backend verification
  - live Google Play internal-test validation of business yearly purchase restore and backend verification
  - Samsung-safe bottom insets on the account flow so sign-in and org buttons stay above system navigation
  - client-side email-shape validation before auth start requests are sent
  - explicit Play billing catalog diagnostics so Android internal-test builds can now tell you whether the store is unavailable, the query returned an error, or specific product IDs were not found
  - release gating for the raw backend diagnostics card so the active service URL is no longer shown in customer-facing release builds
  - account UX cleanup so organization creation stays available after the first organization exists and billing status/errors read more clearly
  - a dedicated sales/trial screen that is now being hardened as a real buying surface instead of a backend test page:
    - tighter first-viewport phone layout
    - stronger plan-value copy
    - explicit explanation that business admins can manage seats/settings without occupying a production seat
    - explicit explanation that an admin can also choose to occupy a seat when they need report-creation access
  - centered/constrained large-screen layout for the main shell surfaces so tablets and desktop-width previews do not sprawl edge to edge:
    - plans
    - account/admin
    - customization
    - drafts
    - job detail
    - receiving form
    - privacy policy
  - account/recovery wording cleanup:
    - same-email sign-in on a new device is now explained directly in-app
    - the account summary now says this device stays signed in until sign-out or app-data loss
    - the admin/account surface now explicitly recommends keeping at least one trusted admin active for business continuity
  - local-first privacy wording cleanup in-app:
    - the privacy screen no longer claims the app is account-free
    - it now distinguishes backend-managed account/org/subscription state from local report/job/media data
  - field caps extended to create-job dialog inputs so long job-number/description/notes entry no longer becomes an unbounded layout/input path
  - create-job dialog save flow hardened after Samsung/debug validation:
    - the dialog no longer writes app-state changes before the route closes
    - one-shot dialog fields no longer keep disposable controllers alive across the close animation
    - widget coverage now includes a regression that opens the dialog, creates a job, and asserts no framework exception
  - signed-out sales/trial flow tightened again after fresh device/emulator validation:
    - the actual `Start Free Trial` form now sits above the long plan-explanation block instead of being buried below it
    - small-phone and tablet first-viewports now show the real account-entry action much earlier
    - Samsung bottom-nav clipping on the `Send Email Code` CTA is now fixed with extra bottom list padding on the live `Plans` screen
  - signed-in account/admin wording cleanup:
    - recovery copy is shorter and less repetitive
    - organization summaries now read with cleaner status separators instead of dense pipe-delimited strings
    - the active organization is no longer redundantly repeated in the memberships card
  - paid-account sales behavior is now cleaner:
    - accounts with an active paid entitlement see an `Active subscription` summary instead of the full buy-button catalog
    - restore/refresh remains available for billing recovery without making subscribed users browse every plan again
  - signature capture is hardened:
    - the shared Flutter signature dialog now uses local pan positions instead of render-box global conversion
    - capture failures now surface a user-facing retry message instead of silently doing nothing
  - Android media capture cleanup:
    - the in-app photo/scan camera preview now uses a cover-style framing path so Samsung no longer shows the visibly squished capture preview
    - Android `Scan MTR/CoC PDFs` now routes through ML Kit document scanning again instead of only the custom camera overlay, with camera fallback still available if the scanner cannot start
    - empty photo/scan slots now show explicit icons and slot numbers instead of reading like blank dead buttons
  - stale edit-draft save safety:
    - completing an edit draft no longer throws just because the referenced source material was removed earlier; the app now falls back to saving it as a new material record instead of failing the whole save
  - donor-aligned receiving-form layout cleanup after fresh Samsung and emulator review:
    - narrow-width rows now collapse instead of crushing fields together:
      - `Qty / Product / A/SA`
      - `Fitting / B16 Type`
      - `TH 1-4`
      - `Width / Length / Diameter / ID/OD`
    - dropdown labels now sit outside the field body, which reads closer to the donor app and removed the jammed floating-label look on real phones
  - customization asset persistence is tighter:
    - capturing, importing, replacing, or removing the default inspector signature now saves immediately instead of waiting for a later general save
    - importing, replacing, or removing the company logo now also saves immediately
    - this reduced the earlier Samsung confusion where signature capture looked like it had not stuck
  - packet export parity moved materially closer to the donor Android form:
    - the first page now renders as a bordered receiving-inspection sheet instead of a loose text dump
    - job/vendor/PO/date, quantity/product/specification/grade/fitting, dimensions, inspection decisions, comments, QC rows, and signatures now read in one structured form block
    - a reusable manual export probe test can now copy the seeded packet, ZIP, and export info to the Windows Desktop for visual comparison without a device round-trip
  - wider-form-factor validation now includes a real Android tablet emulator pass:
    - Pixel Tablet landscape kept the sales first CTA in the initial viewport
    - Pixel Tablet portrait also kept the trial stack readable without system-bar clipping
    - the centered large-screen layout held the shell content together correctly
  - smaller Android phone-emulator validation now also confirms the signed-out `Plans` stack still reads cleanly on a tighter vertical viewport without clipping the first CTA or the start-trial card
  - Google Play billing is not a valid truth source on that emulator because BillingClient reported unsupported API access, so real billing remains phone/internal-test only

## Path forward from the mobile side

### Immediate next mobile/backend handshake

1. validate the new shared sign-in/account shell against the live backend on-device
2. switch trial UX assumptions to the launch target of `6` backend-counted free jobs
3. split the signed-out launch path from the signed-in jobs landing so the paywall/sales surface is not the same screen as account/admin
4. keep persisted backend sessions going straight to the jobs landing; if app data is cleared, require email-code sign-in again because the cached local session is gone
5. move the current mixed account/sales/admin surface toward:
   - signed-out sales/trial screen
   - signed-in account/admin screen
   - customization screen
6. keep solo users on the same customization/report-settings surface as admins, with seats/invites only appearing for business admins
7. hide the account/admin entry point for seated non-admin users while still leaving them access to their own printed-name/signature customization
8. keep local jobs/drafts working while backend account work lands
9. keep sales/trial copy explicit about what each plan unlocks:
   - single-user full workspace
   - business branding/report-default control
   - seat assignment
   - admin-vs-seat behavior
10. consume backend `GET /plans` in customer-facing pricing/paywall screens
11. validate real Android purchase callbacks on-device and confirm successful backend verification against the live dev backend
12. keep privacy/store wording aligned with the actual backend-backed release scope
13. use the next internal-test Play build to confirm whether the current billing blocker is propagation, tester access, or mismatched product visibility

### After the first real backend auth pass

1. harden session-conflict replace flow on-device
2. add entitlement-aware paywall/account state
3. move from operator-style admin controls toward cleaner business UX
4. keep purchase verification, privacy wording, and store disclosures in step with the real release path
5. remove the temporary operator-style backend diagnostics from the visible account flow before release
6. keep running the Desktop export probe and donor PDF comparison after any material export-layout change so packet regression is caught visually, not only by file-exists checks

### Deferred until later

1. cloud document sync
2. cross-device recovery for jobs/media
3. usage-metered Pro storage/API features

## Current known blocker

The live backend path is now proven far enough for:

- sign-in by code
- owner/admin org membership
- business seat assignment
- single-user and business purchase verification on the backend

The current unresolved Android release blocker is narrower:

- the Play-installed app still is not receiving subscription `ProductDetails`
- the next internal-test build now includes explicit missing-product/error messaging so the exact Play-side mismatch can be read directly from the account screen instead of inferred from disabled buy buttons

## Repo ownership reminder

- `material-guardian-mobile`
  mobile workflow, shared client, Apple handoff, privacy/store readiness wording for future mobile releases
- `app-platforms-backend`
  auth, orgs, seats, plans, entitlements, sessions, trials, purchase verification, and hosting direction
- `MaterialGuardian_Android`
  current shipped/reference behavior and current production privacy wording until the shared app replaces it
