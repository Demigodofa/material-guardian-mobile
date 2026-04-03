import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../app/material_guardian_state.dart';
import '../app/models.dart';
import '../util/formatting.dart';
import '../widgets/signature_capture_dialog.dart';

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({required this.appState, super.key});

  final MaterialGuardianAppState appState;

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  late bool _receiveAsmeB16Parts;
  late bool _surfaceFinishRequired;
  late String _surfaceFinishUnit;
  late bool _includeCompanyLogoOnReports;
  late String _savedInspectorSignaturePath;
  late String _companyLogoPath;
  late final TextEditingController _qcInspectorController;
  late final TextEditingController _qcManagerController;

  @override
  void initState() {
    super.initState();
    final customization = widget.appState.customization;
    _receiveAsmeB16Parts = customization.receiveAsmeB16Parts;
    _surfaceFinishRequired = customization.surfaceFinishRequired;
    _surfaceFinishUnit = customization.surfaceFinishUnit;
    _includeCompanyLogoOnReports = customization.includeCompanyLogoOnReports;
    _savedInspectorSignaturePath = customization.savedInspectorSignaturePath;
    _companyLogoPath = customization.companyLogoPath;
    _qcInspectorController = TextEditingController(
      text: customization.defaultQcInspectorName,
    );
    _qcManagerController = TextEditingController(
      text: customization.defaultQcManagerName,
    );
  }

  @override
  void dispose() {
    _qcInspectorController.dispose();
    _qcManagerController.dispose();
    super.dispose();
  }

  Future<void> _persistCustomizationAssets({
    String? successMessage,
  }) async {
    final nextSettings = widget.appState.customization.copyWith(
      receiveAsmeB16Parts: _receiveAsmeB16Parts,
      surfaceFinishRequired: _surfaceFinishRequired,
      surfaceFinishUnit: _surfaceFinishUnit,
      defaultQcInspectorName: _qcInspectorController.text.trim(),
      defaultQcManagerName: _qcManagerController.text.trim(),
      includeCompanyLogoOnReports: _includeCompanyLogoOnReports,
      hasSavedInspectorSignature:
          _savedInspectorSignaturePath.trim().isNotEmpty,
      savedInspectorSignaturePath: _savedInspectorSignaturePath,
      companyLogoPath: _companyLogoPath,
    );
    await widget.appState.saveCustomization(nextSettings);
    if (!mounted || successMessage == null || successMessage.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final canManageWorkspaceSettings =
        widget.appState.hasAdminLikeWorkspaceAccess;
    final hasLogo = _companyLogoPath.trim().isNotEmpty;
    final hasSavedSignature = _savedInspectorSignaturePath.trim().isNotEmpty;
    final cardBackground = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    final deleteColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Customization')),
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
                      canManageWorkspaceSettings
                          ? 'Workspace receiving defaults'
                          : 'Your receiving defaults',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      canManageWorkspaceSettings
                          ? 'These defaults drive what the receiving form shows and what new drafts inherit. Material-level Imperial or Metric remains a live choice on each report.'
                          : 'Your printed inspector name and saved signature stay personal. Company logo and report-setting choices stay under the solo/admin workspace controls.',
                    ),
                    const SizedBox(height: 20),
                    if (canManageWorkspaceSettings) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _receiveAsmeB16Parts,
                        onChanged: (value) {
                          setState(() {
                            _receiveAsmeB16Parts = value;
                          });
                        },
                        title: const Text('Receive ASME B16 parts'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _surfaceFinishRequired,
                        onChanged: (value) {
                          setState(() {
                            _surfaceFinishRequired = value;
                          });
                        },
                        title: const Text('Surface finish required'),
                      ),
                    ],
                    if (canManageWorkspaceSettings &&
                        _surfaceFinishRequired) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Surface finish unit',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ChoiceChip(
                            label: const Text('u-in'),
                            selected: _surfaceFinishUnit == 'u-in',
                            onSelected: (_) {
                              setState(() {
                                _surfaceFinishUnit = 'u-in';
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Ra'),
                            selected: _surfaceFinishUnit == 'Ra',
                            onSelected: (_) {
                              setState(() {
                                _surfaceFinishUnit = 'Ra';
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _qcInspectorController,
                      inputFormatters: [LengthLimitingTextInputFormatter(20)],
                      decoration: InputDecoration(
                        labelText: canManageWorkspaceSettings
                            ? 'Default QC inspector printed name'
                            : 'Your QC inspector printed name',
                      ),
                    ),
                    if (canManageWorkspaceSettings) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _qcManagerController,
                        inputFormatters: [LengthLimitingTextInputFormatter(20)],
                        decoration: const InputDecoration(
                          labelText: 'Default QC manager printed name',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      canManageWorkspaceSettings
                          ? 'Saved QC inspector signature'
                          : 'Your saved inspector signature',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasSavedSignature &&
                              File(
                                _savedInspectorSignaturePath,
                              ).existsSync()) ...[
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.all(8),
                                  child: Image.file(
                                    File(_savedInspectorSignaturePath),
                                    height: 88,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            hasSavedSignature
                                ? p.basename(_savedInspectorSignaturePath)
                                : 'No reusable inspector signature has been imported yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: hasSavedSignature
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final pngBytes = await showSignatureCaptureDialog(
                              context,
                              title: 'Capture default QC inspector signature',
                            );
                            if (pngBytes == null || !context.mounted) {
                              return;
                            }
                            final nextPath = await widget
                                .appState
                                .customizationAssetService
                                .captureSavedInspectorSignature(pngBytes);
                            if (!context.mounted) {
                              return;
                            }
                            setState(() {
                              _savedInspectorSignaturePath = nextPath;
                            });
                            await _persistCustomizationAssets(
                              successMessage: 'Saved inspector signature.',
                            );
                          },
                          icon: const Icon(Icons.draw_outlined),
                          label: Text(
                            _savedInspectorSignaturePath.trim().isEmpty
                                ? 'Capture Signature'
                                : 'Re-sign',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final nextPath = await widget
                                .appState
                                .customizationAssetService
                                .importSavedInspectorSignature();
                            if (nextPath == null || !context.mounted) {
                              return;
                            }
                            setState(() {
                              _savedInspectorSignaturePath = nextPath;
                            });
                            await _persistCustomizationAssets(
                              successMessage: 'Imported inspector signature.',
                            );
                          },
                          icon: const Icon(Icons.file_open_outlined),
                          label: const Text('Import Signature'),
                        ),
                        if (hasSavedSignature)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final opened = await widget
                                  .appState
                                  .customizationAssetService
                                  .openAsset(_savedInspectorSignaturePath);
                              if (opened || !context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not open the saved signature preview.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Preview Signature'),
                          ),
                        if (hasSavedSignature)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: deleteColor,
                            ),
                            onPressed: () async {
                              await widget.appState.customizationAssetService
                                  .clearAssetPath(_savedInspectorSignaturePath);
                              if (!context.mounted) {
                                return;
                              }
                              setState(() {
                                _savedInspectorSignaturePath = '';
                              });
                              await _persistCustomizationAssets(
                                successMessage: 'Removed saved signature.',
                              );
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Remove Signature'),
                          ),
                      ],
                    ),
                    if (canManageWorkspaceSettings) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Company logo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasLogo &&
                                File(_companyLogoPath).existsSync()) ...[
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.all(10),
                                    child: Image.file(
                                      File(_companyLogoPath),
                                      height: 120,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              hasLogo
                                  ? p.basename(_companyLogoPath)
                                  : 'No company logo has been imported yet.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: hasLogo
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final nextPath = await widget
                                  .appState
                                  .customizationAssetService
                                  .importCompanyLogo();
                              if (nextPath == null || !context.mounted) {
                                return;
                              }
                              setState(() {
                                _companyLogoPath = nextPath;
                              });
                              await _persistCustomizationAssets(
                                successMessage: hasLogo
                                    ? 'Replaced company logo.'
                                    : 'Imported company logo.',
                              );
                            },
                            icon: const Icon(Icons.image_outlined),
                            label: Text(
                              hasLogo ? 'Replace Logo' : 'Import Logo',
                            ),
                          ),
                          if (hasLogo)
                            OutlinedButton.icon(
                              onPressed: () async {
                                final opened = await widget
                                    .appState
                                    .customizationAssetService
                                    .openAsset(_companyLogoPath);
                                if (opened || !context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open the imported logo preview.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Preview Logo'),
                            ),
                          if (hasLogo)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: deleteColor,
                              ),
                              onPressed: () async {
                                await widget.appState.customizationAssetService
                                    .clearAssetPath(_companyLogoPath);
                                if (!context.mounted) {
                                  return;
                                }
                                setState(() {
                                  _companyLogoPath = '';
                                });
                                await _persistCustomizationAssets(
                                  successMessage: 'Removed company logo.',
                                );
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Remove Logo'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _includeCompanyLogoOnReports,
                        onChanged: (value) {
                          setState(() {
                            _includeCompanyLogoOnReports = value;
                          });
                        },
                        title: const Text('Include company logo on reports'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () async {
                await widget.appState.saveCustomization(
                  CustomizationSettings(
                    receiveAsmeB16Parts: _receiveAsmeB16Parts,
                    surfaceFinishRequired: _surfaceFinishRequired,
                    surfaceFinishUnit: _surfaceFinishUnit,
                    defaultQcInspectorName: _qcInspectorController.text.trim(),
                    defaultQcManagerName: _qcManagerController.text.trim(),
                    hasSavedInspectorSignature: _savedInspectorSignaturePath
                        .trim()
                        .isNotEmpty,
                    savedInspectorSignaturePath: _savedInspectorSignaturePath,
                    includeCompanyLogoOnReports: _includeCompanyLogoOnReports,
                    companyLogoPath: _companyLogoPath,
                  ),
                );
                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Customization'),
            ),
          ],
        ),
      ),
    );
  }
}
