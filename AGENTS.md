# Mobile Repo Guidance

## Role of this repo

- This repo will hold the shared Flutter client for Android and iPhone.
- It is not a place to improvise product behavior independently from the Android reference app.

## Porting rules

- `MaterialGuardian_Android` remains the behavior reference until the Flutter app replaces it.
- Port behavior deliberately; do not simplify flows just because Flutter makes a new layout easy.
- Keep platform-specific work isolated when camera, scanning, sharing, or billing behavior differs.

## Backend rules

- Consume normalized backend entitlement state.
- Do not hard-code Apple-only or Google-only purchase assumptions into shared app logic.
- Shared Dart code should depend on app-platform concepts like user, org, seat, session, and entitlement.

## Current bootstrap rule

- This repo is docs-first until Flutter tooling is installed in the active environment and the backend contract is clear enough to scaffold against.

