# Store Policy Release Checklist

Last reviewed: April 9, 2026

This checklist is the durable release gate for Material Guardian before any App Store or Google Play submission.

## Official pages reviewed

Apple
- App Review Guidelines
  - https://developer.apple.com/appstore/resources/approval/guidelines.html
- Offering account deletion in your app
  - https://developer.apple.com/support/offering-account-deletion-in-your-app
- App Review preparation
  - https://developer.apple.com/app-store/review/

Google
- Google Play Developer Program Policy
  - https://support.google.com/googleplay/android-developer/answer/16543315
- Google Play Metadata policy
  - https://support.google.com/googleplay/android-developer/answer/9898842
- Google Play Impersonation policy
  - https://support.google.com/googleplay/android-developer/answer/9888374
- Play Billing getting ready
  - https://developer.android.com/google/play/billing/getting-ready
- Play Billing subscriptions
  - https://developer.android.com/google/play/billing/subs
- Play Billing subscription lifecycle
  - https://developer.android.com/google/play/billing/lifecycle/subscriptions
- Play Billing testing
  - https://developer.android.com/google/play/billing/test

## Material Guardian release gates

### Apple

- If Material Guardian supports account creation, it must also let the user initiate account deletion inside the app.
- App Store Connect metadata and the in-app privacy policy must clearly describe backend account identity, email-code sign-in, subscription handling, organization membership, seat assignment, and what remains local-first on device.
- App Review information must include a valid demo path if review requires sign-in or paid/business flows.
- App name, subtitle, screenshots, previews, and keywords must avoid trademark misuse, misleading claims, pricing text in metadata, and irrelevant keyword stuffing.
- Any use of Apple trademarks, product names, or App Store references in screenshots/metadata must follow Apple wording rules and should be checked again at submission time.

### Google Play

- Store listing metadata must stay descriptive and non-misleading.
- App title must remain 30 characters or fewer.
- Do not use ranking claims, promotional claims, emojis, misleading icons, or language that implies a relationship with Google, Apple, or another company without rights.
- Data safety, privacy policy, and any account/data-deletion declarations in Play Console must match the actual backend behavior at release time.
- If account creation remains live, account deletion must be discoverable in-app and through the public Play Console deletion URL path, and the privacy policy must explain any retention limits that still apply to business/workspace records.
- The public privacy policy URL must stay reachable, non-geofenced, and aligned with the app name, developer identity, support contact, retention/deletion behavior, and third-party processors actually in use.
- Subscription behavior must follow current Play Billing guidance, including purchase verification, restoration, replacement handling, and acknowledgement.
- Subscription copy on the plans/purchase surface must state the renewal cadence clearly and must not imply immediate loss of access when the real behavior is end-of-period access after cancellation.
- Digital subscription purchase on Android must stay on Google Play Billing; invite and seat flows must remain entitlement management, not a disguised external checkout path.
- Test billing flows using current Play guidance before release and before significant billing changes.

## Material Guardian-specific blockers to recheck

- In-app account deletion now exists, but the shipped release still needs a final end-to-end policy pass.
  - This remains an Apple review blocker if account creation ships and the release build does not expose the delete path clearly enough.
  - It is also a Play Console/data-deletion review item that must be rechecked against the current Play requirements at submission time.
- Public policy URLs are now intended to be:
  - privacy policy: `https://demigodofa.github.io/privacy-policy/`
  - account deletion: `https://demigodofa.github.io/privacy-policy/delete-account.html`
- Confirm GitHub Pages propagation and then mirror those exact URLs into Play Console declarations before submission.
- iPhone/App Store purchase verification is not yet hardened to the same level as the current Google Play backend verification path.
- Google Play backend verification is live in Cloud Run, and Android Publisher access now works for `mg-play-verifier@asme-receiving.iam.gserviceaccount.com`.
- The remaining Google billing proof is a real purchase-token smoke from the Play-installed `com.asme.receiving` internal-test app.
- Final store screenshots, previews, title/subtitle text, keyword text, and description text still need a release-quality metadata pass.
- Privacy wording must remain aligned with the real backend scope:
  - email-code sign-in
  - email delivery provider / processor
  - session persistence
  - organization membership
  - seat assignment
  - subscription verification
  - local-first job/report/media storage boundaries

## Pre-submit checklist

- Re-read the official pages above again on the week of submission.
- Confirm no Apple or Google wording has changed for account deletion, privacy policy, subscriptions, metadata, screenshots, or impersonation/trademark rules.
- Confirm the app title/subtitle/store copy does not use misleading store language or protected marks improperly.
- Confirm review/demo credentials and test steps are current.
- Confirm privacy policy URL in store metadata matches the in-app policy and the actual shipped behavior.
- Confirm account deletion handling is implemented if account creation ships.
- Confirm billing verification works end to end on the actual target store and environment.
- Confirm screenshots match the shipped UI and do not show placeholder, debugging, or inaccurate state.
