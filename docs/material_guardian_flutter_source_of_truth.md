# Material Guardian Flutter Source Of Truth

Date: 2026-03-31

This is the current Flutter/mobile source of truth for the shared Material Guardian client.

If another repo has older Flutter migration notes, this file wins.

## Active repo ownership

- `material-guardian-mobile`
  authoritative repo for Flutter/mobile architecture, migration, shared-client notes, Apple handoff docs, and copied mobile reference assets
- `app-platforms-backend`
  authoritative repo for monetization, plans, subscriptions, entitlements, sessions, and backend contract notes
- `MaterialGuardian_Android`
  current behavior reference for the shipping Android app until Flutter replaces it

## Canonical handoff locations

- Apple/iOS coordination notes should now live under `ios/` in this repo.
- Apple-specific follow-up for the current Flutter scaffold should be tracked in `ios/apple-platform-todo-2026-04-01.md`.
- The default shared-vs-platform build strategy should be tracked in `docs/flutter_cross_platform_build_plan.md`.
- Android donor behavior and implementation references still live in `MaterialGuardian_Android`.
- Copied Android reference assets now live under `assets/reference/android-source/` in this repo so Flutter/iOS work can proceed without hunting across repos.

## Product direction

Material Guardian is moving toward:

- one shared Flutter client for Android and iPhone
- backend-owned auth, plans, subscriptions, seats, trials, sessions, and entitlements
- deliberate behavior parity with the current Android app instead of a casual redesign

Current reality:

- the Flutter scaffold and first shared shell now exist in this repo
- the app was seeded from the Android-only `MaterialGuardian_Android` repo and that repo remains the donor reference while Flutter reaches parity
- the backend repo now has a runnable scaffold, normalized plan/auth/session/trial endpoints, and a first Postgres migration foundation
- the shared Flutter client now also has a first real backend account shell: sign-in code flow, persisted session restore, `/me` and entitlement hydration, membership visibility, org access-code redemption, and a simple org-admin control surface
- the next backend-connected customer path is now explicit and partly wired: `6` backend-counted free jobs, then Play purchase on Android, then backend verification and refreshed entitlement/account state
- the shared Flutter account area now has a first billing shell: typed backend plan loading, org creation before business checkout, purchase restore, and shared store-purchase handling that can forward verified purchases to the backend
- the shared Flutter billing shell now also exposes Play catalog diagnostics in-app, so internal-test builds can report missing Play product IDs or billing query errors directly instead of only disabling buy buttons
- the agreed launch UX direction is now:
  - signed-out users land on a dedicated sales/trial entry screen, not the jobs landing
  - persisted signed-in users go straight to the normal jobs landing instead of seeing the sales surface every launch
  - if app data/session storage is cleared, the user must complete the email-code sign-in flow again because the backend session is no longer cached on-device
  - sales/paywall and account/admin should be separate surfaces
  - the sales/paywall screen should explain plan value plainly, not just show prices:
    - individual = one full workspace for one shop
    - business = company branding/report defaults plus managed seats
    - yearly plans should call out the annual savings as roughly two free months
  - customization is the shared settings surface, with solo users getting the same logo/report-setting powers as business admins except for seats
  - admin role and seat assignment are separate:
    - business admins can manage seats/settings without occupying a production seat
    - an admin can also occupy a seat when they need receiving-report creation access
  - seated non-admin users keep their own printed-name/signature customization but should not see the account/admin entry point
- shared Dart workflow should stay cross-platform by default
- the receiving form now carries a meaningful donor-aligned field block rather than only a placeholder shell
- saved-material editing now goes back through the same shared form and draft lifecycle rather than using a separate platform-specific edit path
- donor inspection decision state is now part of shared Flutter behavior instead of remaining Android-only
- shared Flutter now owns local media attachment, reusable/default signature capture, privacy-policy display, and packet PDF plus ZIP export/share entry points
- job editing and material deletion now exist in the shared Flutter job-detail flow
- Android release identity is aligned to `com.asme.receiving`, with debug builds split to `com.asme.receiving.dev` so device testing does not have to overwrite the shipped app
- this repo has already produced a Windows-built debug APK and release AAB, so Android compile plumbing is no longer hypothetical
- first real Android phone validation has now happened on a Samsung S911U; install, launch, and home-screen rendering are proven, and the first device-found safe-area bug has already been fixed in shared Flutter layout code
- donor-parity debugging on the Samsung has now also tightened the job-detail page: the global home-screen drafts button is gone, the saved-material row is back to a donor-style tap-to-edit summary plus `Delete`, and the summary/delete controls now sit above Samsung navigation chrome instead of under it
- donor-parity photo capture has now been brought into shared Flutter: Samsung validation proved that `Add material photos -> Take Photo` stays inside `com.asme.receiving.dev`, shows an in-app `Material Photos` overlay, uses `Retake` / `Use Photo`, loops back to the next capture count, and returns to the form with the thumbnail count updated
- donor-parity camera-based scan entry is now also proven on the Samsung: `Scan MTR/CoC PDFs -> Scan With Camera` stays inside `com.asme.receiving.dev`, shows an in-app `MTR/CoC Scans` overlay, uses `Retake` / `Use Scan`, loops back to the next scan count after accept, and returns to the form with the scan count updated
- the receiving-form bottom safe area was tightened again so `Scan MTR/CoC PDFs`, `Save Material`, and `Save Draft and Close` sit above Samsung navigation chrome instead of hiding in the bottom inset
- donor-parity wording cleanup removed the stray `Heat Number` field from the shared Flutter form, and Samsung validation now shows the upper form block as `Material Description`, `PO #`, `Qty`, `Product`, `A/SA`, `Spec / Grade`, and `Fitting` with no `Heat Number`
- donor-parity export wording is now also proven against a real Samsung-generated packet PDF: the pulled artifact contains `RECEIVING INSPECTION REPORT`, `Material Details`, `Dimensions`, `Inspection`, `Comments`, `Quality Control`, `PO#`, `Qty`, `Product`, `Grade/Type`, `Marking Actual`, `MTR/CoC Acceptable to Specification`, `Disposition`, and `QC Manager`, and does not contain `Heat Number`
- donor-parity quality-control layout is now tighter in shared Flutter: Samsung validation shows the live form using `Quality Control`, an explicit `Material approval` toggle (`Approved` / `Rejected`), then `QC Manager` and manager-signature actions instead of silently deriving approval and duplicating the manager printed-name field
- the lower receiving-form media block is now revalidated on the Samsung after the QC cleanup: `Add material photos (2/4)`, real attached photo thumbnails, empty photo slots, `Scan MTR/CoC PDFs (0/8)`, empty scan slots, `Save Material`, and `Save Draft and Close` all remain reachable above Samsung navigation chrome
- the latest Samsung build still keeps donor-style in-app photo capture after the QC/media changes: tapping `Add material photos` opens the in-app action sheet, `Take Photo` stays inside `com.asme.receiving.dev`, and the live overlay shows `Material Photos` with the running counter (`3 / 4` in the current validation)
- Samsung snapshot validation has now confirmed that create-job persistence is real on-device: after entering `JOBTEST6` and pressing `Create`, the job appeared in `files/material_guardian_snapshot.json`, so the remaining Android parity work should not treat job creation as a current blocker
- donor field caps are now restored in shared Flutter for report alignment: `Material Description` 40, `PO #` 20, `Vendor` 20, `Qty` 6, `Spec/Grade` 12, dimension fields 10, and QC inspector/manager names 20; `Actual Markings` is back to 5 lines like the donor form
- donor back-out behavior is now covered in Flutter widget tests as a contract: a dirty receiving form shows `Exit receiving report?`, offers `Keep Editing`, `Leave`, and `Delete Draft`, keeps the draft on leave, and removes it on delete
- donor QC dates are now carried through shared Flutter draft/state/export again: the receiving form shows date pickers beside `QC Inspector` and `QC Manager`, saved materials retain those dates, and packet export now includes `QC Inspector Date` / `QC Manager Date` plus dated signature blocks instead of dropping that donor information
- packet export parity is now tighter again: the Flutter packet no longer prints the donor-inaccurate internal `Tag` row or generic `Field / Value` headers, it omits blank surface-finish rows instead of printing placeholder dashes, it restores donor material-detail order (`Material Description`, `PO#`, `Vendor`, `Qty`, `Product`, `Specification`, `Grade/Type`, `Fitting`), and it now includes the donor-style `Signatures` heading
- the shared Flutter form also now matches the donor surface-finish row structure more closely: `Actual Surface Finish Reading` is its own field again and the unit is rendered beside it instead of being embedded in the label text
- the current project stage is debugging/hardening, not first-pass scaffolding; active attention is on real-device Android behavior and preserving a clean path for later iOS validation
- iOS-specific fit and validation still need to be completed on the Mac through the Apple handoff queue
- privacy/store wording must now be tracked as part of migration because the current shipped Android privacy language is intentionally local-only and will become inaccurate once backend account features are released

## Suite identity

- `Welders Helper` is the umbrella company/brand for this app suite.
- `Material Guardian` is one app in that suite.
- The suite uses a shared umbrella-brand "Brought to you by" splash behavior that should transfer to sibling apps such as `Flange Helper`.
- Product-specific screens can vary, but suite-level splash treatment, colors, layout rhythm, and shell cues should stay homogeneous unless a repo note says otherwise.

## Current reference behavior to preserve

- offline-first local workflow
- blank `Add Material`
- explicit `Resume Draft` and `Delete Draft`
- editable jobs and deletable saved materials
- both `Share PDFs` and `Share ZIP`
- customization-driven QC printed-name defaults
- optional saved QC inspector signature flow
- in-form captured signatures for inspector and manager
- one-page report expectations
- export/share behavior that works with real business targets like SharePoint

## Migration order

### Phase 1

- keep the Android app stable as the behavior reference
- define backend contract first
- install Flutter tooling on the active development machines
- scaffold the shared Flutter app shell in this repo

### Phase 2

- prove sign-in, jobs list, and job detail
- define state-management and service pattern
- build the paywall/plan-selection structure with monthly versus yearly pricing and savings display
- keep local jobs, drafts, and customization persistent while backend work is still incomplete
- split launch into a signed-out sales/trial path versus a signed-in jobs landing path
- move returning-user sign-in to the sales entry flow instead of mixing it into account/admin
- separate account/admin from the sales/paywall screen
- make the sales/paywall screen describe actual plan value, seat behavior, admin behavior, and annual savings before treating it as release-ready
- gate account visibility by role so only solo users and business admins see it
- keep customization visible to every seated user, but restrict org-level report settings to solo/admin paths

### Phase 3

- port receiving form shell
- port draft behavior
- port export/share entry points
- port customization defaults and saved signature flow

### Phase 4

- port photos and document scanning
- port PDF export and ZIP/PDF share flows
- wire backend-aware entitlement state and backend-driven plan catalog
- keep the new shared account/admin shell working against the live backend while preserving local jobs/drafts
- update privacy/store wording in step with actual backend/account features instead of after the fact

### Phase 5

- debug and harden real Android Flutter behavior against the donor app
- validate live Google Play purchase callbacks on-device and confirm the backend verification handoff works against the Cloud Run dev service
- use the next Play internal-test upload to read the exact in-app Play catalog diagnostics and resolve why Google is still not returning subscription `ProductDetails`
- keep using `MaterialGuardian_Android` as the reference for page flow, wording, back-out behavior, media layout, and field order until the Flutter screens stop producing donor-comparison misses
- the old photo-camera bounce, camera-based scan entry, top-form `Heat Number` mismatch, core packet-report wording mismatch, quality-control approval mismatch, missing QC dates, job-creation persistence doubt, missing donor field caps, and several packet-structure mismatches are fixed; next device checks should focus on remaining page-by-page field/detail comparisons plus any scan-preview or other Samsung-only edge cases that still differ from the donor app
- finalize suite-consistent splash/launch treatment for reuse by sibling apps
- keep Apple follow-up notes aligned so iOS validation can start from a stable shared workflow instead of from Android-only assumptions

## Architectural rules

- Shared Dart code should own workflow where possible.
- Platform-specific code should be isolated to camera, scanning, sharing, billing, storage, and other real device/store differences.
- Do not hard-code Apple-only or Google-only purchase assumptions into shared app logic.
- Pricing screens should consume normalized backend plan definitions.
- Business purchase UX should require or create an organization before checkout instead of trying to infer one after the store purchase succeeds.
