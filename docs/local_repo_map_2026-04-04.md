# Local Repo Map

Date: 2026-04-04

This note exists so future agents on this Mac do not waste time rediscovering where the related Material Guardian repos live or which one owns what.

## Local machine paths

- `kevin-codex`
  - path: `/Users/kevinpenfield/kevin-codex`
  - role: machine-level operating base, durable project notes, reusable knowledge, and cross-session handoff context
- `material-guardian-mobile`
  - path: `/Users/kevinpenfield/Documents/Playground/material-guardian-mobile`
  - role: current source of truth for the shared Flutter mobile client, Apple handoff notes, shared wording/flow decisions, and mobile planning
- `MaterialGuardian_Android`
  - path: `/Users/kevinpenfield/Documents/Playground/MaterialGuardian_Android`
  - role: older Android-native donor/reference app; use it as canonical behavior knowledge when porting details, but expect some notes and implementation paths to be older than the Flutter repo
- `app-platforms-backend`
  - path: `/Users/kevinpenfield/Documents/Playground/app-platforms-backend`
  - role: source of truth for auth, plans, subscriptions, entitlements, organizations, seats, sessions, and backend contract/runtime notes
- `privacy-policy`
  - path: `/Users/kevinpenfield/Documents/Playground/privacy-policy`
  - role: standalone hosted privacy-policy site/content repo

## Working interpretation

- For new mobile product wording, flow decisions, backend tie-in notes, and future plans, start in `material-guardian-mobile`.
- For exact legacy Android behavior, export/report expectations, and donor UI details, consult `MaterialGuardian_Android`.
- For backend contract or monetization questions, consult `app-platforms-backend` before changing mobile assumptions.
- For durable machine-level handoff context, consult `kevin-codex`.
- For privacy-policy site/source changes, use `privacy-policy`; do not treat mobile copies as the canonical hosted source automatically.

## iOS placement rule

Build the iPhone app in this repo, not in a separate new repo.

- Shared product logic, screens, validation, drafts, export orchestration, and backend consumption belong in shared Dart under `lib/`.
- Apple-specific work belongs under this repo's existing `ios/` folder:
  - Xcode project and Runner config
  - `Info.plist` privacy strings
  - Apple signing, bundle identifiers, capabilities, provisioning
  - iOS-specific camera/share/file/export/native glue
- Only split into a separate repo if the product direction changes away from the shared Flutter client entirely.

## Practical rule for future agents

If the question is "where should the next iOS change go?":

- shared behavior change: this repo, usually `lib/`
- iOS-only native/package/signing change: this repo, under `ios/`
- backend/API/plan/entitlement change: `app-platforms-backend`
- donor comparison/reference check: `MaterialGuardian_Android`
