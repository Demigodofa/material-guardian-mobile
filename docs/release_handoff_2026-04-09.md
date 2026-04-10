# Material Guardian Mobile Handoff 2026-04-09

Read this before continuing Android/iPhone release work from the Flutter repo.

## Current repo role

`material-guardian-mobile` is the mobile implementation source of truth.

This pass focused on:

- export hardening
- release-readiness notes
- desktop artifact generation
- real Samsung phone validation
- aligning the app with the live backend/admin/auth behavior

## What changed in this pass

### 1. Export now uses bundled fonts

PDF export no longer relies on Helvetica-only behavior.

Changed:

- `lib/services/job_export_service.dart`
- `pubspec.yaml`
- `assets/fonts/roboto-regular.ttf`
- `assets/fonts/roboto-bold.ttf`

Important result:

- Unicode-heavy packet text now exports cleanly through the bundled Roboto theme path

### 2. Export regression coverage was expanded

Changed:

- `test/app_shell_test.dart`
- `test/manual_export_probe_test.dart`
- `tool/run_manual_export_probe.ps1`

Added/proven:

- Unicode export coverage
- expanded export probe that copies the full export tree instead of only packet/zip summaries
- `customized` and `plain` export variants for critique

### 3. Release note and store-policy reminders were updated

Changed:

- `docs/play_release.md`
- `docs/store_policy_release_checklist_2026-04-09.md`
- `README.md`

Important truths:

- do not ship a customer Play build against the dev backend URL by accident
- account deletion is still a real store-policy gap
- Apple purchase verification is still behind Google Play verification
- release prep should include a fresh read of current official Apple and Google policy/review guidance

### 4. Empty-job export bug was found and fixed

Real phone validation found that exporting a job with zero saved materials could still mark the job as `Exported`, even though the export folder only contained `export_info.txt`.

Fixed in:

- `lib/app/material_guardian_state.dart`
- `lib/screens/job_detail_screen.dart`
- `test/app_shell_test.dart`

New behavior:

- empty/zero-packet export results do not stamp the job as exported
- the job screen now tells the operator to save at least one receiving report before exporting

## Phone validation completed

Device used:

- Samsung `SM-S911U`
- adb id `RFCW40P51JK`

Artifacts captured here:

- `artifacts/device_stress_2026-04-09/`

What was exercised on-device:

- signed-out plans/auth entry
- code-entry layout
- signed-in shell
- account screen
- customization screen
- create job dialog
- job detail screen
- receiving form top/middle/lower/footer
- draft save/resume behavior
- export confirmation dialog
- Android-side export output inspection

Important phone finding:

- the main real bug found in this pass was the misleading empty export state, and that is now fixed in code

What looked good on-device:

- create job layout
- job detail layout
- receiving form structure
- lower save-area safe spacing
- export confirmation dialog

What was not fully closed after reinstall:

- the final fresh release-build sign-in round after reinstall was slowed by brittle ADB tap/input automation, not by a reproduced app exception
- earlier in this same broader session, the auth flow itself was already proven live on-device in the debug build, and backend/Gmail delivery was independently re-proven

## Export artifacts ready for critique

Desktop export probe output:

- `C:\Users\KevinPenfield\OneDrive NEMO\OneDrive - NEW ENGLAND MECHANICAL OVERLAY INC\Desktop\material_guardian_export_probe\20260409T155145338536`

Phone-created export evidence pulled into repo artifacts:

- `artifacts/device_stress_2026-04-09/pulled_exports/mg24031/export_info.txt`

That pulled phone export shows the real pre-fix empty-export case:

- `Materials: 0`
- `Packet PDFs: 0`

## Backend/auth alignment confirmed

- live backend auth works for `granitemfgllc@gmail.com`
- live backend auth also works for Gmail plus aliases such as `granitemfgllc+alias1@gmail.com`
- this means one Gmail inbox can simulate many distinct test users without collapsing them into one account identity

## Validation completed locally

- focused `flutter analyze` passed on the edited files
- `flutter test test/app_shell_test.dart` passed with the current sales/account wording and export regressions
- `flutter test test/manual_export_probe_test.dart` passed
- release bundle build had already succeeded earlier in this pass:
  - `build/app/outputs/bundle/release/app-release.aab`

## Remaining mobile work

1. Re-run a clean release-build phone flow after reinstall if you want a fully fresh signed-out-to-export pass with less ADB automation noise.
2. Finish the App Store / Play store policy checklist items before submission:
   - account deletion
   - Apple purchase verification hardening
   - final metadata/screenshot/compliance read-through
3. Capture final polished store screenshots/thumbnails from the current Flutter app.
4. Keep using Gmail plus aliases for multi-account testing.

## 2026-04-10 mobile polish landed

The following release-facing cleanup was added after the main 2026-04-09 handoff:

- explicit `primaryContainer` and `secondaryContainer` theme colors now exist so plan/status cards do not depend on fuzzy Material defaults
- the sales screen copy is tighter and more explicit about:
  - trial value
  - solo versus business naming
  - yearly/business value framing
  - FAQ-level seat invite and phone-recovery guidance
- account/org surfaces now explain that:
  - business plans attach to a company workspace
  - solo plans do not need that workspace step
  - invited users should install Material Guardian from Google Play if needed before redeeming their company access code
- signed-in account and plan surfaces now use friendly labels instead of raw internal plan codes
- the signed-in plans status card now shows the current workspace name when the account is attached to a business org
- the plans screen no longer shows customer-facing `Backend: ... | Store: ...` pricing text; non-release fallback pricing language stays dev-only
- the redundant `Customization` button was removed from job detail so customization stays anchored to the main landing flow
- imported PDF scans on Android now request a generated preview sidecar, which should improve MTR thumbnail visibility instead of falling back to a generic PDF tile as often
- imported PDF scans on Android now generate preview sidecars for every detected PDF page, not just page 1, so multi-page MTR/CoC packets can flow into the packet PDF instead of silently collapsing to one page
- packet export now adds an explicit fallback page when a PDF scan preview is unavailable, instead of silently dropping that scan from the packet while only copying the source PDF into `source_media`
- packet export now separates `Description` and `Comments` instead of compressing them into one dense report cell
- packet export now gives the logo more room, enlarges signature boxes, and labels photo/scanned-document attachments more clearly
- photo attachment pages now render only occupied tiles instead of reserving empty bordered boxes for missing slots in every 2x2 grid

## 2026-04-10 validation notes

- `flutter analyze` passed after the 2026-04-10 edits
- `flutter test test/manual_export_probe_test.dart` now passes with a regression that proves two sequential exports do not reuse the same export root path
- `flutter test test/app_shell_test.dart --plain-name "exporting a scanned PDF also carries its preview image into export media"` passed after the 2026-04-10 export changes
- `tool/run_manual_export_probe.ps1` passed and wrote a fresh desktop probe bundle here:
  - `C:\Users\KevinPenfield\OneDrive NEMO\OneDrive - NEW ENGLAND MECHANICAL OVERLAY INC\Desktop\material_guardian_export_probe\20260410T150256294242`
- a rebuilt debug APK was installed on the attached Android phone
- UI dumps confirmed the updated sales/onboarding copy is the version now running on-device
- a seeded signed-in debug build (`--dart-define=MG_DEBUG_SEEDED_SIGNED_IN=true`) now provides a reliable on-device way to inspect signed-in account/plan UI without depending on brittle phone text-entry automation
- the seeded signed-in state now mirrors the Granite MFG business-owner shape instead of a solo-plan stub, so QA screenshots match the real business billing lane more closely
- that seeded signed-in phone pass showed the account/plan text rendering as readable after the theme/container-color fix
- the danger-zone delete button needed one more fix after device validation because the global outlined-button theme left it with a white fill and effectively invisible text; that styling is now patched
- a later device pass confirmed the updated signed-in plans header text on phone now reads:
  - `Access status: Paid`
  - `Current plan: Business 5 Seats Yearly`
  - `Workspace: Granite MFG LLC`
- a later device pass confirmed the updated account summary card on phone now reads:
  - `Access status: Paid`
  - `Current plan: Business 5 Seats Yearly`
- a later device pass also confirmed the lower Account stack on phone now renders:
  - the danger-zone delete card with the stronger owner/subscription warning
  - the Organizations section with the cleaned ASCII membership subtitle format
  - the organization summary card with the friendly plan label
- live backend account deletion is now fixed server-side and paid workspace owners are blocked correctly, but fully automated phone sign-in remained noisy because ADB text-entry on this Samsung/device path did not reliably enter email addresses with `@`
- Norton 360 repeatedly flagged fresh debug installs of `com.asme.receiving.dev` as suspicious and threw an uninstall modal over the app; treat that as a phone-environment nuisance during local QA, not as an app/backend logic failure
- if both `com.asme.receiving` and `com.asme.receiving.dev` are installed during device validation, confirm which package actually owns the foreground activity before trusting screenshots or UI dumps
- `flutter install --debug` uninstalls and reinstalls `com.asme.receiving.dev` on this setup, which wipes local app data. Do not assume the saved debug auth session survives a debug reinstall.
- after any back-to-home path on the phone, do not use blind launcher taps. Relaunch with `adb shell monkey -p com.asme.receiving.dev -c android.intent.category.LAUNCHER 1`, then confirm the package in a fresh UI dump before any further taps.
- export roots now include millisecond + microsecond precision.
  - the older `YYYYMMDD_HHMMSS` folder naming could collide when two exports happened inside the same second
  - `lib/services/job_export_service.dart` now produces unique export folders for rapid repeat exports, and the manual export probe test locks that behavior in
- Android-side Kotlin compilation could not be fully re-proved in this pass because this PC's Gradle toolchain is pointing at `C:\Program Files\Eclipse Adoptium\jre-17.0.18.8-hotspot`, which is a JRE without a Java compiler.
  - the export bridge changes themselves are in `android/app/src/main/kotlin/com/asme/receiving/MainActivity.kt`
  - `flutter analyze` and the export-focused Flutter tests are green
  - the remaining Kotlin compile blocker is a machine Java-toolchain setup issue, not a confirmed source-code compile error in the app repo

## 2026-04-10 later release-polish pass

Additional release-facing cleanup landed after the first 2026-04-10 polish notes:

- the plans screen now removes one whole explanatory card and replaces it with a tighter `Pick the right lane` card so the page reaches the actual paid choices faster
- the FAQ block is now a single expandable `Questions Before You Buy` card instead of a permanently open wall of text
- plans copy now explicitly says subscriptions auto-renew until canceled in the active store, and that cancellation normally keeps access through the current paid period
- the free-trial sign-in card now makes the solo-versus-business naming split more direct: personal name now, company name only if Business is chosen later
- the account summary card now shows the active workspace name directly, which makes the business identity path more obvious for paid owners
- the lower account/workspace area now uses `Company Workspaces` wording instead of `Organizations`
- when a user already has a workspace, `Add Another Workspace` is now collapsed by default instead of always showing a second full company form
- the lower workspace card now stays focused on the current workspace and invite/member management instead of competing with a second always-open setup form
- the store-policy checklist now explicitly tracks:
  - public account deletion URL / declaration work
  - Data Safety and privacy alignment
  - email delivery/provider wording
  - the current Play Console verifier-permission blocker
- the in-app privacy screen now explicitly mentions:
  - backend email delivery/provider usage
  - store-backed entitlement verification
  - account deletion expectations and business-retention caveats

## 2026-04-10 later device validation

The later Android debug pass re-proved the updated account/plans structure on the attached Samsung using the seeded signed-in lane:

- the plans screen rendered:
  - the signed-in Granite MFG status block
  - the workspace name
  - the new `Pick the right lane` card
- the account summary rendered:
  - paid status
  - friendly plan label
  - direct workspace name line
- the lower account screen rendered:
  - `Company Workspaces`
  - the accepted Granite MFG membership summary
  - the new collapsed `Add Another Workspace` control instead of an always-open second company form

Backend truth that still matters to mobile release work:

- the live Google backend revision is deployed and RTDN/auth smoke is good
- Play Console service-account linkage is now working for `mg-play-verifier@asme-receiving.iam.gserviceaccount.com`
- the old `permissionDenied` blocker is gone; the next Google billing proof should use a real purchase token
- durable operator note: Play Console `API access` for the service account was the working fix, not only the human-style `Users and permissions` invite flow
- the Android release bundle now also builds cleanly with the live backend URL:
  - `build/app/outputs/bundle/release/app-release.aab`
- this Samsung currently only has `com.asme.receiving.dev`, so a real Google billing proof still requires the Play-installed `com.asme.receiving` internal-test app
- the public privacy-policy repo was updated and pushed at `Demigodofa/privacy-policy`
  - privacy policy URL target: `https://demigodofa.github.io/privacy-policy/`
  - account deletion URL target: `https://demigodofa.github.io/privacy-policy/delete-account.html`
  - GitHub Pages propagation still needed to catch up before those URLs are treated as live-ready

## 2026-04-10 safer live-auth device lane

The most reliable way to prove the real signed-in Android account surfaces on this Samsung is now a dev-only bootstrap session, not ADB typing through the login form.

- `lib/main.dart` accepts:
  - `MG_DEBUG_BACKEND_ACCESS_TOKEN`
  - `MG_DEBUG_BACKEND_REFRESH_TOKEN`
- `MaterialGuardianAppState.create()` will save that provided session and hydrate directly from `/me` plus `/entitlements/current` before the app UI settles
- this stays debug-only and does not affect the production release path
- the resulting session persists correctly in `flutter.backend_auth_session_v1` once the app itself saves it

What this proved on-device:

- the app cold-launched directly into the signed-in shell with a real live Granite MFG owner session
- the real paid business account screen rendered correctly
- the plan text remained readable
- the red danger-zone delete card rendered correctly with readable button text
- the organization section showed the real Granite MFG workspace

Use this route when the goal is:

- proving real account UI against the live backend
- verifying signed-in account/organization surfaces
- avoiding brittle Samsung keyboard/input automation

## 2026-04-10 release sign-in cleanup

The attached Samsung is now back on a clean local release install instead of a mixed debug/play state.

- the phone now has only `com.asme.receiving`
- current locally installed release version is:
  - `versionName=1.0.7`
  - `versionCode=8`
- the local signed release APK was rebuilt and reinstalled after the final sign-in cleanup pass
- release builds no longer auto-fill the backend `demoCode` into the sign-in code box
- release builds also no longer render `Dev code: ...` helper text on the plans/account verification cards
- those demo-code conveniences now stay gated to non-release builds only in:
  - `lib/screens/account_screen.dart`
  - `lib/screens/sales_screen.dart`
- after reinstall and `pm clear`, the phone was rechecked in a fresh UI dump and the release first-run screen showed:
  - empty `Email`
  - empty `Personal Name (optional)`
  - no prefilled code
- this matters because an earlier release-style pass looked like the app was "helpfully" logging in from a shown code; that was really the release client still surfacing backend `demoCode`
- if a future release QA pass needs true customer-like auth behavior, keep using the release package and do not trust sign-in behavior from a debug/dev build unless the goal is explicitly dev-side auth inspection

## Exact next-agent brief

Use this:

```text
Start in C:\Users\KevinPenfield\source\repos\Demigodofa\material-guardian-mobile.

Read:
- docs/release_handoff_2026-04-09.md
- docs/store_policy_release_checklist_2026-04-09.md
- docs/play_release.md
- README.md

Truths:
- export uses bundled Roboto fonts now
- empty jobs must not mark themselves exported anymore
- phone screenshots and pulled export artifacts are under artifacts/device_stress_2026-04-09
- Gmail plus-addresses work for distinct test accounts
- signed-in UI verification on-device is easiest through `MG_DEBUG_SEEDED_SIGNED_IN=true` when the goal is visual inspection rather than live auth proving
- real signed-in UI verification on-device is easiest through `MG_DEBUG_BACKEND_ACCESS_TOKEN` plus `MG_DEBUG_BACKEND_REFRESH_TOKEN` when the goal is proving the live backend account state without depending on Samsung text-entry

Likely next work:
- finish store-policy/account-deletion closure
- harden Apple verification
- capture final store screenshots and release polish
- keep doing broader screen-by-screen UX/copy cleanup now that plans/account/export are in better shape
```
