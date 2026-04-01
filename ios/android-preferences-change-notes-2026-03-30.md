# Android Preferences Change Notes

Date: 2026-03-30

These notes are for the in-progress iOS build so feature parity stays aligned with the Android app.

## New customization screen

- Android now has a landing-page `Customization` entry point.
- The screen currently owns app-level preferences that affect receiving entry and PDF export behavior.

## Current customization scope

- Optional `Receive ASME B16 parts` toggle
  - When off, new receiving entries hide the B16 fitting and B16 dimensions controls.
  - Existing materials with B16 data should still show/edit that data cleanly.
- Optional `Surface finish required` toggle
  - When on, the receiving form shows:
    - `Surface Finish` dropdown
    - `Actual Surface Finish Reading` numeric field
    - fixed unit label beside the reading
  - The unit is chosen once in customization, not on the live receiving form.
- Report logo upload
  - Android accepts PNG/JPEG, copies and normalizes the image into app-private storage, and uses that logo on exported receiving PDFs.

## Data behavior to match on iOS

- Keep `Imperial` / `Metric` as live per-material toggles on the receiving form.
- Surface-finish unit is a customization default, but the resolved unit should still be stored on each saved material/report record.
- Existing/older materials must remain editable and export accurately even if customization settings change later.

## PDF/export expectations

- Export should omit disabled/unused B16 and surface-finish sections cleanly instead of leaving blank placeholder rows.
- The report logo should appear in the receiving report header when configured.

## Follow-up customization/product direction

- Android is expected to add default printed-name fields for:
  - `QC Inspector`
  - `QC Manager`
- Android is also expected to add an optional saved default QC inspector signature that can be applied quickly from the receiving form.
- Export/share should keep both explicit choices:
  - `Share PDFs`
  - `Share ZIP`
- Draft behavior is expected to become:
  - `Add Material` always opens blank
  - unsaved work is still autosaved
  - drafts are reopened through an explicit draft entry point, not by reusing the main create action
