# Migration Plan

Date: 2026-03-31

## Phase 1

- keep `MaterialGuardian_Android` stable as the behavior reference
- define the backend contract in `app-platforms-backend`
- install Flutter tooling in the active development environments

## Phase 2

- scaffold the Flutter app shell
- prove sign-in, jobs list, and job detail navigation
- establish the state-management and service pattern
- establish plan-selection/paywall structure that can show monthly versus yearly pricing and yearly savings

## Phase 3

- port receiving form shell
- port draft behavior
- port export/share entry points
- port customization defaults and saved signature behavior

## Phase 4

- port photos and document scanning
- port PDF export and ZIP/PDF share flows
- wire backend-aware entitlement state
- wire backend-driven plan catalog and store-product mapping

## Phase 5

- retire Android-native code only after behavior parity and release confidence exist
