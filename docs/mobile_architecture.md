# Mobile Architecture

Date: 2026-03-31

## Goal

Build one shared Flutter client for Android and iPhone while preserving the proven Material Guardian workflow from the current Android-native app.

## Core app layers

### Shared app layer

- routes and navigation
- feature state
- validation rules
- form logic
- entitlement-aware UI decisions
- pricing/paywall presentation including yearly savings messaging

### Platform integration layer

- camera
- document scanning
- file export and share
- purchase SDK integration
- platform-specific storage and permission handling

### Backend integration layer

- auth/session APIs
- org and seat state
- plan catalog lookup
- entitlement lookup
- trial status
- later sync/recovery

## Architectural rules

- Shared Dart code should own the product workflow where possible.
- Platform-specific code should be isolated to the places where Android and iOS actually differ.
- The current Android app is the reference for workflow and export behavior until the Flutter app is complete.
- Pricing screens should consume backend plan definitions and show yearly savings clearly instead of hard-coding plan meaning separately on each platform.
