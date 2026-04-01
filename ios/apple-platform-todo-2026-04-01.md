# Apple Platform TODO

Last updated: 2026-04-01

## What is already true

- `material-guardian-mobile` is the source of truth for Material Guardian mobile work.
- The Flutter scaffold exists in this repo, including the generated iOS project under `ios/`.
- Shared Dart code is now in progress under `lib/` and is intended to serve both Android and Apple.
- The current behavior donor is still `C:\Users\KevinPenfield\source\repos\Demigodofa\MaterialGuardian_Android`.
- Shared Flutter now already includes jobs, drafts, customization, signature capture/import, media attachment, privacy-policy copy, and packet PDF plus ZIP export flows.
- Android release identity is already aligned to the donor package, while debug Android builds use a `.dev` suffix so release identity and device-testing identity stay separate.
- Android phone validation has already started on real hardware, and the first live safe-area issue was fixed in shared Flutter layout code rather than Android-only UI code.

## What is not true yet

- The app is not yet functionally at full parity with the Android donor.
- The app is not yet validated on an iPhone or in the iOS simulator.
- Platform-specific integrations for camera, scans, exports, sharing, icons, and store metadata are not finalized.
- The generated iOS identifiers and display settings are still scaffold defaults and must not be treated as release-ready.

## Apple-specific work queue

1. Replace scaffold app identity.
   - Set the real bundle identifier.
   - Set Apple team signing in Xcode.
   - Align display name, version, and build number with the release strategy.

2. Lock down permissions.
   - Add only the `Info.plist` usage descriptions required by the actual selected plugins.
   - Validate wording for camera, photo-library, and document/file-import access.
   - Confirm whether any extra export/open-in-place permissions or document types are needed for the chosen iOS file flow.

3. Validate plugin choices on iOS.
   - Camera/photo capture
   - Multi-image handling
   - Document scanning
   - PDF generation
   - ZIP packaging
   - Share sheet / file export
   - Local storage paths

4. Check iOS sandbox behavior against product expectations.
   - Exported files cannot assume Android-style public folders.
   - Share flows must be tested against Mail, Files, AirDrop, and enterprise targets if used.
   - Temporary vs persistent storage needs deliberate handling.

5. Replace scaffold visuals.
   - App icons
   - Launch assets / splash behavior
   - Any Apple-facing display strings or bundle metadata

6. Perform Apple QA once the shared features exist.
   - keyboard and form flow
   - portrait layout on iPhone
   - signature drawing feel and saved-signature reuse
   - image orientation
   - file export and reopen behavior
   - permissions first-run experience

## Current code assumptions to revisit on the Mac

- Shared Flutter state is local-first and currently persists snapshots on-device.
- Shared Flutter now proves jobs, drafts, customization defaults, blank material creation, signature capture, material media attachment, privacy-policy display, and packet export structure.
- iOS should preserve the same product behavior as Android where practical, but platform-specific file and share semantics will need Apple-side adjustments.

## Release caution

- Do not ship with the scaffold bundle id or default icons.
- Do not add signing secrets or provisioning profiles to git.
- If a newer Mac clone already has iOS-specific work, preserve it and merge carefully instead of overwriting it from Windows.
