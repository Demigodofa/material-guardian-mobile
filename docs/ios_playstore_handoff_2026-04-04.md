# iOS and Play Store Handoff 2026-04-04

This note records product decisions and temporary bypasses that affect both the Apple and Android/store tracks.

## Product polish decisions now in the shared app

- The `Plans` screen should not overwhelm a paid user after purchase.
- When an account already has a paid plan:
  - show the active subscription first
  - show seat usage and open seats for business workspaces when available
  - keep the primary way back into work obvious
  - hide full plan options until the user explicitly taps `Upgrade or Change Plan`
- `Restore App Store Purchases` should be framed as a device-recovery action, not normal day-to-day seat or ownership management.
- Privacy policy wording should describe shipped behavior only. Do not expose internal roadmap/shop-talk such as speculative cloud-workspace wording to customers.
- Signed-in jobs entry should use `Plans and Billing` rather than a generic `Plans` label so paid users understand where account changes live.
- Account/workspace UI should use customer-facing language:
  - `Company Workspaces`
  - `Create Workspace`
  - `Join Workspace from Invite`
  - `Workspace ID` and `Invite Code`
  - `Send Invite`
- Raw backend plan codes should not be shown to customers. Shared screens now humanize them into labels such as `Business 5 Monthly`.

## Seat and owner/admin intent

- Owners and admins manage the company workspace.
- Seats are only for people who need to create receiving reports.
- Owners/admins may still take a seat themselves when they need to create reports.
- Inviting someone to the workspace and assigning a report seat are separate actions; keep that distinction obvious in both stores.
- The account/seat/invite flow should stay aligned between Android and iOS because it lives in shared Flutter code unless a platform-specific requirement forces a divergence.

## Current Apple validation status

- iOS simulator build is working on this Mac.
- The app has been relaunched on:
  - `iPhone 17`
  - `iPhone 17 Pro Max`
  - `iPad Pro 13-inch (M5)`
- Additional shared test coverage now exists for:
  - phone and tablet material-form stability
  - dropdown usability on the material form
  - customization-screen stability with saved logo/signature assets
  - export bundle generation with logo and signatures present

## Temporary machine-local bypass

- This Mac still requires local Flutter-tool patches so simulator builds can skip failing codesign steps on simulator artifacts/native assets.
- Those patches are local to Kevin's Flutter SDK and are not committed in this repo.
- Treat that as a machine issue, not shared app behavior.

## Backend/email testing note

- Gmail access for `granitemfgllc@gmail.com` is live in Codex.
- Forwarding from `kevin@granitemfg.com` to Gmail is blocked by Gmail rejecting the forwarded external message.
- Keep moving with local/dev backend auth flows where possible instead of blocking mobile work on that mail-routing issue.

## Guidance for the Play Store / Android agent

- Preserve the shared Flutter plans/account/privacy behavior unless there is a store-specific compliance reason to diverge.
- If Android wording is changed for store review or purchase clarity, mirror the intent back into the shared Flutter screens so Apple and Android do not drift.
- Keep exported report packaging and local file expectations aligned across platforms, but respect sandbox differences in the platform-specific open/share entry points.
