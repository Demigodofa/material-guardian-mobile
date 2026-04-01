import 'package:flutter/material.dart';

import '../app/material_guardian_state.dart';
import '../app/routes.dart';
import '../util/formatting.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({
    required this.appState,
    required this.jobId,
    super.key,
  });

  final MaterialGuardianAppState appState;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final job = appState.jobById(jobId);
        final drafts = appState.draftsForJob(jobId);
        return Scaffold(
          appBar: AppBar(title: Text(job.jobNumber)),
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
                        job.description.trim().isEmpty
                            ? 'Receiving job'
                            : job.description,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.notes.trim().isEmpty
                            ? 'Use this job to collect receiving materials, drafts, and later exports.'
                            : job.notes,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () async {
                              final draft = await appState.createBlankDraft(
                                jobId: jobId,
                              );
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.pushNamed(
                                context,
                                AppRoutes.materialForm,
                                arguments: MaterialFormRouteArgs(
                                  jobId: jobId,
                                  draftId: draft.id,
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_task_rounded),
                            label: const Text('Add Material'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await _showEditJobDialog(
                                context,
                                appState,
                                jobId,
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Job'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await appState.deleteJob(jobId);
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Delete Job'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.drafts,
                                arguments: DraftsRouteArgs(jobId: jobId),
                              );
                            },
                            icon: const Icon(Icons.history_edu_outlined),
                            label: Text('Resume Draft (${drafts.length})'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.customization,
                              );
                            },
                            icon: const Icon(Icons.tune_rounded),
                            label: const Text('Customization'),
                          ),
                          FilledButton.icon(
                            onPressed: () async {
                              final result = await appState.exportJob(jobId);
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Exported ${result.packetCount} packet PDFs, ${result.photoCount} photos, and ${result.scanCount} scans.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.ios_share_outlined),
                            label: const Text('Export Job'),
                          ),
                        ],
                      ),
                      if (job.exportPath.trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Latest export: ${job.exportPath}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final opened = await appState.mediaService
                                    .openPath(job.exportPath);
                                if (opened || !context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open the export folder on this device.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.folder_open_outlined),
                              label: const Text('Open Export'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final shared = await appState
                                    .shareLatestExportPdfs(jobId);
                                if (shared || !context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not share the latest packet PDFs.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: const Text('Share PDFs'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final shared = await appState
                                    .shareLatestExportZip(jobId);
                                if (shared || !context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not share the latest export ZIP.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.archive_outlined),
                              label: const Text('Share ZIP'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (drafts.isNotEmpty) ...[
                Text(
                  'Active Drafts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final draft in drafts) ...[
                  Card(
                    child: ListTile(
                      title: Text(
                        draft.description.trim().isEmpty
                            ? draft.sourceMaterialId.trim().isEmpty
                                  ? 'Blank receiving draft'
                                  : 'Material edit draft'
                            : draft.description,
                      ),
                      subtitle: Text(
                        'Updated ${formatCompactDateTime(draft.updatedAt)}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.materialForm,
                          arguments: MaterialFormRouteArgs(
                            jobId: jobId,
                            draftId: draft.id,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
              ],
              Text(
                'Saved Materials',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final material in job.materials) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    material.tag,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    material.description,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            Chip(label: Text('Qty ${material.quantity}')),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          [
                            if (material.vendor.trim().isNotEmpty)
                              'Vendor ${material.vendor.trim()}',
                            if (material.poNumber.trim().isNotEmpty)
                              'PO ${material.poNumber.trim()}',
                            if (material.heatNumber.trim().isNotEmpty)
                              'Heat ${material.heatNumber.trim()}',
                          ].join('  |  '),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (material.productType.trim().isNotEmpty)
                              Chip(label: Text(material.productType.trim())),
                            Chip(label: Text(material.dimensionUnit.label)),
                            Chip(
                              label: Text(
                                material.acceptanceStatus.toUpperCase(),
                              ),
                            ),
                            if (material.photoPaths.isNotEmpty)
                              Chip(
                                label: Text(
                                  'Photos ${material.photoPaths.length}',
                                ),
                              ),
                            if (material.scanPaths.isNotEmpty)
                              Chip(
                                label: Text(
                                  'Scans ${material.scanPaths.length}',
                                ),
                              ),
                            Chip(
                              label: Text(
                                material.visualInspectionAcceptable
                                    ? 'Visual OK'
                                    : 'Visual Hold',
                              ),
                            ),
                            Chip(
                              label: Text(
                                material.markingAcceptableNa
                                    ? 'Markings N/A'
                                    : material.markingAcceptable
                                    ? 'Markings Yes'
                                    : 'Markings No',
                              ),
                            ),
                            Chip(
                              label: Text(
                                material.mtrAcceptableNa
                                    ? 'MTR N/A'
                                    : material.mtrAcceptable
                                    ? 'MTR Yes'
                                    : 'MTR No',
                              ),
                            ),
                          ],
                        ),
                        if (material.comments.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            material.comments,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final draft = await appState.createEditDraft(
                                  jobId: jobId,
                                  materialId: material.id,
                                );
                                if (!context.mounted) {
                                  return;
                                }
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.materialForm,
                                  arguments: MaterialFormRouteArgs(
                                    jobId: jobId,
                                    draftId: draft.id,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit Material'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirmed =
                                    await _showDeleteMaterialDialog(
                                      context,
                                      material.description.trim().isEmpty
                                          ? material.tag
                                          : material.description,
                                    );
                                if (confirmed != true) {
                                  return;
                                }
                                await appState.deleteMaterial(
                                  jobId: jobId,
                                  materialId: material.id,
                                );
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

Future<void> _showEditJobDialog(
  BuildContext context,
  MaterialGuardianAppState appState,
  String jobId,
) async {
  final job = appState.jobById(jobId);
  final jobNumberController = TextEditingController(text: job.jobNumber);
  final descriptionController = TextEditingController(text: job.description);
  final notesController = TextEditingController(text: job.notes);

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Edit Job'),
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
              await appState.updateJob(
                jobId: jobId,
                jobNumber: jobNumberController.text,
                description: descriptionController.text,
                notes: notesController.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      );
    },
  );

  jobNumberController.dispose();
  descriptionController.dispose();
  notesController.dispose();
}

Future<bool?> _showDeleteMaterialDialog(
  BuildContext context,
  String materialLabel,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete receiving report?'),
        content: Text('Delete $materialLabel from this job?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}
