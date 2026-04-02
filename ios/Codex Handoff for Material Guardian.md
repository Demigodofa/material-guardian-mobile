# Codex Handoff for Material Guardian

Last updated: 2026-04-02

## Project location

- Repo root: `C:\Users\KevinPenfield\source\repos\Demigodofa\material-guardian-mobile`
- Remote: `https://github.com/Demigodofa/material-guardian-mobile.git`
- Branch: `main`
- Behavior donor repo: `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android`

## Current state

- This repo is the source of truth for the future shared Flutter client and Apple handoff notes.
- The shipping Android app still does not live in this repo; it remains the behavior donor and the original Android-only source this Flutter work was built from.
- The Flutter scaffold now exists in this repo, including generated Android and iOS projects.
- Shared Dart code now exists in `lib/` and currently covers jobs, job detail, drafts, customization defaults, and local persistence.
- The app is being built as one shared Flutter client for Android and Apple, but iOS-specific validation and platform fit are still unfinished.
- The current delivery stage is debugging/hardening the Flutter app against donor behavior and real Android device use, not greenfield scaffolding.
- Android app work is ahead of the older iOS notes and should be treated as the current product reference.
- Long-term client direction is now a shared Flutter app plus backend, not "separate full native iOS app by default."
- `Welders Helper` is the umbrella company/brand for the app suite, and `Material Guardian` is one product in that suite.
- The suite-level "Brought to you by" splash behavior is intended to carry forward to sibling apps such as `Flange Helper`; keep that umbrella splash rule documented rather than implicit.
- Active repo split is now:
  - `MaterialGuardian_Android` for the current shipping/reference app
  - `material-guardian-mobile` for the future shared Flutter client
  - `app-platforms-backend` for the shared backend
- The next Codex session should treat Android as the reference implementation while planning/building the Flutter + backend path; use `ios/` here for Apple-specific notes until a real cross-platform client structure exists.
- If a newer clone, branch, or Mac working copy already contains iOS files, preserve that work and extend it instead of replacing it with a fresh scaffold.
- The Android repo still keeps an older `ios/` copy for safety; treat this repo's `ios/` folder as canonical going forward.

## Cross-platform reality check

- Shared Flutter code is the correct direction for both Android and Apple.
- That does not mean the app is already optimized for iPhone.
- The shared product/data/navigation layer should be built once in Dart where possible.
- Android is the active debugging lane right now; Apple work should pick up from stable shared workflow and documented suite rules rather than from stale assumptions.
- Apple-specific build settings, permissions, camera/scanner behavior, file export behavior, app icons, launch assets, and signing must still be finished and validated on the Mac.
- Keep Apple-specific follow-up work tracked in `ios/apple-platform-todo-2026-04-01.md`.

## Read first

1. `AGENTS.md`
2. `C:\Users\KevinPenfield\.codex\skills\kevin-codex\SKILL.md`
3. `C:\Users\KevinPenfield\.codex\skills\kevin-codex\references\foundation.md`
4. `C:\Users\KevinPenfield\.codex\skills\kevin-codex\references\web-apps.md`
5. `README.md`
6. `docs/material_guardian_flutter_source_of_truth.md`
7. `docs/flutter_cross_platform_build_plan.md`
8. `app-platforms-backend/docs/material_guardian_monetization_source_of_truth.md`
9. `docs/mobile_architecture.md`
10. `docs/migration_plan.md`
11. `docs/android_behavior_reference.md`
12. `docs/android_migration_inventory.md`
13. `assets/reference/android-source/www/privacy-policy.html`
14. `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\docs\release_handoff.md`
15. `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\docs\play_release.md`
16. `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\docs\google_play_submission.md`
17. `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\docs\welders_helper_suite.md`
18. `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\docs\monetization_backend_handoff.md`
19. `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\docs\flutter_backend_direction_2026-03-31.md`
20. `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\docs\next_phase_product_plan_2026-03-31.md`
21. `ios/android-preferences-change-notes-2026-03-30.md`
22. `ios/apple-backend-coordination-2026-03-30.md`
23. `ios/apple-platform-todo-2026-04-01.md`

## Review-first workflow

- For this repo, treat rereads, fix-hunting, adjustment ideas, design decisions, live output checks, and "does it actually run" validation as part of a code-review pass first.
- Use regular Codex work for the implementation/editing phase after the review pass identifies the needed change.
- Keep the runtime checks real, but group them under the review umbrella when possible to reduce pure Codex token use.

## Where the important files are

### Android behavior donor

- App source: `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\java\com\asme\receiving\`
- UI screens: `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\java\com\asme\receiving\ui\`
- Local data / Room: `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\java\com\asme\receiving\data\local\`
- Export logic: `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\java\com\asme\receiving\data\export\`
- Resources: `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\res\`
- Bundled assets: `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\assets\`

### Shared mobile repo working area

- Apple handoff notes: `ios/`
- Migration notes: `docs/`
- Copied Android reference assets: `assets/reference/android-source/`
- Shared Dart code target: `lib/`
- Tests target: `test/`

### iOS work area

- Put Apple-specific code and docs under `ios/`
- Keep shared Dart/app logic in this repo and do not mix Android native build files or signing files into it
- If `ios/` already contains Swift/Xcode project files in another environment, treat them as authoritative in-progress work and avoid destructive rewrites
- If the product moves into a Flutter workspace, keep Apple-specific setup, signing, StoreKit notes, and platform exceptions clearly separated from shared Dart/app logic

## Apple-side specifics that still need Mac validation

- bundle identifier, signing team, provisioning, and build settings
- `Info.plist` usage descriptions once real camera/photo/scan plugins are selected
- iPhone-safe camera capture, scan flow, image orientation, and permission prompts
- iOS sandbox-safe local storage, PDF export, ZIP creation, and share-sheet behavior
- app icons, launch screen assets, and store-facing metadata

## Behavior the iOS version should match

- Offline-first local workflow
- Jobs list and job detail flow
- Receiving inspection report form
- Material list with create/edit flow
- Up to 4 photos per material
- Up to 8 scans per material
- Local export behavior centered on one job folder and one packet PDF per material
- Privacy-policy and store wording where still applicable

## Android behavior that changed after the first iOS note

- Landing screen now exposes a real `Customization` entry point.
- Customization/preferences currently drive:
  - whether ASME B16 receiving fields appear
  - whether surface-finish fields appear
  - which fixed surface-finish unit is shown on the receiving form
  - whether a company logo is embedded in exported reports
- The receiving form still keeps the `Imperial` / `Metric` material-level choice on-device.
- New-material form entry was hardened so starting a new receiving report should reset cleanly instead of restoring the last abandoned `__new__` draft.
- Photo previews were corrected to respect image orientation while exported photos already retained proper orientation.
- Export PDF layout was tightened repeatedly to keep the receiving report on one page and keep lower sections aligned.
- Android launch behavior was cleaned so the app should go straight into the intended splash flow instead of briefly showing the launcher icon first.
- The Flutter repo is now actively debugging shared splash/launch behavior and Downloads-backed export reopening on real Android hardware.
- Samsung donor-parity validation has now confirmed that the home screen no longer shows a global drafts button and that the job-detail materials list is back to a donor-style tap-to-edit summary row with a separate `Delete`, positioned safely above the Samsung navigation bar.
- Samsung donor-parity validation has now also confirmed the new in-app photo capture flow: `Add material photos -> Take Photo` stays inside the Flutter app, shows a `Material Photos` camera overlay, uses `Retake` / `Use Photo`, advances the in-overlay counter after accept, and returns to the form with the photo count updated.
- Samsung donor-parity validation has now also confirmed the camera-based scan flow: `Scan MTR/CoC PDFs -> Scan With Camera` stays inside the Flutter app, shows an `MTR/CoC Scans` overlay, uses `Retake` / `Use Scan`, advances the in-overlay counter after accept, and returns to the form with the scan count updated.
- The lower media controls on the receiving form were also moved clear of Samsung navigation chrome so `Scan MTR/CoC PDFs`, `Save Material`, and `Save Draft and Close` are reachable on-device.
- Samsung donor-parity validation has now also confirmed that the shared Flutter form no longer exposes the donor-inaccurate `Heat Number` field; the live upper form block shows `Material Description`, `PO #`, `Qty`, `Product`, `A/SA`, `Spec / Grade`, and `Fitting`.
- Samsung donor-parity validation has also confirmed the packet-report wording update with a pulled PDF artifact: the exported packet now contains `RECEIVING INSPECTION REPORT`, `Material Details`, `Dimensions`, `Inspection`, `Comments`, `Quality Control`, `PO#`, `Qty`, `Product`, `Grade/Type`, `Marking Actual`, `MTR/CoC Acceptable to Specification`, `Disposition`, and `QC Manager`, and no `Heat Number`.
- Samsung donor-parity validation now also confirms that the shared Flutter form exposes donor-style `Material approval` instead of inferring it on save, and that the `Quality Control -> Material approval -> QC Manager` order is restored on-device without the duplicate manager printed-name field.
- Samsung donor-parity validation also reconfirmed the lower media block after that QC fix: the live form still shows attached photo thumbnails, empty photo/scan slots, and reachable `Save Material` / `Save Draft and Close` controls above the Samsung nav bar.
- Samsung donor-parity validation also reconfirmed the latest in-app photo flow from the corrected media block: tapping `Add material photos` opens the in-app action sheet, `Take Photo` stays inside `com.asme.receiving.dev`, and the overlay still shows `Material Photos` with the running counter.
- Samsung snapshot validation has now also confirmed that creating a job on-device really persists: after entering `JOBTEST6` and pressing `Create`, the new job appeared in `files/material_guardian_snapshot.json`.
- Shared Flutter now also restores the donor field caps that protect receiving-report line placement: `Material Description` 40, `PO #` 20, `Vendor` 20, `Qty` 6, `Spec/Grade` 12, dimension fields 10, QC inspector/manager names 20, and `Actual Markings` back to 5 lines.
- Shared Flutter now also has widget-test coverage for donor back-out behavior: dirty receiving forms show `Exit receiving report?`, offer `Keep Editing` / `Leave` / `Delete Draft`, preserve the draft on leave, and remove it on delete.
- Shared Flutter now also restores donor QC-date parity: the receiving form has date pickers beside `QC Inspector` and `QC Manager`, drafts/materials persist those dates, and export packets now include `QC Inspector Date` / `QC Manager Date` plus dated signature blocks.
- Shared Flutter now also restores more donor packet structure: the export no longer prints the internal `Tag` row or generic `Field / Value` headers, blank surface-finish rows are omitted, material-detail order is back to donor order, and the signature area now has a donor-style `Signatures` heading.
- Shared Flutter now also matches the donor surface-finish form row more closely by rendering `Actual Surface Finish Reading` as the field label with the unit beside the field instead of inside the label.
- The next Android parity pass should now move beyond the old camera/media/job-create/QC-date/packet-structure uncertainty and focus on broader donor comparisons: receiving-report field order/details, plus any remaining back-out edge cases that only show up on-device or scan-preview mismatches.
- The next agreed product pass includes explicit draft access, explicit PDF-vs-ZIP sharing, and QC-name/signature defaults driven from customization.

## Important Android details to preserve when porting

- Draft safety was hardened recently; interrupted receiving-report sessions should not lose user work
- Local data is intentionally kept on-device; cloud sync/export is deferred
- Export/share behavior was adjusted to work better with real-world share targets like SharePoint
- Optional report/logo/customization behavior is now part of the product, not just an Android experiment
- The Android team is already thinking ahead to backend-driven auth, seat control, trials, and cross-platform entitlement handling; do not hard-code store-only account assumptions on iOS
- Release signing and Play setup exist for Android only and should not be copied into iOS signing
- Version nomenclature should stay aligned across platforms: use `major.minor.patch` with no `v` prefix for the user-facing app version, keep Android `versionCode` and iOS build number as increasing integers, and use operational release labels like `1.0.2 (3) - Export Fixes` or `1.0.2 (3) Internal - Export Fixes`

## Local-only files and folders

These help on Kevin's PC but should not drive iOS architecture:

- `release-signing.properties`
- `keystore/`
- `local.properties`
- `.gradle/`
- `.gradle-user-home/`
- `.android-user-home/`
- `.idea/`
- `.idx/`
- `.kotlin/`
- `.tmp/`

## Suggested starting point for the next Codex session

Ask Codex to:

`Open C:\Users\KevinPenfield\source\repos\Demigodofa\material-guardian-mobile and read ios/Codex Handoff for Material Guardian.md first. Use C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android as the behavior reference, read docs/material_guardian_flutter_source_of_truth.md, and continue the Flutter debugging/hardening path for Material Guardian without touching Android signing files. Keep the Welders Helper suite branding and shared "Brought to you by" splash behavior in mind for future sibling apps like Flange Helper. Start from the remaining Android donor-parity checks around receiving-report field/detail order, back-out edge cases, and any remaining scan/preview mismatches unless newer notes in the repo override that priority.`

Also tell Codex that if there is already iOS work in this clone, branch, or another newer Mac copy, it should preserve and extend that work instead of replacing it with a fresh scaffold. Have it also check `C:\Users\KevinPenfield\.codex\skills\kevin-codex\` on this PC to pick up Kevin-machine workflow context and see whether any durable guidance or legacy workflow notes should be updated as the iOS work progresses.
