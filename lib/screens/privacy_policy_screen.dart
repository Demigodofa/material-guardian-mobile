import 'package:flutter/material.dart';

import '../util/formatting.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<({String title, String body})> _sections = [
    (
      title: 'Overview',
      body:
          'Material Guardian, published by Welders Helper, is a receiving inspection app. In the current Android release, jobs, receiving reports, photos, scans, signatures, and exported packet files remain on your device unless you choose to export or share them. The service currently uses backend features for sign-in, account access, organization membership, seats, and subscription status.',
    ),
    (
      title: 'Data handled by the service',
      body:
          'When you create or use an account, the service may process your email address, optional display name, organization and seat information, authentication challenges, active session tokens, and subscription or entitlement status. Google Play billing data that Google processes to complete a purchase stays under Google Play\'s own payment flow, but Material Guardian does receive subscription status needed to grant or restore access.',
    ),
    (
      title: 'Data that stays on your device',
      body:
          'In the current release, your job content, receiving reports, attached photos, scanned documents, signatures, and exported packet files remain local to your device unless you intentionally export or share them. Cloud file sync and cross-device recovery for those files are not part of the current release behavior.',
    ),
    (
      title: 'Permissions and device access',
      body:
          'Material Guardian requests camera access only when you choose to capture photos or scan MTR/CoC documents. Export actions may write files to app storage and to a device-accessible folder such as Downloads/MaterialGuardian so you can keep or share the exported packet.',
    ),
    (
      title: 'How data is used',
      body:
          'We use account and subscription data to authenticate users, deliver sign-in codes, manage workspace membership and seats, verify eligibility for paid access, respond to support requests, and protect the service from misuse. We do not use the current Android release for advertising or third-party analytics tracking.',
    ),
    (
      title: 'Sharing and service providers',
      body:
          'Material Guardian does not automatically publish your reports or media. Data is shared only when you choose an export or share destination, or when service providers are needed to operate the app. Current providers can include Google Play for subscriptions, the configured email delivery provider for sign-in or invite emails, and backend hosting or database providers that run account and billing features.',
    ),
    (
      title: 'Security',
      body:
          'We use reasonable administrative and technical safeguards for the service, including HTTPS or TLS for data in transit and access controls around backend-managed account systems. Local files that stay on your device are also subject to the security settings and protections of that device.',
    ),
    (
      title: 'Retention and deletion',
      body:
          'Local jobs, reports, photos, scans, signatures, and exported files remain on the device until you delete them, uninstall the app, or clear app data. Backend account records are retained while the account is active and may be retained for a limited period where needed for security, fraud prevention, legal compliance, billing, or workspace ownership resolution. Android backup for app data is disabled in this release.',
    ),
    (
      title: 'Account deletion',
      body:
          'If you created a Material Guardian account, you can request deletion through the in-app Delete Account flow and through the public delete-account page published with the app\'s privacy policy. Deleting the backend account does not automatically cancel an active Google Play subscription, so store billing must still be canceled in Google Play. Workspace ownership or active team subscriptions can delay deletion until those obligations are resolved.',
    ),
    (
      title: 'Contact',
      body:
          'For privacy, support, or account questions, contact granitemfgllc@gmail.com.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: centeredContent(
        child: ListView(
          padding: screenListPadding(context),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Last updated: April 13, 2026. This policy summarizes the current Android release and should stay aligned with the public privacy policy URL and Google Play disclosures.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final section in _sections) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(section.body),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
