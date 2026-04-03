import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/brand_assets.dart';
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
        final entitlement = appState.effectiveBackendEntitlement;
        final hasUsableJobAccess = appState.hasUsableJobAccess;
        return Scaffold(
          body: SafeArea(
            child: centeredContent(
              child: ListView(
                padding: screenListPadding(context).copyWith(top: 24),
                children: [
                  const _LandingLogo(),
                  const SizedBox(height: 20),
                  if (entitlement != null &&
                      (appState.isTrialAccess ||
                          appState.isLockedFromSubscription ||
                          appState.isSeatBlocked)) ...[
                    _AccessBanner(
                      appState: appState,
                      onViewPlans: () {
                        Navigator.pushNamed(context, AppRoutes.sales);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: FilledButton(
                        onPressed: () async {
                          if (!hasUsableJobAccess) {
                            Navigator.pushNamed(context, AppRoutes.sales);
                            return;
                          }
                          await _showCreateJobDialog(context, appState);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text('Create Job'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _LandingLinkButton(
                        label: 'Plans',
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.sales);
                        },
                      ),
                      if (appState.shouldShowAccountEntry)
                        _LandingLinkButton(
                          label: 'Account',
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.account);
                          },
                        ),
                      _LandingLinkButton(
                        label: 'Customization',
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.customization);
                        },
                      ),
                      _LandingLinkButton(
                        label: 'Privacy Policy',
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 14),
                  Text(
                    'Current Jobs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (appState.jobs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No jobs yet. Create your first job above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF7B8794)),
                        ),
                      ),
                    )
                  else
                    for (final job in appState.jobs) ...[
                      _JobLinkRow(appState: appState, jobId: job.id),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccessBanner extends StatelessWidget {
  const _AccessBanner({required this.appState, required this.onViewPlans});

  final MaterialGuardianAppState appState;
  final VoidCallback onViewPlans;

  @override
  Widget build(BuildContext context) {
    final entitlement = appState.effectiveBackendEntitlement;
    if (entitlement == null) {
      return const SizedBox.shrink();
    }

    final title = switch (entitlement.accessState) {
      'trial' => 'Free trial active',
      'no_seat' => 'No seat assigned yet',
      'locked' => 'Choose a plan to keep going',
      _ => 'Account update',
    };
    final message = switch (entitlement.accessState) {
      'trial' =>
        'You have ${entitlement.trialRemaining} free jobs remaining. When the trial runs out, come back here to pick a plan and keep the same workflow.',
      'no_seat' =>
        'Your business account is in the system, but this user does not have a seat assigned yet. Contact your admin.',
      'locked' =>
        'Your free jobs are used up. Pick the plan that fits your shop and come right back to work.',
      _ => '',
    };

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message),
            if (entitlement.accessState != 'no_seat') ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onViewPlans,
                child: const Text('View Plans'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _showCreateJobDialog(
  BuildContext context,
  MaterialGuardianAppState appState,
) async {
  var jobNumber = '';
  var description = '';
  var notes = '';

  final request = await showDialog<
    ({String jobNumber, String description, String notes})
  >(
    context: context,
    builder: (context) {
      return AlertDialog(
        scrollable: true,
        title: const Text('Create New Job'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(24)],
                onChanged: (value) {
                  jobNumber = value;
                },
                decoration: const InputDecoration(labelText: 'Job Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                onChanged: (value) {
                  description = value;
                },
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                textInputAction: TextInputAction.done,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                onChanged: (value) {
                  notes = value;
                },
                decoration: const InputDecoration(labelText: 'Notes'),
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
              if (jobNumber.trim().isEmpty) {
                return;
              }
              Navigator.pop(
                context,
                (
                  jobNumber: jobNumber,
                  description: description,
                  notes: notes,
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      );
    },
  );

  if (request == null) {
    return;
  }

  await appState.saveJob(
    jobNumber: request.jobNumber,
    description: request.description,
    notes: request.notes,
  );
}

class _LandingLogo extends StatelessWidget {
  const _LandingLogo();

  @override
  Widget build(BuildContext context) {
    final logoSize = (MediaQuery.sizeOf(context).height * 0.2).clamp(
      96.0,
      160.0,
    );
    return Center(
      child: Image.asset(
        BrandAssets.materialGuardianLogo512,
        width: logoSize,
        height: logoSize,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _LandingLinkButton extends StatelessWidget {
  const _LandingLinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            color: const Color(0xFF1E3A5F),
          ),
        ),
      ),
    );
  }
}

class _JobLinkRow extends StatelessWidget {
  const _JobLinkRow({required this.appState, required this.jobId});

  final MaterialGuardianAppState appState;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    final job = appState.jobById(jobId);
    final exportStatus = job.exportedAt == null ? 'Not exported' : 'Exported';
    final exportColor = job.exportedAt == null
        ? const Color(0xFF9A3412)
        : const Color(0xFF166534);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.jobDetail,
            arguments: JobDetailRouteArgs(jobId: job.id),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job# ${job.jobNumber}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1E3A5F),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    if (job.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        job.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      exportStatus,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: exportColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (job.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(job.notes),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${job.materials.length} materials',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF566173),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB00020),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      final message = job.exportedAt == null
                          ? 'This job has not been exported yet. Deleting will remove it and its materials from this device.'
                          : 'This job was already exported. Delete the local copy?';
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
                              foregroundColor: const Color(0xFFB00020),
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirmed != true) {
                    return;
                  }
                  await appState.deleteJob(job.id);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
