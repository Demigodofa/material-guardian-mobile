# Google Play Privacy Alignment

Date: April 13, 2026

## Why this note exists

Material Guardian now has backend-managed sign-in, workspace membership, seat assignment, account deletion, and Google Play subscription verification. That means the in-app privacy screen, the public privacy-policy URL, and the Play Console `Data safety` answers all need to describe the same real behavior.

## Official Google Play requirements reviewed

- `Understanding Google Play's app account deletion requirements`
  - If the app allows account creation, it must provide:
    - an in-app account deletion path
    - a functional public web link where users can request account deletion
  - the public web link must clearly reference the app or listed developer name and keep the deletion path easy to find
- `Provide information for Google Play's Data safety section`
  - data is generally `collected` for Play purposes when it is transmitted off the device
  - data entered into an account profile must be disclosed for account-management purposes
  - payment credentials collected directly by Google Play do not need to be declared by the app if the app is only using Google Play's billing system
- `SDK Requirements - Play Console Help`
  - privacy-policy disclosures and prominent-disclosure expectations also apply to third-party SDK behavior

## Similar-program pattern review

Compared with field-inspection and form/reporting products such as GoCanvas, the common structure is:

- overview and scope
- what data is collected by the service
- what data remains customer-controlled
- how data is used
- service providers or third-party sharing
- security
- retention and deletion
- contact details

Material Guardian should stay in that structure and avoid developer-internal wording such as:

- `this screen should match`
- `future upgrade wording`
- references to old app states that are no longer the release truth

## Current Material Guardian truth to keep aligned

### Data that is processed by the backend

- email address
- optional display name
- authentication challenges
- session tokens
- organization membership and seat state
- entitlement and subscription state returned to Material Guardian after Google Play verification

### Data that currently remains local on-device

- jobs
- receiving reports
- photos
- scanned documents
- signatures
- exported packets

These local-only files should not be marked as `collected` in Play `Data safety` unless the app later starts transmitting them off-device.

## Play Console follow-through still required

1. Re-check the `Data safety` form against the current Android release.
2. Confirm the privacy-policy URL points to the updated public page in the `privacy-policy` repo.
3. Confirm the external account-deletion URL points to `delete-account.html`.
4. Make sure the `Data safety` answers stay consistent with the current release truth:
   - account data is collected for account management
   - Google Play payment credentials are handled by Google Play
   - local jobs and report media are not declared as collected if they remain on-device only
   - no ad tracking or third-party analytics should be declared if none are present
5. Re-check the store listing contact details so they match the public policy and in-app policy.

## Files updated in this pass

- `material-guardian-mobile/lib/screens/privacy_policy_screen.dart`
- `privacy-policy/index.html`
- `privacy-policy/delete-account.html`

