# Android Release Master Checklist 2026-04-14

This is the active control sheet for the Android release program. It tracks the 25 workstreams, recommended pass counts, current status, owners, and proof artifacts.

Status values:

- `not-started`
- `in-progress`
- `blocked`
- `needs-rerun`
- `verified`

Owner values:

- `lead`
- `reviewer`
- `artifact`
- `backend`
- `device`
- `policy`

## Program Summary

| # | Task | Passes | Agents | Owner | Status | Notes / proof |
| --- | --- | ---: | ---: | --- | --- | --- |
| 1 | Landing and first-run sales flow | 3 | 3 | lead | in-progress | Release phone sales screen verified. See phone screenshot artifacts. |
| 2 | Auth and session lifecycle | 3 | 2 | backend | verified | Session refresh/sign-out tests are passing, transient refresh failures no longer wipe a valid saved session, and the Samsung was re-signed into `granitemfgllc@gmail.com` against the production-named backend on 2026-04-17. |
| 3 | Trial enforcement and paywall behavior | 4 | 3 | lead | in-progress | Backend and fallback 6-job wall tests passing. Needs another real-device human pass. |
| 4 | Jobs home and job creation flow | 3 | 2 | device | in-progress | Phone/tablet seeded captures exist. |
| 5 | Job detail flow | 3 | 2 | device | in-progress | Phone/tablet seeded captures exist. |
| 6 | Receiving form structure and usability | 5 | 4 | device | in-progress | Multiple passes completed; continue human-use review on phone. |
| 7 | Draft persistence and autosave safety | 4 | 3 | reviewer | verified | Debounced/serialized saves landed, snapshot writes are now atomic with backup fallback, and the targeted snapshot recovery tests are green. |
| 8 | Photo capture and photo persistence | 5 | 4 | reviewer | in-progress | Better than before, but keep pressure on real-device camera paths. |
| 9 | Scan capture and scan persistence | 5 | 4 | reviewer | in-progress | Partial-failure save handling landed and targeted regression reruns are green. |
| 10 | Media import compatibility | 4 | 3 | reviewer | in-progress | Unrenderable photo exports now keep a placeholder tile instead of silently disappearing. |
| 11 | Signature capture and signoff behavior | 4 | 3 | device | in-progress | Signature capture/layout fixed; keep validating export and blank-manager behavior. |
| 12 | Customization and admin preferences | 3 | 2 | device | in-progress | Phone captures and tests exist. |
| 13 | Account and business workspace flow | 4 | 3 | backend | in-progress | Admin/non-admin tests green; business members now keep account self-service access while billing restore stays gated to owner/admin paths. Live invite/business lane still needs manual walkthrough. |
| 14 | PDF packet generation | 5 | 4 | artifact | in-progress | Photo grids and scan orientation improved; continue export inspection. |
| 15 | Export stress and artifact review | 4 | 4 | artifact | in-progress | 15-report stress/export pass complete; rerendered packet artifacts available. |
| 16 | Delete and cleanup behavior | 3 | 2 | reviewer | verified | Draft deletion now cleans job-owned media and keeps shared customization assets. |
| 17 | Device matrix visual QA | 4 | 5 | device | in-progress | Phone + emulators partly covered; continue matrix cleanup. |
| 18 | Emulator automation and screenshot harness | 2 | 2 | device | in-progress | Driver exists; still vulnerable to Samsung/system UI interruptions. |
| 19 | Backend contract verification for mobile | 3 | 3 | backend | in-progress | App-side contract tests green; live endpoint pass in progress. |
| 20 | Google Play billing path | 4 | 3 | backend | blocked | Paid tester account and backend entitlement state were proven on the real phone, and the restore flow now surfaces an explicit result instead of idling. On 2026-04-17 the Samsung restore result was `No purchases were returned to re-link on this device. Your backend access is still active.` Prod logs showed no `POST /purchases/google/verify`, so the remaining blocker is now Google Play purchase ownership/install context on the device, not silent mobile/backend failure. |
| 21 | Privacy policy and Play compliance text | 3 | 2 | policy | in-progress | In-app delete-account access is now available to every signed-in user. Public policy is aligned, and the stale internal local-only docs were updated to reflect the backend-backed Android release truth. |
| 22 | Release artifact verification | 3 | 2 | lead | verified | Final-source release APK + AAB were rebuilt against `app-platforms-backend-prod`, the APK was reinstalled to the Samsung on 2026-04-17, and the live phone re-entered the signed-in Granite MFG paid state from that build. |
| 23 | Code review and regression sweep | 3 | 3 | reviewer | in-progress | Multiple review passes completed; continue until medium-risk issues are closed. |
| 24 | Final manual ship pass on the real phone | 2 | 2 | device | in-progress | Continuing. Current phone has latest release APK installed. |
| 25 | Release readiness signoff | 1 | 1 | lead | not-started | Do only after billing, handset path, and HEIC/media confidence are acceptable. |

## Current Proof

- QA root:
  - `C:\Users\KevinPenfield\OneDrive NEMO\OneDrive - NEW ENGLAND MECHANICAL OVERLAY INC\Desktop\material_guardian_qa_20260414_141023`
- Real phone screenshots:
  - `C:\Users\KevinPenfield\OneDrive NEMO\OneDrive - NEW ENGLAND MECHANICAL OVERLAY INC\Desktop\material_guardian_qa_20260414_141023\screens_phone`
- Export probe:
  - `C:\Users\KevinPenfield\OneDrive NEMO\OneDrive - NEW ENGLAND MECHANICAL OVERLAY INC\Desktop\material_guardian_export_probe\20260414T164800172440`
- Real phone release screenshots:
  - `C:\Users\KevinPenfield\OneDrive NEMO\OneDrive - NEW ENGLAND MECHANICAL OVERLAY INC\Desktop\material_guardian_qa_20260414_141023\screens_phone\RFCW40P51JK_release_sales_home_portrait.png`
  - `C:\Users\KevinPenfield\OneDrive NEMO\OneDrive - NEW ENGLAND MECHANICAL OVERLAY INC\Desktop\material_guardian_qa_20260414_141023\screens_phone\RFCW40P51JK_release_sales_home_landscape.png`
  - `C:\Users\KevinPenfield\OneDrive NEMO\OneDrive - NEW ENGLAND MECHANICAL OVERLAY INC\Desktop\material_guardian_qa_20260414_141023\screens_phone\RFCW40P51JK_release_sales_auth_portrait.png`
- Latest stress export root:
  - `C:\Users\KevinPenfield\AppData\Local\Temp\material_guardian_mobile_release_stress\exports\stress_bulk\20260414_165106_768596`
- Latest final-source release artifacts:
  - `build\app\outputs\flutter-apk\app-release.apk`
  - `build\app\outputs\bundle\release\app-release.aab`
- Supporting note:
  - `docs/android_stress_sweep_2026-04-14.md`
- Backend live auth-email proof:
  - fresh hosted `/auth/start` on `2026-04-14` delivered `Your Material Guardian sign-in code` to `granitemfgllc@gmail.com`
- Latest release artifact:
  - `build\app\outputs\flutter-apk\app-release.apk`

## Active Open Risks

1. Google Play billing still needs its final ownership/context proof on the real handset. The live restore attempt on 2026-04-17 now returns an explicit `No purchases were returned to re-link on this device` result and still does not reach `POST /purchases/google/verify` on prod.
2. The exact next check is in Google Play itself: confirm the Samsung Play account is the subscription owner and that Material Guardian is active under `Payments & subscriptions`.
3. If the subscription is active in Play, the strongest final proof should use the Play internal-testing install path before customer rollout.
4. The final human phone pass should still walk the real capture/export flow end to end after the latest media and snapshot-safety fixes.
5. Emulator/tablet screenshot automation is still weaker than the real-phone lane and should not be treated as sole proof for deep screens.

## Next Sequence

1. In Google Play on the Samsung, confirm the signed-in Play account actually owns the Material Guardian subscription and that the subscription is active.
2. If needed, install the app from the Play internal-testing track and rerun `Restore Purchases`.
3. Confirm prod receives `POST /purchases/google/verify` during that final billing proof.
4. Run the final human capture/export walkthrough on the phone.
5. Close any remaining media compatibility/export edge cases, especially HEIC/HEIF and scan reruns.
6. Re-score every line item and only then issue release signoff.
