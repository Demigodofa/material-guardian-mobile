# Apple Platform TODO

Last updated: 2026-04-05

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
- Platform-specific integrations for camera, scans, exports, sharing, icons, and store metadata are not finalized.
- Signed device install and App Store export are still blocked by missing Apple codesigning identities on this Mac.
- The Apple account visible in Xcode on 2026-04-05 is still only `Personal Team` for `granitemfgllc@gmail.com`.
- Apple Developer Program enrollment was started on 2026-04-05, but approval is still pending. Until Apple approves that enrollment and Xcode shows a real team instead of `Personal Team`, App Store Connect setup, TestFlight, production signing, and upload work are blocked.

## Apple-specific work queue

1. Replace scaffold app identity.
   - Confirm the now-updated bundle identifier `com.asme.materialguardian.ios`.
   - Confirm the now-updated display name `Material Guardian`.
   - Set Apple team signing in Xcode once an Apple identity is available on this Mac.
   - Align version and build number with the release strategy.

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

- Do not ship without Apple signing configured on this Mac.
- Do not add signing secrets or provisioning profiles to git.
- If a newer Mac clone already has iOS-specific work, preserve it and merge carefully instead of overwriting it from Windows.

## Local validation update 2026-04-05

- `flutter build ios --simulator` is green on this Mac after the iOS identity and launch-asset cleanup.
- Simulator launch was rechecked on `iPhone 17` with the app installed as `com.asme.materialguardian.ios`.
- The launch screen now shows:
  - native launch: `Brought to you by:`
  - Flutter splash: Welders Helper logo
  - then handoff to the Material Guardian landing screen
- Direct unsigned archive validation succeeded with:
  - `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -destination 'generic/platform=iOS' -archivePath build/ios/archive/Runner.xcarchive CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' archive`
- `flutter build ipa --no-codesign` is still flaky on this machine; prefer the direct `xcodebuild archive` command above for unsigned archive validation until that tool-path issue is understood.

## Auth and store-testing state 2026-04-05

- There are two separate emails in active use and the next agent should preserve that split:
  - backend/Postmark/admin GUI auth email: `kevin@granitemfg.com`
  - store purchase testing email: `granitemfgllc@gmail.com`
- Those emails are intentionally not the same.
- Current live backend reality:
  - `POST /auth/start` succeeds for `kevin@granitemfg.com`
  - `POST /auth/start` still returns `500` for outside domains like `granitemfgllc@gmail.com`
- This is not an iOS-only bug. It reproduces against the live backend with direct `curl`.
- Root cause is still Postmark external-recipient restriction while approval is pending.
- Until Postmark approval completes, use `kevin@granitemfg.com` for login-code delivery and use `granitemfgllc@gmail.com` only for store purchase testing.

## Backend patch already prepared locally but not deployed

- Local backend repo path:
  - `/Users/kevinpenfield/Documents/Playground/app-platforms-backend`
- Local patch now exists to keep dev auth usable when email delivery fails for outside domains:
  - `apps/api/src/postgres-store.ts`
  - `apps/api/src/store-factory.ts`
  - `apps/api/src/postgres-store.test.ts`
- Behavior of that patch:
  - in dev Cloud Run mode, if `sendLoginCode` throws during `startAuth`, the backend logs a warning and returns success with a `demoCode` fallback instead of a hard `500`
  - outside that dev fallback mode, delivery failure still throws
- Local validation for that patch passed:
  - `npm test`
  - `npm run check`
- The patch is not live yet because this Mac currently has no active `gcloud` login, so Cloud Run redeploy could not be performed from here.

## Immediate next steps once external approvals move

1. When Postmark approval lands, retest `/auth/start` with `granitemfgllc@gmail.com`.
2. If Gmail delivery still fails after Postmark approval, inspect Postmark sender/domain status and Cloud Run env vars before blaming the app.
3. When Apple Developer approval lands, reopen Xcode Accounts and confirm `Personal Team` has been replaced by the real team.
4. Once the real Apple team appears, set Runner signing to that team, validate archive/signing, create the App Store Connect app, and continue TestFlight/store setup.
