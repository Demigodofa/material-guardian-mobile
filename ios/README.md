# Material Guardian iOS

This folder is the canonical Apple handoff and future iOS-specific landing area for Material Guardian inside the shared mobile repo.

The original Android-repo `ios/` folder is being preserved as a legacy reference copy for safety, but new Apple-side notes should be centered here.

Start with:

- `docs/flutter_cross_platform_build_plan.md`
- `ios/Codex Handoff for Material Guardian.md`

Review/validation preference:

- Use a code-review pass first when rereading code, searching for fixes, exploring adjustment ideas, making design decisions, checking live outputs, or confirming the iOS-side process/build actually runs.
- Use regular Codex work for the implementation/editing phase after that review pass.

Current state:

- This repo is the source of truth for the future Flutter mobile client.
- The Flutter scaffold now exists in this repo, including generated `ios/Runner` and shared Dart code under `lib/`.
- The shared app shell already covers jobs, job detail, drafts, customization defaults, and local persistence.
- The app is being built as one shared Flutter client for both Android and Apple, but it is not yet honestly iOS-validated or Apple-optimized.
- iOS-specific product work is still at the handoff/setup stage and must be finished on the Mac with Xcode.
- The shipping behavior reference still lives in `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android`.
- The Android reference implementation has moved materially since the first iOS handoff note:
  - customization/preferences now control optional B16 usage, optional surface-finish fields, and company-logo inclusion on exported reports
  - the receiving form still keeps per-material `Imperial` / `Metric`
  - export/report layout and launch splash behavior were tightened through recent Android validation on a real phone
- If another clone, branch, or Mac working copy already has iOS files, preserve and extend that work rather than replacing it with a new scaffold.
- This Windows clone now contains the generated Flutter iOS project plus handoff docs; if a newer Mac working copy has unpushed Apple files, reconcile there carefully so older files do not overwrite newer work.
- The future iOS app should use this repo's existing product references first:
  - `README.md`
  - `AGENTS.md`
  - `C:\Users\KevinPenfield\.codex\skills\kevin-codex\`
  - `docs/material_guardian_flutter_source_of_truth.md`
  - `docs/mobile_architecture.md`
  - `docs/migration_plan.md`
  - `docs/android_behavior_reference.md`
  - `docs/android_migration_inventory.md`
  - copied Android reference assets under `assets/reference/android-source/`
  - Android donor docs in `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\docs\`
  - Android UI/assets under `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android\app\`, `assets/`, and `www/`
  - iOS coordination notes already in this folder:
    - `ios/android-preferences-change-notes-2026-03-30.md`
    - `ios/apple-backend-coordination-2026-03-30.md`
    - `ios/apple-platform-todo-2026-04-01.md`

Recommended iOS handoff inputs:

- screen flow and wording from the Android app
- export behavior and folder/package rules
- local-first data model and validation rules
- the newer Android customization/preferences behavior, optional receiving sections, logo workflow, and launch/splash expectations
- the next-phase draft/export/customization plan in `docs/next_phase_product_plan_2026-03-31.md`
- privacy policy and store-listing language where still applicable
- icons, colors, and suite branding references

Apple-specific queue to finish on the Mac:

- replace scaffold bundle identifiers, team signing, and build-number/version wiring with the real app identity
- confirm camera, photo-library, document-scan, file-export, and share-sheet plugins work correctly on iPhone
- add any required `Info.plist` privacy usage strings once the actual plugins are chosen
- validate export folder behavior, PDF generation, ZIP creation, and share targets against iOS sandbox rules
- replace scaffold app icons, launch assets, and any Apple-specific display strings
- run simulator and real-device QA for orientation, keyboard behavior, file pickers, and photo/document permissions

Keep Apple-specific signing material, provisioning profiles, and secrets out of git just as with the Android signing files.
