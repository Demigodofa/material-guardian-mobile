# Material Guardian Android Release Handoff 2026-04-17

This is the active pickup note for continuing the Android release from another machine.

## Current repo truth

- Repo: `material-guardian-mobile`
- Branch: `main`
- Customer-facing backend target in source:
  - `https://app-platforms-backend-prod-293518443128.us-east4.run.app`
- Release package:
  - `com.asme.receiving`
- Debug package:
  - `com.asme.receiving.dev`
- Latest rebuilt artifacts from current source:
  - `build/app/outputs/flutter-apk/app-release.apk`
  - `build/app/outputs/bundle/release/app-release.aab`
- Fresh validation rerun on 2026-04-17:
  - `flutter analyze`
  - `flutter test`

## What was already closed before this handoff

- The mobile app now targets the production-named Cloud Run backend by default in release docs/source.
- The new production Cloud Run service exists and is healthy:
  - `app-platforms-backend-prod`
- The app-side restore flow was hardened so Android restore no longer fails silently.
- Google purchase restore now has three distinct user-facing outcomes:
  - purchases found and verified
  - no purchases returned on this device
  - restore/backend error
- Paid business access no longer pretends billing is fully ready when the backend returns `no_seat`.
- Startup purchase updates now defer until auth and purchase-catalog hydration are ready.
- Trial and seat gating now applies to report-level draft creation/completion, not only top-level job creation.
- Snapshot persistence is now atomic, backup-backed, and tolerant of corrupt primary JSON.
- Current-source validation was green before this handoff:
  - `flutter analyze`
  - `flutter test`

## What was proven live on 2026-04-17

### 1. Prod backend auth/session path is working

Against `app-platforms-backend-prod`, the phone successfully:

- started auth for `granitemfgllc@gmail.com`
- completed auth with a fresh email code
- hydrated `/me`
- hydrated `/entitlements/current`
- hydrated the Granite MFG organization

The phone ended in the signed-in state with:

- `Access status: Paid`
- `Current plan: Business 5 Users Yearly`
- `Workspace: Granite MFG LLC`

### 2. Restore Purchases no longer lies by omission

On the Samsung handset, the signed-in `Plans` screen now shows the restore result explicitly after a tap:

- `No purchases were returned to re-link on this device. Your backend access is still active.`

That is the current honest outcome on the live handset.

### 3. The restore tap did not reach backend verification

During the live restore attempt on 2026-04-17, prod Cloud Run request logs showed only:

- `GET /me`
- `GET /entitlements/current`
- `GET /organizations/:id`

There was no fresh:

- `POST /purchases/google/verify`

So the current blocker is not a mysterious backend failure. The phone did not produce a relinkable Google Play purchase for the app to send to prod.

## Current root-cause framing

The remaining billing blocker is now narrow:

- Material Guardian on the Samsung is signed in and paid on the backend
- the restore UI path works and surfaces a truthful result
- prod backend is healthy
- but Google Play returned no purchase to re-link on this device

The most likely remaining causes are:

1. the Google Play account on the phone is not the account that owns the Material Guardian subscription
2. the subscription is expired/canceled in Google Play truth
3. the current install context is not sufficient for final billing proof and the app needs to be installed from the Play internal-testing track for the final restore test

## Important backend/environment truth

- Production backend service:
  - `app-platforms-backend-prod`
- Dev backend service still exists:
  - `app-platforms-backend-dev`
- Current caveat:
  - prod and dev are still cloned from the same tested environment shape and are not yet a true split with separate database state
- Google RTDN push subscription was retargeted to prod during this pass:
  - subscription: `material-guardian-google-rtdn-push`
  - push endpoint: `https://app-platforms-backend-prod-293518443128.us-east4.run.app/billing/google/rtdn`

## Highest-priority remaining work

### Ship blocker 1: final Google Play ownership proof

On the Samsung:

1. open Google Play Store
2. confirm the active Play account is the one that owns the Material Guardian subscription
3. open `Payments & subscriptions` -> `Subscriptions`
4. verify the Material Guardian business subscription is actually active there

If it is not active there, restore cannot relink anything.

If it is active there, the next strongest proof is:

1. install Material Guardian from the Play internal-testing track
2. sign in as `granitemfgllc@gmail.com`
3. run `Restore Purchases`
4. confirm prod receives `POST /purchases/google/verify`
5. confirm entitlement/subscription-link state updates cleanly

### Ship blocker 2: final store-release confidence

After the Google Play billing proof:

1. rebuild if any code/config changed
2. verify the exact release AAB intended for upload
3. finalize Play screenshots/listing assets
4. re-check Play Console Data safety answers against the actual current app behavior

## Useful pickup facts

- Granite MFG owner email:
  - `granitemfgllc@gmail.com`
- Connected handset during this pass:
  - `RFCW40P51JK`
- Fresh auth email code used successfully during this pass:
  - the final successful challenge email on 2026-04-17 was `412906`
- The restore result on the phone is now deterministic and should be treated as real evidence, not a UI automation artifact.

## Read next

1. `docs/android_release_master_checklist_2026-04-14.md`
2. `docs/android_stress_sweep_2026-04-14.md`
3. `docs/play_release.md`
