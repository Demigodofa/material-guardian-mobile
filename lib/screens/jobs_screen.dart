import 'package:flutter/material.dart';

import '../app/material_guardian_state.dart';
import '../app/routes.dart';
import '../util/formatting.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({required this.appState, super.key});

  final MaterialGuardianAppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Material Guardian'),
            actions: [
              IconButton(
                onPressed: () async {
                  await _showCreateJobDialog(context, appState);
                },
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: 'Add Job',
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.customization);
                },
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Customization',
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                },
                icon: const Icon(Icons.policy_outlined),
                tooltip: 'Privacy Policy',
              ),
            ],
          ),
          body: ListView(
            padding: screenListPadding(context),
            children: [
              _HeroCard(appState: appState),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Active Jobs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.drafts);
                    },
                    icon: const Icon(Icons.note_alt_outlined),
                    label: Text('Drafts (${appState.drafts.length})'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (appState.jobs.isEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No jobs saved yet.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create the first job here. The Flutter shell now persists jobs and drafts locally between launches.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () async {
                            await _showCreateJobDialog(context, appState);
                          },
                          icon: const Icon(Icons.add_task_rounded),
                          label: const Text('Create First Job'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              for (final job in appState.jobs) ...[
                _JobCard(appState: appState, jobId: job.id),
                const SizedBox(height: 14),
              ],
            ],
          ),
        );
      },
    );
  }
}

Future<void> _showCreateJobDialog(
  BuildContext context,
  MaterialGuardianAppState appState,
) async {
  final jobNumberController = TextEditingController();
  final descriptionController = TextEditingController();
  final notesController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Create Job'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jobNumberController,
                decoration: const InputDecoration(labelText: 'Job number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / customer / team',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await appState.saveJob(
                jobNumber: jobNumberController.text,
                description: descriptionController.text,
                notes: notesController.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save Job'),
          ),
        ],
      );
    },
  );

  jobNumberController.dispose();
  descriptionController.dispose();
  notesController.dispose();
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.appState});

  final MaterialGuardianAppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Flutter migration shell',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Blank Add Material, explicit drafts, shared signatures, and customization defaults are already carried into the first shared client shell.',
              style: theme.textTheme.headlineSmall?.copyWith(
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Android remains the behavior donor. This shell is proving the shared flow shape while camera, scan, signature, PDF, ZIP, and policy behavior are moved into shared Flutter where possible.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatPill(label: 'Jobs', value: '${appState.jobs.length}'),
                _StatPill(label: 'Drafts', value: '${appState.drafts.length}'),
                _StatPill(
                  label: 'Surface Finish',
                  value: appState.customization.surfaceFinishRequired
                      ? 'On'
                      : 'Off',
                ),
                _StatPill(
                  label: 'Saved Signature',
                  value: appState.customization.hasSavedInspectorSignature
                      ? 'Ready'
                      : 'Off',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.appState, required this.jobId});

  final MaterialGuardianAppState appState;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    final job = appState.jobById(jobId);
    final draftCount = appState.draftsForJob(job.id).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.jobNumber,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.description.trim().isEmpty
                            ? 'Receiving job'
                            : job.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                Chip(label: Text('${job.materials.length} materials')),
              ],
            ),
            const SizedBox(height: 10),
            if (job.notes.trim().isNotEmpty)
              Text(job.notes, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.jobDetail,
                      arguments: JobDetailRouteArgs(jobId: job.id),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Open Job'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.drafts,
                      arguments: DraftsRouteArgs(jobId: job.id),
                    );
                  },
                  icon: const Icon(Icons.note_alt_outlined),
                  label: Text('Drafts ($draftCount)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
