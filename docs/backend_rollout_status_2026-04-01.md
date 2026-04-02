# Backend Rollout Status

Date: 2026-04-01

This note keeps the shared mobile repo aligned with the backend repo so Flutter work does not drift from the actual account/entitlement implementation state.

## Current backend status

The backend repo `app-platforms-backend` now has:

- a runnable TypeScript/Fastify scaffold
- normalized Material Guardian plan catalog endpoints
- a real Neon/Postgres dev path for plan catalog, auth challenge/session flow, refresh-token rotation, `GET /me`, entitlement, trial, and org summary endpoints
- a Postgres foundation for the real backend path:
  - migration scripts
  - database connection helper
  - config fields for DB/email/store verification credentials

The backend is no longer docs-only or demo-only.

It now has a live dev database path, but it is still not a finished production backend.

It does **not** yet mean production-ready:

- fully hardened auth
- final production email-delivery approval state
- final session token storage model
- real Apple verification
- real sync/recovery

## What mobile can safely assume now

Shared Flutter should assume the long-term backend model is:

- app account
- one active authenticated session per user
- organization membership
- seat assignment
- normalized plan catalog
- normalized entitlement state
- server-side trial counting
- backend-owned free-job trial limits, with the current intended launch target now `6`

Shared Flutter can now also assume that the backend dev environment is real enough to support the first real account shell, not just mock contracts.

Shared Flutter should **not** assume yet:

- that purchase verification exists end to end
- that document sync exists
- that account-backed cloud storage is active
- that current local-only privacy wording is still valid once backend features ship

## What is done in mobile already

The Flutter repo already has:

- shared shell and donor-aligned workflow base
- local jobs and drafts
- local customization/defaults
- local signatures, photos/scans attachments, and export/share entry points
- Android package identity alignment and first real Samsung validation
- a first real backend account shell:
  - sign-in start and code completion
  - refresh-token-backed session restore
  - bearer-auth `/me` and entitlement hydration
  - membership display plus org access-code redemption
  - simple org-admin invite / resend / seat / remove actions for backend testing
  - backend-typed plan loading
  - signed-in organization creation for business checkout
  - first Google Play purchase shell that maps store purchases back into backend verification

## Path forward from the mobile side

### Immediate next mobile/backend handshake

1. validate the new shared sign-in/account shell against the live backend on-device
2. switch trial UX assumptions to the launch target of `6` backend-counted free jobs
3. keep local jobs/drafts working while backend account work lands
4. consume backend `GET /plans` in customer-facing pricing/paywall screens
5. validate real Android purchase callbacks on-device and confirm successful backend verification against the live dev backend
6. keep privacy/store wording aligned with the actual backend-backed release scope

### After the first real backend auth pass

1. harden session-conflict replace flow on-device
2. add entitlement-aware paywall/account state
3. move from operator-style admin controls toward cleaner business UX
4. keep purchase verification, privacy wording, and store disclosures in step with the real release path

### Deferred until later

1. cloud document sync
2. cross-device recovery for jobs/media
3. usage-metered Pro storage/API features

## Repo ownership reminder

- `material-guardian-mobile`
  mobile workflow, shared client, Apple handoff, privacy/store readiness wording for future mobile releases
- `app-platforms-backend`
  auth, orgs, seats, plans, entitlements, sessions, trials, purchase verification, and hosting direction
- `MaterialGuardian_Android`
  current shipped/reference behavior and current production privacy wording until the shared app replaces it
