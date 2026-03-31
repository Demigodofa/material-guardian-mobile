# Android Behavior Reference

Date: 2026-03-31

Use the current `MaterialGuardian_Android` app as the behavior reference while building the Flutter client.

## Behaviors that must be preserved

- offline-first local workflow
- blank `Add Material` entry
- explicit `Resume Draft` and `Delete Draft`
- both `Share PDFs` and `Share ZIP`
- customization-driven QC printed-name defaults
- optional saved QC inspector signature flow
- one-page report output expectations
- export/share behavior that works with real business targets like SharePoint

## Porting caution

- Do not silently reopen the latest new-material draft from the main create action.
- Do not collapse the PDF-vs-ZIP export choice into one ambiguous share action.
- Do not assume Android and iPhone file/share behavior are identical.

