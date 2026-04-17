# Apple Handoff 2026-04-13

This note exists so the next iOS-focused agent does not have to reconstruct what was already done during the Android release push.

## Current release priority

- The active shipping lane is Android-first.
- Do not treat iOS/App Store release as active until Apple developer authorization, signing, and store access are actually available.
- If work overlaps cleanly with Android/backend hardening, keep it. Do not spend time polishing Apple-only release surfaces until the Apple account lane is open.

## What was completed now because it overlaps

### Backend Apple purchase verification is no longer a hardcoded stub at purchase time

Implemented in the backend repo:

- `app-platforms-backend/apps/api/src/purchase/apple-receipt-verifier.ts`
- `app-platforms-backend/apps/api/src/postgres-store.ts`
- `app-platforms-backend/apps/api/src/app.ts`
- `app-platforms-backend/apps/api/src/store-factory.ts`

What this now does:

- accepts Apple receipt data on `POST /purchases/apple/verify`
- calls Apple receipt verification from the backend
- retries sandbox receipts correctly when Apple returns `21007`
- validates bundle ID when configured
- normalizes:
  - product ID
  - transaction ID
  - original transaction ID
  - expiry
  - refunded/canceled state
- rejects expired or refunded Apple subscriptions instead of minting access anyway

What this does **not** mean:

- this is not a full iOS/App Store release signoff
- this was not live-proven against a real Apple sandbox or production account in this pass
- App Store Server Notifications are still scaffolded only

### Shared mobile client now forwards Apple receipt payloads

Implemented in the mobile repo:

- `lib/app/material_guardian_state.dart`
- `lib/services/backend_api_service.dart`
- `test/backend_api_service_test.dart`

What this now does:

- forwards Apple receipt data from the store purchase flow into backend purchase verification
- keeps Google-specific payload handling separate

## Important current truth for the next iOS agent

The next iOS agent should assume:

- shared auth/session/org logic is not the main blocker
- backend Apple purchase verification is partially prepared now
- Apple lifecycle ingestion is still incomplete
- Apple device/simulator validation is still incomplete
- Apple signing/App Store Connect/store metadata work is still incomplete

## Still blocked or incomplete

### 1. No Apple release authorization yet

- no Apple developer/store-authorization path should be assumed live
- do not claim iOS release readiness from these backend/mobile overlap changes

### 2. App Store Server Notifications are still scaffolded only

Still pending in the backend repo:

- `app-platforms-backend/apps/api/src/billing/apple-app-store-notifications.ts`

Current state:

- route exists
- verification/decoding is not finished
- lifecycle ingestion is not production-ready

### 3. Apple-side validation is still missing

Still not re-proven in this pass:

- iPhone simulator build/run
- real-device install/signing
- iOS share/export behavior
- iOS camera/photo/document plugin behavior
- iOS billing purchase/restore smoke

### 4. iOS release metadata is still not ready

Still pending:

- real bundle identity confirmation
- Apple team signing
- App Store Connect metadata
- screenshots / previews
- privacy/review text specific to Apple submission

## What the next iOS agent should read first

1. `ios/README.md`
2. `ios/apple-platform-todo-2026-04-01.md`
3. this file
4. `../docs/release_handoff_2026-04-09.md`
5. `../../app-platforms-backend/docs/apple_purchase_verification_backend_handoff_2026-04-10.md`

## Recommended next Apple-side sequence

1. Confirm Apple developer authorization, signing access, and the real bundle/team path.
2. Re-prove the shared Flutter iOS app locally on the Mac or a real iPhone.
3. Run a real Apple sandbox purchase/restore smoke against the new backend verification path.
4. Only after that, finish Apple notification ingestion and store-submission polish.

## Recommended non-goals until Apple auth is live

- do not burn time on speculative App Store Connect polish
- do not claim billing parity from code inspection alone
- do not weaken Android release momentum to chase Apple-only tasks prematurely
