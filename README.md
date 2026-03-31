# material-guardian-mobile

Shared Flutter mobile client for Material Guardian.

This repo is the future home of the cross-platform Android and iPhone app.
Until the migration exists, `MaterialGuardian_Android` remains the product behavior reference.

## Current state

This repo is bootstrapped as docs-first because:

- the backend contract should be designed before the Flutter client hard-codes assumptions
- Flutter is not installed on this Windows box yet, so a generated project here would be partial and misleading
- the current Android app is still the real implementation to copy behavior from

## Relationship to the other repos

- `MaterialGuardian_Android`
  Current shipping/reference app. Use it to port behavior deliberately.
- `app-platforms-backend`
  Future source of truth for auth, orgs, seats, subscriptions, sessions, trials, and entitlements.

## Planned repo shape

```text
lib/       shared Dart app code
test/      unit and widget tests
assets/    bundled assets and reference materials
docs/      migration notes and behavior references
```

## First build targets

1. sign-in shell
2. jobs list shell
3. job detail shell
4. receiving form shell
5. local draft persistence
6. backend-aware entitlement checks

## Read first

1. `docs/material_guardian_flutter_source_of_truth.md`
2. `docs/mobile_architecture.md`
3. `docs/migration_plan.md`
4. `docs/android_behavior_reference.md`
