# Android Migration Inventory

Date: 2026-04-01

This inventory tracks what was copied from `MaterialGuardian_Android` into `material-guardian-mobile` for reference and what still needs to be ported deliberately into Flutter.

## Canonical repo roles

- `material-guardian-mobile`
  source of truth for shared mobile planning, Apple handoff notes, and the future Flutter app
- `MaterialGuardian_Android`
  donor repo for current product behavior, Android-native implementation details, and original reference assets
- `app-platforms-backend`
  source of truth for backend contract, plans, entitlements, seats, sessions, and trials

## Copied into this repo already

### Apple handoff notes

- `ios/README.md`
- `ios/Codex Handoff for Material Guardian.md`
- `ios/android-preferences-change-notes-2026-03-30.md`
- `ios/apple-backend-coordination-2026-03-30.md`

### Android reference assets

- `assets/reference/android-source/icons/Material_Guardian_512.png`
- `assets/reference/android-source/icons/Material_Guardian_192.png`
- `assets/reference/android-source/icons/Material_Guardian_180.png`
- `assets/reference/android-source/icons/Material_Guardian32x32.png`
- `assets/reference/android-source/icons/Receiving Inspection Report.pdf`
- `assets/reference/android-source/google-play/screenshots/material-guardian-google-play-01.png`
- `assets/reference/android-source/google-play/screenshots/material-guardian-google-play-02.png`
- `assets/reference/android-source/google-play/screenshots/material-guardian-google-play-03.png`
- `assets/reference/android-source/google-play/screenshots/material-guardian-google-play-04.png`
- `assets/reference/android-source/google-play/screenshots/material-guardian-google-play-05.png`
- `assets/reference/android-source/www/privacy-policy.html`

## Behavior that must be ported

- offline-first local workflow
- jobs list and job detail flow
- blank `Add Material`
- explicit `Resume Draft` and `Delete Draft`
- both `Share PDFs` and `Share ZIP`
- customization-driven QC printed-name defaults
- optional saved QC inspector signature flow
- one-page report output expectations
- export/share behavior that works with business targets like SharePoint
- up to 4 photos per material
- up to 8 scans per material

Primary references:

- `docs/android_behavior_reference.md`
- `docs/material_guardian_flutter_source_of_truth.md`
- `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\docs\release_handoff.md`
- `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\docs\next_phase_product_plan_2026-03-31.md`

## Source areas to study during the port

### Android native UI and workflow

- `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\java\com\asme\receiving\ui\`
- `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\java\com\asme\receiving\navigation\`

### Local data and draft behavior

- `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\java\com\asme\receiving\data\local\`
- `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\java\com\asme\receiving\data\`

### Export and PDF logic

- `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\java\com\asme\receiving\data\export\`

### Branding and product copy

- `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\src\main\res\`
- `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\assets\`
- `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\www\`

## Reuse directly vs. port deliberately

Reuse directly:

- PNG icon files
- screenshot images
- privacy-policy HTML wording
- report template/reference PDF
- product wording and plan wording where still accurate

Port deliberately:

- Compose screen structure
- Room entities and repository code
- CameraX and ML Kit integrations
- Android share/export intent handling
- Android storage paths and permissions
- Gradle, manifest, and signing configuration

## First Flutter implementation targets

1. scaffold the Flutter app once Flutter is installed on at least one active development machine
2. create shared Dart domain models for job, material, customization, draft, entitlement, and plan state
3. build shell navigation for sign-in, jobs, job detail, and receiving form
4. keep Apple- and Android-specific integrations isolated from shared Dart workflow code

## Implemented in Flutter so far

- generated shared Flutter repo scaffold with Android and iOS targets
- canonical Apple handoff area under `ios/`
- copied Android reference assets under `assets/reference/android-source/`
- initial shared app shell for jobs, job detail, drafts, customization, and receiving form
- local persistence for jobs, drafts, and customization so the shell survives relaunches
- create job flow in Flutter instead of depending on seeded demo data
- donor-aligned receiving form fields for vendor, PO number, product type, specification/grade, fitting fields, dimensions, disposition, markings, comments, and QC printed names
- richer saved-material summaries in job detail so Flutter materials reflect more of the donor data instead of only tag/description
- saved-material edit flow through shared draft-backed Flutter state so existing materials can be reopened and updated without duplicate records
- donor inspection-state controls in Flutter for visual inspection and marking/MTR yes-no-NA decisions, with those values persisted through draft/edit/save flows
- local Flutter media services for photos, scans, signatures, and customization assets
- packet PDF export plus ZIP bundle generation and share actions in shared Flutter
- cross-platform inspector and manager signature capture in Flutter instead of import-only placeholders
- privacy-policy screen ported into the Flutter app shell from the donor wording
- job edit flow and saved-material delete flow in shared Flutter job detail
- Android package identity aligned to the donor release package, with debug builds intentionally split to a `.dev` suffix for coexistence on test phones
- successful local Android artifact builds from this repo: debug APK and release AAB
- first Samsung phone validation completed for install/launch/home-shell rendering, with the initial bottom navigation overlap fixed through shared safe-area padding rather than a one-off device hack
