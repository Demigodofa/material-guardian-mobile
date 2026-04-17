# Android Stress Sweep 2026-04-14

This pass focused on Android release hardening, export artifact review, emulator screenshot review, and code-level stress risks around draft persistence and trial/job limits.

## 2026-04-15 follow-up hardening

An additional release-quality pass on 2026-04-15 closed several higher-risk logic gaps after reviewer feedback:

- report-access gating now applies to receiving-report draft creation and completion, not only top-level `Create Job`
- transient store purchase updates now defer until auth and billing catalog state are ready instead of failing early during startup
- business purchase verification now surfaces the `no seat` outcome explicitly instead of implying the account is immediately ready to create reports
- signed-in non-admin business members no longer see a broken `Restore Purchases` affordance that depends on owner/admin billing context
- snapshot persistence is now atomic and backed by a recovery file, and corrupt primary snapshots now fall back to the backup instead of bricking startup state restoration
- internal repo docs were updated to stop describing the active Android release as local-only/offline-only

## Artifacts

- Desktop QA root:
  - `C:\Users\KevinPenfield\OneDrive NEMO\OneDrive - NEW ENGLAND MECHANICAL OVERLAY INC\Desktop\material_guardian_qa_20260414_141023`
- Desktop export probe bundle:
  - `C:\Users\KevinPenfield\OneDrive NEMO\OneDrive - NEW ENGLAND MECHANICAL OVERLAY INC\Desktop\material_guardian_export_probe\20260414T140632681437`
- Rendered packet pages:
  - `C:\Users\KevinPenfield\OneDrive NEMO\OneDrive - NEW ENGLAND MECHANICAL OVERLAY INC\Desktop\material_guardian_qa_20260414_141023\rendered_packets`
- Stress export root:
  - `C:\Users\KevinPenfield\AppData\Local\Temp\material_guardian_mobile_release_stress\exports\stress_bulk\20260414_142620_536822`
- Latest rerun stress export root from the 2026-04-17 validation pass:
  - `C:\Users\KevinPenfield\AppData\Local\Temp\material_guardian_mobile_release_stress\exports\stress_bulk\20260417_164722_937625`

## What was exercised

- `flutter analyze`
- `flutter test test/app_shell_test.dart test\release_stress_probe_test.dart`
- `flutter test test\manual_export_probe_test.dart`
- 15 receiving-report packet export stress run
- offline/local 6-job trial-limit fallback
- delete-and-recreate trial-limit regression
- phone/tablet emulator screenshot review for:
  - sales landing
  - auth card
  - jobs home
  - account
  - customization
  - B16 preference dialog
  - privacy policy
  - job detail
  - receiving-form top section

## Fixes landed in this pass

### 1. Draft persistence is now ordered instead of fire-and-forget

Problem:

- the receiving form autosaved on every controller change with no debounce and no ordering guarantees
- overlapping writes could persist older draft payloads after newer ones, which was a plausible fit for intermittent media-path loss

Fix:

- `lib/screens/material_form_screen.dart`
  - autosave now debounces
  - form saves queue in order instead of racing
- `lib/app/material_guardian_state.dart`
  - snapshot writes are now serialized so later state wins deterministically

### 2. Double-submit on `Save Material` is now blocked

Problem:

- the final material save path allowed repeated taps while `completeDraft()` was still running
- on a new draft that could append duplicate materials

Fix:

- `lib/screens/material_form_screen.dart`
  - submit path now guards against re-entry
  - footer actions disable while the material submit is running

### 3. Offline/local trial limit no longer reopens after deleting jobs

Problem:

- the fallback 6-job wall used current local job count only
- deleting a job reopened a slot in offline/no-entitlement mode

Fix:

- `lib/data/material_guardian_snapshot_store.dart`
  - snapshot now stores `localTrialJobsConsumed`
- `lib/app/material_guardian_state.dart`
  - fallback gating now uses lifetime local jobs consumed instead of current count

### 4. Regression coverage added

- `test/release_stress_probe_test.dart`
  - now proves the local fallback trial wall stays closed even after deleting a job

### 5. Scan packet pages now choose orientation from the rendered preview

Problem:

- scanned-document export pages were always forced onto landscape letter
- portrait PDF previews looked undersized and left excessive empty page area

Fix:

- `lib/services/job_export_service.dart`
  - scan packet pages now choose portrait vs landscape from the preview image dimensions
  - portrait scan previews now use the sheet much better in the exported packet

### 6. Draft deletion now cleans job-owned media

Problem:

- deleting a discarded draft removed the draft record but left job-media files on disk
- that allowed orphaned photos/scans to accumulate even when the user intentionally threw the draft away

Fix:

- `lib/app/material_guardian_state.dart`
  - draft deletion now removes job-owned media paths before the snapshot is persisted
- `test/app_shell_test.dart`
  - regression now proves draft deletion removes job media while preserving shared customization assets

### 7. Unrenderable photos no longer disappear silently from packet exports

Problem:

- if a stored image could not be normalized for export, the photo attachment page silently skipped it
- that made the packet look complete even when an original media file was present only in `source_media`

Fix:

- `lib/services/job_export_service.dart`
  - photo pages now keep the slot and render a clear `Preview unavailable` placeholder tile instead of dropping the attachment without warning

### 8. Billing and auth hardening landed after the main sweep

Problem:

- the shared backend `/plans` catalog could bleed non-Material-Guardian plans into the mobile client
- Google purchase verification did not send `googlePackageName`
- the mobile client acknowledged paid Play purchases even when backend verification failed
- Play-facing copy said `Android` instead of `Google Play`
- hosted auth emails were still arriving as `Your Welders Helper sign-in code`

Fix:

- `lib/app/material_guardian_state.dart`
  - filters `/plans` down to Material Guardian entries before querying store IDs
  - sends `googlePackageName: com.asme.receiving`
  - no longer acknowledges paid Play purchases when backend verification fails or the purchase cannot be matched back to a signed-in Material Guardian plan
  - now sends `authEmailBrand: material_guardian` on `/auth/start`
- `lib/screens/sales_screen.dart`
  - Play-facing copy now says `Google Play`
- `apps/api`
  - hosted `app-platforms-backend-dev` was redeployed successfully on revision `app-platforms-backend-dev-00042-8cw`
  - fresh hosted auth email proof now shows `Your Material Guardian sign-in code`

## Visual findings

What looked good in the reviewed captures:

- sales landing hierarchy and CTA prominence on phone portrait
- account summary readability on phone portrait
- customization/B16 preferences layout on phone portrait
- jobs home structure on tablet landscape
- privacy policy card layout on tablet landscape
- job detail structure on tablet landscape
- rendered packet PDFs:
  - customized packet first page
  - customized photo page
  - 4-up stress photo page

Specific packet observations:

- 4-up photo export is working and renders occupied slots correctly
- customized packet first page keeps signatures, names, dates, and branding in a printable shape
- portrait PDF scan previews now render on portrait packet pages instead of being centered on landscape sheets
- photo attachment export now fails louder when an image cannot render, instead of silently omitting that slot
- photo pages still leave unused vertical whitespace when a packet has only 1-2 photos, but the media itself is present and readable

## Emulator/harness limits hit during this pass

- Android emulators repeatedly surfaced lock-screen / notification-shade UI over the app during long scripted runs
- adb text injection for email entry was still brittle in the sales/auth lane, so emulator auth screenshots are good for layout review but not a trustworthy proof of typed-email behavior
- Samsung handset ADB text injection was still brittle enough to corrupt email entry and even jump out of the app during retries, so the final phone purchase/restore pass should use human typing instead of pure ADB text automation
- because of those harness issues, the static signed-in screen set was more reliable than fully scripted auth-to-form end-to-end emulation

These were environment/automation nuisances, not app crashes.

## Donor Android comparison

Read-only review of `MaterialGuardian_Android` confirmed:

- donor app stores photo paths as app-owned job media
- donor app treats scan source and preview image as a first-class pair
- donor export uses true 4-up photo pages and imports scan PDFs directly
- donor app does not contain the current backend-backed trial/billing behavior

That donor comparison is useful mainly as a media/export reference, not as a billing reference.

## Remaining real risks

- scan thumbnails/export pages still depend on preview-sidecar generation for imported PDFs; when preview generation fails, the source PDF is preserved but the packet can still fall back to a generic preview-missing page
- a final human phone pass is still worth doing for camera capture on a real handset, because emulator media tooling is not a strong substitute for the actual device camera path
- emulator screenshot automation should start by explicitly dismissing lock/shade state before capture; `tool/emulator_qa_driver.py` is a useful base, but it is still not a fully bulletproof unattended driver

## Current status

- core focused tests: green
- analyze: green
- full `flutter test`: green on 2026-04-17
- export stress run: green
- desktop probe bundle: generated
- rendered packet review: generated
- key concurrency and offline-trial bugs found in review: fixed

## Real-phone buyer-path follow-up

- Signed in on handset `RFCW40P51JK` with `granitemfgllc@gmail.com`
- Post-login paid state hydrated correctly:
  - `Access status: Paid`
  - `Current plan: Business 5 Users Yearly`
  - `Workspace: Granite MFG LLC`
- `Plans` screen shows the paid subscription card and a visible `Restore Purchases` control
- On 2026-04-17, after the production-named backend cutover and the restore-flow patch, the Samsung restore result became explicit:
  - `No purchases were returned to re-link on this device. Your backend access is still active.`
- Prod access logs during that restore attempt showed:
  - fresh `GET /me`
  - fresh `GET /entitlements/current`
  - fresh `GET /organizations/:id`
  - no fresh `POST /purchases/google/verify`
- That narrows the remaining billing blocker further:
  - the app is signed in correctly
  - the backend is healthy
  - the restore UI is no longer silent
  - but Google Play did not hand the app a relinkable purchase on that handset/install context
- The next billing proof is therefore not another generic backend pass. It is a Google Play ownership/context pass:
  - confirm the phone's Play account owns the subscription
  - confirm the subscription is active in Play
  - if needed, install from the Play internal-testing track and rerun restore there
