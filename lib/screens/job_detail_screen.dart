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
        final sortedDrafts = [...drafts]
          ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
        final latestDraft = sortedDrafts.isEmpty ? null : sortedDrafts.first;
        return Scaffold(
          appBar: AppBar(title: Text(job.jobNumber)),
          body: centeredContent(
            child: ListView(
              padding: screenListPadding(context),
              children: [
                Center(
                  child: Text(
                    'JOB DETAILS',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          await _showEditJobDialog(context, appState, jobId);
                        },
                        child: Text(
                          'Job# ${job.jobNumber}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF1E3A5F),
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      job.exportedAt == null ? 'Not exported' : 'Exported',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: job.exportedAt == null
                            ? const Color(0xFF9A3412)
                            : const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    await _showEditJobDialog(context, appState, jobId);
                  },
                  child: Text(
                    job.description.trim().isEmpty
                        ? 'Add job description'
                        : job.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: job.description.trim().isEmpty
                          ? const Color(0xFF1E3A5F)
                          : null,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                if (job.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(job.notes),
                ],
                const SizedBox(height: 24),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: FilledButton(
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
                      child: const Text('Add Receiving Report'),
                    ),
                  ),
                ),
                if (latestDraft != null) ...[
                  const SizedBox(height: 10),
                  if (sortedDrafts.length == 1)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.materialForm,
                                arguments: MaterialFormRouteArgs(
                                  jobId: jobId,
                                  draftId: latestDraft.id,
                                ),
                              );
                            },
                            child: const Text('Resume Draft'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () async {
                            final confirmed = await _showDeleteDraftDialog(
                              context,
                              latestDraft.description.trim().isEmpty
                                  ? 'this draft'
                                  : latestDraft.description,
                            );
                            if (confirmed != true) {
                              return;
                            }
                            await appState.deleteDraft(latestDraft.id);
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Draft deleted.')),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          child: const Text('Delete Draft'),
                        ),
                      ],
                    )
                  else
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.drafts,
                              arguments: DraftsRouteArgs(jobId: jobId),
                            );
                          },
                          child: Text('Open Drafts (${sortedDrafts.length})'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    latestDraft.description.trim().isEmpty
                        ? sortedDrafts.length == 1
                              ? 'Unsaved receiving report draft'
                              : '${sortedDrafts.length} saved drafts ready to resume'
                        : latestDraft.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _showEditJobDialog(context, appState, jobId);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Job'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.customization);
                      },
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Customization'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () async {
                        final confirmed = await _showDeleteJobDialog(
                          context,
                          alreadyExported: job.exportedAt != null,
                        );
                        if (confirmed != true) {
                          return;
                        }
                        await appState.deleteJob(jobId);
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete Job'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Materials Received',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (job.materials.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'No receiving reports saved yet.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                for (final material in job.materials) ...[
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    material.description.trim().isEmpty
                                        ? 'Material'
                                        : material.description.trim(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qty ${material.quantity}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
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
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 18),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: FilledButton.icon(
                      onPressed: () async {
                        final confirmed = await _showExportJobDialog(
                          context,
                          alreadyExported: job.exportedAt != null,
                        );
                        if (confirmed != true) {
                          return;
                        }
                        final result = await appState.exportJob(jobId);
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result.downloadsFolder.trim().isEmpty
                                  ? 'Exported ${result.packetCount} packet PDFs, ${result.photoCount} photos, and ${result.scanCount} scans.'
                                  : 'Exported ${result.packetCount} packet PDFs, ${result.photoCount} photos, and ${result.scanCount} scans to ${result.downloadsFolder}.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.ios_share_outlined),
                      label: const Text('Export Job'),
                    ),
                  ),
                ),
                if (job.exportPath.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Latest export folder',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  if (job.exportedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last exported ${_formatExportTimestamp(job.exportedAt!)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final opened = await appState.mediaService.openExport(
                            exportRootPath: job.exportPath,
                            jobNumber: job.jobNumber,
                          );
                          if (opened || !context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not open the exported files on this device.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.folder_open_outlined),
                        label: const Text('Open Export Folder'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayExportFolder(job.jobNumber),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final shared = await appState.shareLatestExportPdfs(
                              jobId,
                            );
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
                          child: const Text('Share PDFs'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final shared = await appState.shareLatestExportZip(
                              jobId,
                            );
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
                          child: const Text('Share ZIP'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

String _displayExportFolder(String jobNumber) {
  final safeJobNumber = jobNumber
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return 'Downloads/MaterialGuardian/${safeJobNumber.isEmpty ? 'job' : safeJobNumber}';
}

String _formatExportTimestamp(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final year = (local.year % 100).toString().padLeft(2, '0');
  final hour24 = local.hour;
  final suffix = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month/$day/$year at $hour12:$minute $suffix';
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

Future<bool?> _showDeleteJobDialog(
  BuildContext context, {
  required bool alreadyExported,
}) {
  final message = alreadyExported
      ? 'This job was already exported. Delete the local copy?'
      : 'This job has not been exported yet. Deleting will remove it and its materials from this device.';
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete job?'),
        content: Text(message),
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

Future<bool?> _showExportJobDialog(
  BuildContext context, {
  required bool alreadyExported,
}) {
  final message = alreadyExported
      ? 'This job was already exported. Export again?'
      : 'Export job files to local storage and Downloads?';
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Export job'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Export'),
          ),
        ],
      );
    },
  );
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

Future<bool?> _showDeleteDraftDialog(BuildContext context, String draftLabel) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete draft?'),
        content: Text('Delete $draftLabel?'),
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}
