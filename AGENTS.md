# Mobile Repo Guidance

## Role of this repo

- This repo will hold the shared Flutter client for Android and iPhone.
- This repo is now the source of truth for Material Guardian mobile planning, Apple handoff notes, and shared-client migration assets.
- It is not a place to improvise product behavior independently from the Android reference app.

## Porting rules

- `MaterialGuardian_Android` remains the behavior reference until the Flutter app replaces it.
- Port behavior deliberately; do not simplify flows just because Flutter makes a new layout easy.
- Keep platform-specific work isolated when camera, scanning, sharing, or billing behavior differs.
- Use `docs/flutter_cross_platform_build_plan.md` as the default split between shared Dart work and platform-specific work.
- Treat `ios/` in this repo as the canonical Apple handoff area.
- Treat `assets/reference/android-source/` as copied donor material from the Android repo, not as proof that the Android implementation can be lifted directly into Dart.

## Backend rules

- Consume normalized backend entitlement state.
- Do not hard-code Apple-only or Google-only purchase assumptions into shared app logic.
- Shared Dart code should depend on app-platform concepts like user, org, seat, session, and entitlement.

## Current bootstrap rule

- The Flutter scaffold now exists in this repo.
- Keep backend contract changes explicit and do not let the shared client quietly invent plan, entitlement, or session behavior.
