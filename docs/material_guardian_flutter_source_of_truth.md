# Material Guardian Flutter Source Of Truth

Date: 2026-03-31

This is the current Flutter/mobile source of truth for the shared Material Guardian client.

If another repo has older Flutter migration notes, this file wins.

## Active repo ownership

- `material-guardian-mobile`
  authoritative repo for Flutter/mobile architecture, migration, shared-client notes, Apple handoff docs, and copied mobile reference assets
- `app-platforms-backend`
  authoritative repo for monetization, plans, subscriptions, entitlements, sessions, and backend contract notes
- `MaterialGuardian_Android`
  current behavior reference for the shipping Android app until Flutter replaces it

## Canonical handoff locations

- Apple/iOS coordination notes should now live under `ios/` in this repo.
- Apple-specific follow-up for the current Flutter scaffold should be tracked in `ios/apple-platform-todo-2026-04-01.md`.
- The default shared-vs-platform build strategy should be tracked in `docs/flutter_cross_platform_build_plan.md`.
- Android donor behavior and implementation references still live in `MaterialGuardian_Android`.
- Copied Android reference assets now live under `assets/reference/android-source/` in this repo so Flutter/iOS work can proceed without hunting across repos.

## Product direction

Material Guardian is moving toward:

- one shared Flutter client for Android and iPhone
- backend-owned auth, plans, subscriptions, seats, trials, sessions, and entitlements
- deliberate behavior parity with the current Android app instead of a casual redesign

Current reality:

- the Flutter scaffold and first shared shell now exist in this repo
- shared Dart workflow should stay cross-platform by default
- the receiving form now carries a meaningful donor-aligned field block rather than only a placeholder shell
- saved-material editing now goes back through the same shared form and draft lifecycle rather than using a separate platform-specific edit path
- donor inspection decision state is now part of shared Flutter behavior instead of remaining Android-only
- shared Flutter now owns local media attachment, reusable/default signature capture, privacy-policy display, and packet PDF plus ZIP export/share entry points
- job editing and material deletion now exist in the shared Flutter job-detail flow
- Android release identity is aligned to `com.asme.receiving`, with debug builds split to `com.asme.receiving.dev` so device testing does not have to overwrite the shipped app
- this repo has already produced a Windows-built debug APK and release AAB, so Android compile plumbing is no longer hypothetical
- first real Android phone validation has now happened on a Samsung S911U; install, launch, and home-screen rendering are proven, and the first device-found safe-area bug has already been fixed in shared Flutter layout code
- iOS-specific fit and validation still need to be completed on the Mac through the Apple handoff queue

## Current reference behavior to preserve

- offline-first local workflow
- blank `Add Material`
- explicit `Resume Draft` and `Delete Draft`
- editable jobs and deletable saved materials
- both `Share PDFs` and `Share ZIP`
- customization-driven QC printed-name defaults
- optional saved QC inspector signature flow
- in-form captured signatures for inspector and manager
- one-page report expectations
- export/share behavior that works with real business targets like SharePoint

## Migration order

### Phase 1

- keep the Android app stable as the behavior reference
- define backend contract first
- install Flutter tooling on the active development machines
- scaffold the shared Flutter app shell in this repo

### Phase 2

- prove sign-in, jobs list, and job detail
- define state-management and service pattern
- build the paywall/plan-selection structure with monthly versus yearly pricing and savings display
- keep local jobs, drafts, and customization persistent while backend work is still incomplete

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
