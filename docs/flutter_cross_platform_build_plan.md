# Flutter Cross-Platform Build Plan

Date: 2026-04-01

This is the working build plan for Material Guardian and the default pattern to reuse for future Flutter/Dart app migrations.

## Goal

Build one real product in shared Dart where possible, while isolating only the parts that genuinely need Android-specific or Apple-specific behavior.

## Source-of-truth rule

- `material-guardian-mobile` is the source of truth for the mobile app plan, shared code, and platform handoff notes.
- `MaterialGuardian_Android` remains the behavior donor until Flutter reaches release parity.
- Apple-specific follow-up notes live under `ios/`.

## Default separation rule

If a feature can behave the same on Android and iPhone, it belongs in shared Dart.

If a feature depends on OS permissions, device hardware, filesystem rules, store SDKs, or native packaging/signing, it must be isolated behind a platform boundary.

## What belongs in shared Dart

- domain models
- validation rules
- workflow rules
- draft and persistence rules
- navigation and route definitions
- feature state and controllers
- shared screens and widgets
- report/export orchestration logic
- backend-facing app concepts like user, org, seat, session, trial, and entitlement
- normalized pricing/paywall presentation
- design tokens, theme, copy, and shared assets where practical

## What belongs in platform-specific work

### Android-specific

- Android manifest entries
- Android permission declarations
- Android storage/share plumbing when native behavior differs
- Play Billing bridge
- Play Store packaging and release config
- Android app icons and adaptive-icon specifics
- Android-only native fixes or plugins

### Apple-specific

- `Info.plist` usage strings
- iOS permission wording and prompts
- iPhone/iPad camera, share sheet, and file-export specifics
- Apple purchase/store bridge
- bundle identifiers, signing, provisioning, and App Store packaging
- Apple app icons, launch assets, and display metadata
- any iOS-only native fixes or plugins

## Required architecture split

### 1. Shared feature layer

Keep feature behavior here first.

- jobs
- job detail
- drafts
- customization
- receiving form
- saved-material edit flow
- export flow
- entitlement-aware UI

### 2. Shared platform-contract layer

Define the capability in Dart before binding it to Android or Apple.

Examples:

- camera service
- document scan service
- file export service
- share service
- billing service
- local storage path service

Each contract should describe what the app needs, not how a specific OS implements it.

### 3. Platform implementation layer

Implement the contracts per platform only where the OS differs.

- Flutter plugin wrappers in shared Dart when a package already handles both platforms cleanly
- native Android code under `android/` only when the package or OS requires it
- native Apple code under `ios/` only when the package or OS requires it

## Build order for Material Guardian

### Phase A. Shared product parity first

- port donor models completely enough to stop shell drift
- port receiving form workflow and validation
- port draft lifecycle
- port customization behavior
- port jobs/material CRUD

### Phase B. Shared export orchestration

- define the packet/export workflow in shared Dart
- define what files get produced and when
- define explicit `Share PDFs` and `Share ZIP` app behavior

### Phase C. Platform service boundaries

- define camera, scan, export-path, and share contracts
- keep the contract API stable before deep platform work

### Phase D. Android implementation first for release pressure

- wire Android platform services
- match current donor behavior
- validate on-device and prepare Play Store release shape

### Phase E. Apple implementation against the same contracts

- hand the Apple queue to the Mac-side agent
- implement iOS services against the same shared contracts
- resolve iOS-specific permission, share, and sandbox differences without changing shared workflow rules unless the product truly needs it

## Folder intent

- `lib/`
  shared app logic, shared UI, feature state, contracts, and orchestration
- `android/`
  Android runner plus Android-native glue only
- `ios/`
  Apple handoff notes, Apple queue, and iOS-native glue only
- `docs/`
  source-of-truth build plan, migration notes, and behavior references

## Decision test for every new feature

Ask these in order:

1. Is the product behavior the same on both platforms?
   If yes, keep it in shared Dart.

2. Is the difference only implementation, not workflow?
   If yes, keep the workflow in shared Dart and isolate the implementation behind a contract.

3. Is the difference truly product-visible on one platform?
   If yes, document the exception in `ios/` or Android notes and keep the exception narrow.

## Rules for plugins and native bridges

- Prefer packages that support both Android and iOS cleanly.
- Do not leak plugin-specific objects through the shared feature layer.
- Wrap plugin behavior behind app-owned interfaces when the feature is important to the product.
- If Android needs a workaround that iOS does not, keep that workaround in the Android implementation and do not contaminate shared models or feature logic.
- If iOS needs a sandbox/share workaround that Android does not, keep that workaround in the Apple implementation and record it in `ios/`.

## Definition of done for a cross-platform feature

A feature is not done just because it works on Android.

For each major feature:

- shared workflow is in Dart
- tests cover the shared behavior
- Android implementation is validated
- Apple-specific follow-up is either implemented or explicitly queued in `ios/`
- the repo docs state whether the feature is Android-only complete or truly cross-platform complete

## Handoff rule for the Mac-side Apple agent

The Apple agent should start with:

1. `README.md`
2. `AGENTS.md`
3. `docs/flutter_cross_platform_build_plan.md`
4. `docs/material_guardian_flutter_source_of_truth.md`
5. `ios/README.md`
6. `ios/apple-platform-todo-2026-04-01.md`

Then it should implement only the Apple-specific pieces needed to satisfy the shared contracts and leave the shared Dart workflow intact unless there is a documented product reason to change it.

## Reuse rule for future Flutter apps

Use this same structure unless there is a strong reason not to:

- shared product logic first
- app-owned Dart contracts second
- OS-specific implementations third
- platform notes kept in-repo so another machine/agent sees the same plan
