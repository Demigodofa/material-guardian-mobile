import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customization')),
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
                    'App-level receiving defaults',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These defaults drive what the receiving form shows and what new drafts inherit. Material-level Imperial or Metric remains a live choice on each report.',
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _surfaceFinishUnit,
                    decoration: const InputDecoration(
                      labelText: 'Surface finish unit',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'u-in', child: Text('u-in')),
                      DropdownMenuItem(value: 'Ra', child: Text('Ra')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _surfaceFinishUnit = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _qcInspectorController,
                    decoration: const InputDecoration(
                      labelText: 'Default QC inspector printed name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _qcManagerController,
                    decoration: const InputDecoration(
                      labelText: 'Default QC manager printed name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Saved QC inspector signature',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _savedInspectorSignaturePath.trim().isEmpty
                        ? 'No reusable inspector signature has been imported yet.'
                        : _savedInspectorSignaturePath,
                    style: Theme.of(context).textTheme.bodyMedium,
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
                        },
                        icon: const Icon(Icons.file_open_outlined),
                        label: const Text('Import Signature'),
                      ),
                      if (_savedInspectorSignaturePath.trim().isNotEmpty)
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
                      if (_savedInspectorSignaturePath.trim().isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () async {
                            await widget.appState.customizationAssetService
                                .clearAssetPath(_savedInspectorSignaturePath);
                            if (!context.mounted) {
                              return;
                            }
                            setState(() {
                              _savedInspectorSignaturePath = '';
                            });
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Remove Signature'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Company logo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _companyLogoPath.trim().isEmpty
                        ? 'No company logo has been imported yet.'
                        : _companyLogoPath,
                    style: Theme.of(context).textTheme.bodyMedium,
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
                        },
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          _companyLogoPath.trim().isEmpty
                              ? 'Import Logo'
                              : 'Replace Logo',
                        ),
                      ),
                      if (_companyLogoPath.trim().isNotEmpty)
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
                      if (_companyLogoPath.trim().isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () async {
                            await widget.appState.customizationAssetService
                                .clearAssetPath(_companyLogoPath);
                            if (!context.mounted) {
                              return;
                            }
                            setState(() {
                              _companyLogoPath = '';
                            });
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
            label: const Text('Save Defaults'),
          ),
        ],
      ),
    );
  }
}
