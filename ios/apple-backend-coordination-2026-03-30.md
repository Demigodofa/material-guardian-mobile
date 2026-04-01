# Apple Backend Coordination Note

Date: 2026-03-30

This note is for the Apple/macOS-side agent building the iOS version of Material Guardian.

Direction update:

- long-term client strategy is now shared Flutter + backend
- use this Apple note for Apple/store/platform-specific concerns, not as a signal to build a separate long-term native iOS product by default
- current Android behavior still defines product behavior until the Flutter client exists
- active repo split is now:
  - `MaterialGuardian_Android` for the current shipping/reference app
  - `material-guardian-mobile` for the future shared Flutter client
  - `app-platforms-backend` for the shared backend
- Flutter/mobile source of truth now lives in `material-guardian-mobile/docs/material_guardian_flutter_source_of_truth.md`
- backend/monetization source of truth now lives in `app-platforms-backend/docs/material_guardian_monetization_source_of_truth.md`

## Why this note exists

Product direction is expanding beyond a local-only mobile utility.
The Android planning direction now assumes future backend-backed:

- auth
- subscriptions
- business/admin accounts
- seat management
- trial enforcement
- one-device-active session behavior
- cross-platform access between iPhone and Android

The iOS app should not be designed in a way that assumes purchase and identity live only on-device or only inside Apple purchase state.

## High-level product direction

- business plan example in mind: `5 seats` at about `$49.99 / month`
- individual users also need sign-in and entitlement state
- one user may have unlimited devices, but only one active signed-in device at a time
- signing in on a new device should allow replacing the old active session
- trial plan in mind:
  - `2` free jobs
  - unlimited material receiving inside those jobs

## iOS-side implications

The iOS app will likely need future support for:

- sign-in screen
- invite acceptance
- email code / magic link / backend-issued login flow
- session replacement prompt
- current plan / seat state display
- admin user management UI
- subscription or entitlement status UI
- sync-aware data model if users are expected to recover jobs on another device

## Important architecture warning

Do not assume that:

- Apple receipt state alone is the long-term source of truth
- purchase on one Apple device is enough for all future entitlement logic
- store purchase identity and app user identity are the same thing

The likely clean architecture is:

- Apple purchase handled through iOS-compliant purchase flow
- purchase verified by backend
- backend attaches entitlement to app account / organization
- Android and iOS both read entitlement from backend

## Seat/admin expectations

Likely admin capabilities:

- add user
- delete user
- send login code
- resend login code
- assign seat
- see seat count and seat usage

Likely user identity fields:

- name
- email
- backend-managed login token or invite flow

## Session expectations

Target behavior:

- one active logged-in device per user
- if same user logs into another device, app asks whether to sign out the current active device
- backend revokes prior session if user confirms

## Data sync warning

If users are expected to switch devices and recover jobs, then iOS should eventually plan for backend sync of:

- jobs
- materials
- media
- export-related records or references

If backend sync is not present, login alone will not restore local work on a second device.

## What the Apple-side agent should avoid

- do not hardwire business access to Apple-only purchase state
- do not build final admin/subscription UX around Apple-only assumptions
- do not assume Android access should be blocked if the original purchase was on iPhone

## Near-term non-backend parity notes

Before backend work lands, the mobile product direction also now expects:

- explicit draft access instead of letting the main `Add Material` action reopen the last abandoned draft
- both `Share PDFs` and `Share ZIP` export options for business workflows like SharePoint
- customization-driven default QC printed names
- an optional saved QC inspector signature flow for repeated report entry

## Recommended pickup for future Apple/backend session

1. read `docs/monetization_backend_handoff.md`
2. treat backend entitlement design as shared Android+iOS product work
3. keep iOS auth/session/subscription architecture compatible with cross-platform backend control
