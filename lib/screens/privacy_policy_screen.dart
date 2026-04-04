import 'package:flutter/material.dart';

import '../util/formatting.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<({String title, String body})> _sections = [
    (
      title: 'Overview',
      body:
          'Material Guardian is a receiving inspection app. Jobs, receiving reports, photos, scans, signatures, and exported packet files stay on your device unless you choose to share or export them.',
    ),
    (
      title: 'Camera and document scanning',
      body:
          'If you choose to capture material photos or scan MTR/CoC documents, the app uses the device camera and document scanner only for that workflow.',
    ),
    (
      title: 'Accounts and sign-in',
      body:
          'Material Guardian can use an email-code account for sign-in, subscriptions, organization membership, and seat access. The app remembers the signed-in session on this device until you sign out or clear app data.',
    ),
    (
      title: 'Local job data',
      body:
          'Account, membership, seat, and subscription status can be checked against the Material Guardian service. Your jobs, reports, photos, scans, and signatures remain local to this device unless you export or share them.',
    ),
    (
      title: 'Organizations and billing',
      body:
          'Business plans can include organization membership, admin controls, and seat assignment. Subscription and entitlement state may be verified against the app store and the Material Guardian backend service.',
    ),
    (
      title: 'Sharing and exports',
      body:
          'When you export a job, the app writes packet files to app storage and a copy under Downloads/MaterialGuardian on your device. If you use share actions, the selected files are shared only to the destination you choose.',
    ),
    (
      title: 'Retention and control',
      body:
          'You control local data on the device. You can keep drafts, delete drafts, delete jobs, or remove exported files from device storage. Android backup and device-to-device transfer are disabled for app data in this release.',
    ),
    (
      title: 'Contact',
      body:
          'For support or privacy questions, use the contact details published with the store listing or your company deployment channel.',
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
                      'This policy reflects the shipped product behavior: local report data on the device, account and billing access through the Material Guardian service, and user-controlled exports and sharing.',
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
