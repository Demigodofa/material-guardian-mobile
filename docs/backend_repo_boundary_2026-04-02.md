# Backend Repo Boundary

Date: 2026-04-02

This note exists so future agents do not let backend ownership drift back into the mobile repo.

## Canonical backend repo

- `app-platforms-backend` is the authoritative repo for:
  - auth/session flow
  - plans, subscriptions, and entitlements
  - organizations, seats, and admin/member management
  - backend-side monetization and future metered usage/overage logic
  - Cloud Run hosting/runtime setup

## What stays in this mobile repo

- shared Flutter client behavior
- app-owned local jobs, drafts, export flow, and media handling
- backend consumption through one client boundary instead of scattered URLs

## Current client boundary

- shared backend client: `lib/services/backend_api_service.dart`
- dev backend base URL source: `MG_BACKEND_BASE_URL`
- current dev default:
  - `https://app-platforms-backend-dev-293518443128.us-east4.run.app`

## Rule for future work

- if backend contract, billing, admin, seat, entitlement, auth, or hosting logic changes, update `app-platforms-backend` first
- only keep mobile-facing integration notes here when they directly affect the Flutter client
- do not duplicate backend source-of-truth docs here when the backend repo already owns them
