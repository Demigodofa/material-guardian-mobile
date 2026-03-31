# Material Guardian Flutter Source Of Truth

Date: 2026-03-31

This is the current Flutter/mobile source of truth for the shared Material Guardian client.

If another repo has older Flutter migration notes, this file wins.

## Active repo ownership

- `material-guardian-mobile`
  authoritative repo for Flutter/mobile architecture, migration, and shared-client notes
- `app-platforms-backend`
  authoritative repo for monetization, plans, subscriptions, entitlements, sessions, and backend contract notes
- `MaterialGuardian_Android`
  current behavior reference for the shipping Android app until Flutter replaces it

## Product direction

Material Guardian is moving toward:

- one shared Flutter client for Android and iPhone
- backend-owned auth, plans, subscriptions, seats, trials, sessions, and entitlements
- deliberate behavior parity with the current Android app instead of a casual redesign

## Current reference behavior to preserve

- offline-first local workflow
- blank `Add Material`
- explicit `Resume Draft` and `Delete Draft`
- both `Share PDFs` and `Share ZIP`
- customization-driven QC printed-name defaults
- optional saved QC inspector signature flow
- one-page report expectations
- export/share behavior that works with real business targets like SharePoint

## Migration order

### Phase 1

- keep the Android app stable as the behavior reference
- define backend contract first
- install Flutter tooling on the active development machines

### Phase 2

- scaffold the Flutter app shell
- prove sign-in, jobs list, and job detail
- define state-management and service pattern
- build the paywall/plan-selection structure with monthly versus yearly pricing and savings display

### Phase 3

- port receiving form shell
- port draft behavior
- port export/share entry points
- port customization defaults and saved signature flow

### Phase 4

- port photos and document scanning
- port PDF export and ZIP/PDF share flows
- wire backend-aware entitlement state and backend-driven plan catalog

## Architectural rules

- Shared Dart code should own workflow where possible.
- Platform-specific code should be isolated to camera, scanning, sharing, billing, storage, and other real device/store differences.
- Do not hard-code Apple-only or Google-only purchase assumptions into shared app logic.
- Pricing screens should consume normalized backend plan definitions.

