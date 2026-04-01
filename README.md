# material-guardian-mobile

Shared Flutter mobile client for Material Guardian.

This repo is now the source of truth for the shared Material Guardian mobile client.
It is the future home of the cross-platform Android and iPhone app.
Until the migration exists, `MaterialGuardian_Android` remains the product behavior reference and donor repo.

## Current state

This repo now contains the initial Flutter scaffold and the first shared app shell.

Current foundation:

- the backend contract still needs to stay ahead of hard-coded client assumptions
- the backend repo now has a runnable scaffold plus the first Postgres migration foundation, but mobile should still treat account/entitlement features as in-progress until real persistent auth and store verification land
- the current Android app is still the real implementation to copy behavior from
- the initial iOS handoff docs and Android reference assets were copied here so migration can continue without splitting product truth across repos
- the Flutter shell already proves jobs, job detail, drafts, customization defaults, and blank `Add Material`
- jobs, drafts, and customization now persist locally between launches through the Flutter app state
- the receiving form now carries a donor-aligned field set for material identity, specification, dimensions, disposition, and QC defaults
- saved materials now reopen through the same shared draft-backed Flutter form so edits update the original record instead of creating duplicates
- donor inspection-state behavior is now represented in Flutter for visual inspection plus marking/MTR yes-no-NA decisions
- shared Flutter now owns QC signature capture/import flows, local media attachment, packet PDF/ZIP export, and the privacy-policy screen
- job edit, material delete, export/share entry points, and local export persistence are now active in the Flutter client instead of being docs-only
- Android identity is aligned to the donor release package `com.asme.receiving`, while debug builds intentionally use `com.asme.receiving.dev` so phone testing can coexist with the shipped app later
- local validation has already produced a debug APK and a release AAB from this repo on Windows
- first live Samsung phone validation is now complete for install, launch, and home-screen rendering; the initial bottom safe-area overlap was found on-device and fixed in shared screen padding
- the shared Flutter direction is right for both Android and iPhone, but Apple-specific validation, permissions, export behavior, and signing are still tracked separately under `ios/`
- future account-backed releases will require updated privacy/store wording; the current shipped Android local-only policy language should not be reused blindly once backend auth/entitlements ship

## Relationship to the other repos

- `MaterialGuardian_Android`
  Current shipping/reference app. Use it to port behavior deliberately.
- `app-platforms-backend`
  Future source of truth for auth, orgs, seats, subscriptions, sessions, trials, and entitlements.

## Planned repo shape

```text
ios/       Apple handoff notes and future platform-specific setup
lib/       shared Dart app code
test/      unit and widget tests
assets/    bundled assets and copied Android reference materials
docs/      migration notes and behavior references
```

## First build targets

1. deepen donor receiving-form parity where fields are still simplified
2. continue Android-native phone validation for camera, file picker, share, export-open behavior, and form interaction beyond the shell/home screen
3. replace scaffold icons and launch visuals
4. wire the shared app to backend `plans`, `me`, and entitlement endpoints without breaking local-first jobs/drafts
5. complete the first real sign-in/account shell around the backend session model
6. complete Apple-specific identifiers, permissions, and file/share validation on the Mac
7. finalize store metadata, privacy wording, and release signing with backend scope reflected accurately

## Read first

1. `docs/material_guardian_flutter_source_of_truth.md`
2. `docs/backend_rollout_status_2026-04-01.md`
3. `docs/privacy_store_readiness_2026-04-01.md`
4. `docs/flutter_cross_platform_build_plan.md`
5. `docs/mobile_architecture.md`
6. `docs/migration_plan.md`
7. `docs/android_behavior_reference.md`
8. `docs/android_migration_inventory.md`
9. `ios/README.md`
