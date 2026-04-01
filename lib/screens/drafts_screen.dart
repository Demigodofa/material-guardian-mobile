import 'package:flutter/material.dart';

import '../app/material_guardian_state.dart';
import '../app/routes.dart';
import '../util/formatting.dart';

class DraftsScreen extends StatelessWidget {
  const DraftsScreen({required this.appState, this.jobId, super.key});

  final MaterialGuardianAppState appState;
  final String? jobId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final drafts = jobId == null
            ? appState.drafts
            : appState.draftsForJob(jobId!);

        return Scaffold(
          appBar: AppBar(
            title: Text(jobId == null ? 'Material Drafts' : 'Job Drafts'),
          ),
          body: ListView(
            padding: screenListPadding(context),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Drafts stay explicit. Add Material always opens blank, and interrupted work is resumed from here instead of silently hijacking the create action.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.35),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (drafts.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No drafts are waiting in this view yet.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                )
              else
                for (final draft in drafts) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.description.trim().isEmpty
                                ? draft.sourceMaterialId.trim().isEmpty
                                      ? 'Blank receiving draft'
                                      : 'Material edit draft'
                                : draft.description,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${appState.jobById(draft.jobId).jobNumber} - ${draft.sourceMaterialId.trim().isEmpty ? 'new material' : 'editing saved material'} - updated ${formatCompactDateTime(draft.updatedAt)}',
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.materialForm,
                                    arguments: MaterialFormRouteArgs(
                                      jobId: draft.jobId,
                                      draftId: draft.id,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(
                                  draft.sourceMaterialId.trim().isEmpty
                                      ? 'Resume Draft'
                                      : 'Resume Edit',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await appState.deleteDraft(draft.id);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Draft deleted.'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Delete Draft'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }
}
