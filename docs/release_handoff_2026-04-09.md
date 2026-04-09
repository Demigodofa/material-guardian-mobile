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
- `flutter test test/app_shell_test.dart` passed with the new export regression
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

Likely next work:
- finish store-policy/account-deletion closure
- harden Apple verification
- capture final store screenshots and release polish
```
