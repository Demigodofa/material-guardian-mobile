# Sales Launch Flow - 2026-04-13

Current signed-out launch direction for Android:

- New signed-out users land on `SalesScreen`, not the jobs shell.
- Primary promise: `Try your first 6 free jobs now`.
- First-time flow stays simple:
  - `Start Free Trial`
  - `Log In`
  - `Individual`
  - `Business`
- If already signed in, the app should continue past the sales-first landing and use the normal app shell.

Product-truth constraints that the sales screen must not overstate:

- The free trial is `6 jobs` on the starting account.
- The free trial is not split per included business user.
- Public self-serve business offer is currently fixed at `5 report users`.
- Business flow is:
  - start with owner email
  - create company workspace
  - buy Business
  - invite teammates
  - assign report users
- Workspace name is backend-backed once created.
- Imported logo files and saved signatures are still device-local today and should not be described as cross-device backend-managed assets.

Copy direction:

- Prefer `material receiving` language over vague generic wording.
- Keep the first screen focused on actual field value:
  - receiving reports
  - MTR capture
  - packet export
- Avoid cluttering the first screen with deep billing mechanics or seat math.
- Keep business explanation visible but compressed.
- Use `5 report users included` in customer-facing copy instead of internal-only seat wording.
