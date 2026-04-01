import 'package:flutter/material.dart';

import '../util/formatting.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<({String title, String body})> _sections = [
    (
      title: 'Overview',
      body:
          'Material Guardian is an offline-first receiving inspection app. The app stores jobs, receiving reports, material photos, scanned PDFs, signatures, and exported packet files on your device.',
    ),
    (
      title: 'Camera and document scanning',
      body:
          'If you choose to capture material photos or scan MTR/CoC documents, the app uses the device camera and document scanner only for that workflow.',
    ),
    (
      title: 'Data handling',
      body:
          'Material Guardian does not require an account. The current release does not upload your jobs, reports, photos, scans, or signatures to a cloud service operated by the developer.',
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
      body: ListView(
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This mirrors the current Android donor policy wording so the shared Flutter app keeps the same product promises while platform-specific permissions are finished on each OS.',
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
    );
  }
}
