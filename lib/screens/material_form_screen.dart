import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../app/material_guardian_state.dart';
import '../app/models.dart';
import '../services/material_media_service.dart';
import '../util/formatting.dart';
import '../widgets/signature_capture_dialog.dart';

class MaterialFormScreen extends StatefulWidget {
  const MaterialFormScreen({
    required this.appState,
    required this.jobId,
    required this.draftId,
    super.key,
  });

  final MaterialGuardianAppState appState;
  final String jobId;
  final String draftId;

  @override
  State<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends State<MaterialFormScreen> {
  late final TextEditingController _materialTagController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _vendorController;
  late final TextEditingController _poNumberController;
  late final TextEditingController _productTypeController;
  late final TextEditingController _specificationPrefixController;
  late final TextEditingController _gradeTypeController;
  late final TextEditingController _fittingStandardController;
  late final TextEditingController _fittingSuffixController;
  late final TextEditingController _heatNumberController;
  late final TextEditingController _quantityController;
  late final TextEditingController _thickness1Controller;
  late final TextEditingController _widthController;
  late final TextEditingController _lengthController;
  late final TextEditingController _diameterController;
  late final TextEditingController _diameterTypeController;
  late final TextEditingController _b16SizeController;
  late final TextEditingController _surfaceFinishController;
  late final TextEditingController _surfaceFinishReadingController;
  late final TextEditingController _markingsController;
  late final TextEditingController _commentsController;
  late final TextEditingController _qcInspectorController;
  late final TextEditingController _qcManagerController;
  late UnitSystem _unitSystem;
  late bool _includesB16Data;
  late bool _signatureApplied;
  late bool _visualInspectionAcceptable;
  late bool _markingAcceptable;
  late bool _markingAcceptableNa;
  late bool _mtrAcceptable;
  late bool _mtrAcceptableNa;
  late String _acceptanceStatus;
  late List<String> _photoPaths;
  late List<String> _scanPaths;
  late String _qcSignaturePath;
  late String _qcManagerSignaturePath;

  static const List<String> _acceptanceOptions = ['accept', 'hold', 'reject'];

  MaterialDraft get _draft => widget.appState.draftById(widget.draftId);
  CustomizationSettings get _customization => widget.appState.customization;
  bool get _isEditingExistingMaterial =>
      _draft.sourceMaterialId.trim().isNotEmpty;
  String get _materialLabelForFiles {
    final tag = _materialTagController.text.trim();
    if (tag.isNotEmpty) {
      return tag;
    }
    final description = _descriptionController.text.trim();
    if (description.isNotEmpty) {
      return description;
    }
    return 'material';
  }

  List<TextEditingController> get _autosaveControllers => [
    _materialTagController,
    _descriptionController,
    _vendorController,
    _poNumberController,
    _productTypeController,
    _specificationPrefixController,
    _gradeTypeController,
    _fittingStandardController,
    _fittingSuffixController,
    _heatNumberController,
    _quantityController,
    _thickness1Controller,
    _widthController,
    _lengthController,
    _diameterController,
    _diameterTypeController,
    _b16SizeController,
    _surfaceFinishController,
    _surfaceFinishReadingController,
    _markingsController,
    _commentsController,
    _qcInspectorController,
    _qcManagerController,
  ];

  @override
  void initState() {
    super.initState();
    final draft = _draft;
    _materialTagController = TextEditingController(text: draft.materialTag);
    _descriptionController = TextEditingController(text: draft.description);
    _vendorController = TextEditingController(text: draft.vendor);
    _poNumberController = TextEditingController(text: draft.poNumber);
    _productTypeController = TextEditingController(text: draft.productType);
    _specificationPrefixController = TextEditingController(
      text: draft.specificationPrefix,
    );
    _gradeTypeController = TextEditingController(text: draft.gradeType);
    _fittingStandardController = TextEditingController(
      text: draft.fittingStandard,
    );
    _fittingSuffixController = TextEditingController(text: draft.fittingSuffix);
    _heatNumberController = TextEditingController(text: draft.heatNumber);
    _quantityController = TextEditingController(text: draft.quantity);
    _thickness1Controller = TextEditingController(text: draft.thickness1);
    _widthController = TextEditingController(text: draft.width);
    _lengthController = TextEditingController(text: draft.length);
    _diameterController = TextEditingController(text: draft.diameter);
    _diameterTypeController = TextEditingController(text: draft.diameterType);
    _b16SizeController = TextEditingController(text: draft.b16Size);
    _surfaceFinishController = TextEditingController(text: draft.surfaceFinish);
    _surfaceFinishReadingController = TextEditingController(
      text: draft.surfaceFinishReading,
    );
    _markingsController = TextEditingController(text: draft.markings);
    _commentsController = TextEditingController(text: draft.comments);
    _qcInspectorController = TextEditingController(text: draft.qcInspectorName);
    _qcManagerController = TextEditingController(text: draft.qcManagerName);
    _unitSystem = draft.unitSystem;
    _includesB16Data = draft.includesB16Data;
    _signatureApplied = draft.signatureApplied;
    _visualInspectionAcceptable = draft.visualInspectionAcceptable;
    _markingAcceptable = draft.markingAcceptable;
    _markingAcceptableNa = draft.markingAcceptableNa;
    _mtrAcceptable = draft.mtrAcceptable;
    _mtrAcceptableNa = draft.mtrAcceptableNa;
    _acceptanceStatus = draft.acceptanceStatus;
    _photoPaths = List<String>.from(draft.photoPaths);
    _scanPaths = List<String>.from(draft.scanPaths);
    _qcSignaturePath = draft.qcSignaturePath;
    _qcManagerSignaturePath = draft.qcManagerSignaturePath;

    for (final controller in _autosaveControllers) {
      controller.addListener(_saveDraftSilently);
    }
  }

  @override
  void dispose() {
    for (final controller in _autosaveControllers) {
      controller.removeListener(_saveDraftSilently);
      controller.dispose();
    }
    super.dispose();
  }

  MaterialDraft _currentDraftPayload() {
    return _draft.copyWith(
      materialTag: _materialTagController.text,
      description: _descriptionController.text,
      vendor: _vendorController.text,
      poNumber: _poNumberController.text,
      productType: _productTypeController.text,
      specificationPrefix: _specificationPrefixController.text,
      gradeType: _gradeTypeController.text,
      fittingStandard: _fittingStandardController.text,
      fittingSuffix: _fittingSuffixController.text,
      heatNumber: _heatNumberController.text,
      quantity: _quantityController.text,
      thickness1: _thickness1Controller.text,
      width: _widthController.text,
      length: _lengthController.text,
      diameter: _diameterController.text,
      diameterType: _diameterTypeController.text,
      unitSystem: _unitSystem,
      includesB16Data: _includesB16Data,
      b16Size: _b16SizeController.text,
      visualInspectionAcceptable: _visualInspectionAcceptable,
      surfaceFinish: _surfaceFinishController.text,
      surfaceFinishReading: _surfaceFinishReadingController.text,
      surfaceFinishUnit: _customization.surfaceFinishUnit,
      markings: _markingsController.text,
      markingAcceptable: _markingAcceptable,
      markingAcceptableNa: _markingAcceptableNa,
      mtrAcceptable: _mtrAcceptable,
      mtrAcceptableNa: _mtrAcceptableNa,
      comments: _commentsController.text,
      acceptanceStatus: _acceptanceStatus,
      qcInspectorName: _qcInspectorController.text,
      qcManagerName: _qcManagerController.text,
      qcSignaturePath: _qcSignaturePath,
      qcManagerSignaturePath: _qcManagerSignaturePath,
      photoPaths: _photoPaths,
      scanPaths: _scanPaths,
      signatureApplied: _signatureApplied,
    );
  }

  void _saveDraftSilently() {
    widget.appState.saveDraft(_currentDraftPayload());
  }

  Future<void> _saveDraftNow() {
    return widget.appState.saveDraft(_currentDraftPayload());
  }

  Future<void> _addPhoto(PhotoCaptureSource source) async {
    if (_photoPaths.length >= 4) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A material can keep up to 4 photos.')),
      );
      return;
    }

    final addedPath = await widget.appState.mediaService.addPhoto(
      jobNumber: widget.appState.jobById(widget.jobId).jobNumber,
      materialLabel: _materialLabelForFiles,
      source: source,
      nextIndex: _photoPaths.length + 1,
    );
    if (addedPath == null || !mounted) {
      return;
    }
    setState(() {
      _photoPaths = [..._photoPaths, addedPath];
    });
    await _saveDraftNow();
  }

  Future<void> _addScans() async {
    final remainingSlots = 8 - _scanPaths.length;
    if (remainingSlots <= 0) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A material can keep up to 8 scans.')),
      );
      return;
    }

    final addedPaths = await widget.appState.mediaService.addScans(
      jobNumber: widget.appState.jobById(widget.jobId).jobNumber,
      materialLabel: _materialLabelForFiles,
      startingIndex: _scanPaths.length + 1,
      remainingSlots: remainingSlots,
    );
    if (addedPaths.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _scanPaths = [..._scanPaths, ...addedPaths];
    });
    await _saveDraftNow();
  }

  Future<void> _removeMediaAt({
    required bool isPhoto,
    required int index,
  }) async {
    final targetList = isPhoto ? _photoPaths : _scanPaths;
    final path = targetList[index];
    await widget.appState.mediaService.deletePath(path);
    if (!mounted) {
      return;
    }
    setState(() {
      if (isPhoto) {
        _photoPaths = [
          for (var i = 0; i < _photoPaths.length; i++)
            if (i != index) _photoPaths[i],
        ];
      } else {
        _scanPaths = [
          for (var i = 0; i < _scanPaths.length; i++)
            if (i != index) _scanPaths[i],
        ];
      }
    });
    await _saveDraftNow();
  }

  Future<void> _openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type == ResultType.done || !mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _importSignature({required bool forManager}) async {
    final importedPath = await widget.appState.mediaService.importSignature(
      jobNumber: widget.appState.jobById(widget.jobId).jobNumber,
      materialLabel: _materialLabelForFiles,
      targetLabel: forManager ? 'qc_manager' : 'qc_inspector',
    );
    if (importedPath == null || !mounted) {
      return;
    }
    setState(() {
      if (forManager) {
        _qcManagerSignaturePath = importedPath;
      } else {
        _qcSignaturePath = importedPath;
        _signatureApplied = true;
      }
    });
    await _saveDraftNow();
  }

  Future<void> _captureSignature({required bool forManager}) async {
    final pngBytes = await showSignatureCaptureDialog(
      context,
      title: forManager
          ? 'Capture QC manager signature'
          : 'Capture QC inspector signature',
    );
    if (pngBytes == null) {
      return;
    }

    final capturedPath = await widget.appState.mediaService.captureSignature(
      jobNumber: widget.appState.jobById(widget.jobId).jobNumber,
      materialLabel: _materialLabelForFiles,
      targetLabel: forManager ? 'qc_manager' : 'qc_inspector',
      pngBytes: pngBytes,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      if (forManager) {
        _qcManagerSignaturePath = capturedPath;
      } else {
        _qcSignaturePath = capturedPath;
        _signatureApplied = true;
      }
    });
    await _saveDraftNow();
  }

  Future<void> _applySavedInspectorSignature() async {
    final sourcePath = _customization.savedInspectorSignaturePath.trim();
    if (sourcePath.isEmpty) {
      return;
    }
    setState(() {
      _qcSignaturePath = sourcePath;
      _signatureApplied = true;
    });
    await _saveDraftNow();
  }

  Future<void> _clearSignature({required bool forManager}) async {
    setState(() {
      if (forManager) {
        _qcManagerSignaturePath = '';
      } else {
        _qcSignaturePath = '';
        _signatureApplied = false;
      }
    });
    await _saveDraftNow();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.appState.jobById(widget.jobId);
    final showB16 =
        _customization.receiveAsmeB16Parts ||
        _includesB16Data ||
        _b16SizeController.text.trim().isNotEmpty;
    final showSurfaceFinish =
        _customization.surfaceFinishRequired ||
        _surfaceFinishController.text.trim().isNotEmpty ||
        _surfaceFinishReadingController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditingExistingMaterial
              ? '${job.jobNumber} edit material'
              : '${job.jobNumber} draft',
        ),
      ),
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
                    _isEditingExistingMaterial
                        ? 'Edit saved material'
                        : 'Receiving form shell',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditingExistingMaterial
                        ? 'Saved materials now reopen through the same shared form, with edits protected by the draft flow before the material record is updated.'
                        : 'This screen already follows the migration rule that Add Material starts blank while interrupted work remains recoverable through explicit drafts.',
                  ),
                  const SizedBox(height: 18),
                  const _SectionHeader(title: 'Material Identity'),
                  TextField(
                    controller: _materialTagController,
                    decoration: const InputDecoration(
                      labelText: 'Material tag',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vendorController,
                    decoration: const InputDecoration(labelText: 'Vendor'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _poNumberController,
                    decoration: const InputDecoration(labelText: 'PO number'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _heatNumberController,
                    decoration: const InputDecoration(labelText: 'Heat number'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  const SizedBox(height: 12),
                  const _SectionHeader(title: 'Specification'),
                  TextField(
                    controller: _productTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Product type',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _specificationPrefixController,
                    decoration: const InputDecoration(
                      labelText: 'Specification prefix',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _gradeTypeController,
                    decoration: const InputDecoration(labelText: 'Grade type'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fittingStandardController,
                    decoration: const InputDecoration(
                      labelText: 'Fitting standard',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fittingSuffixController,
                    decoration: const InputDecoration(
                      labelText: 'Fitting suffix',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UnitSystem>(
                    initialValue: _unitSystem,
                    decoration: const InputDecoration(labelText: 'Unit system'),
                    items: UnitSystem.values
                        .map(
                          (unitSystem) => DropdownMenuItem<UnitSystem>(
                            value: unitSystem,
                            child: Text(unitSystem.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _unitSystem = value;
                      });
                      _saveDraftSilently();
                    },
                  ),
                  const SizedBox(height: 12),
                  const _SectionHeader(title: 'Dimensions'),
                  TextField(
                    controller: _thickness1Controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Thickness'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _widthController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Width'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lengthController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Length'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _diameterController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Diameter'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _diameterTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Diameter type',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _visualInspectionAcceptable,
                    onChanged: (value) {
                      setState(() {
                        _visualInspectionAcceptable = value;
                      });
                      _saveDraftSilently();
                    },
                    title: const Text('Visual inspection acceptable'),
                  ),
                  if (showB16) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includesB16Data,
                      onChanged: (value) {
                        setState(() {
                          _includesB16Data = value;
                        });
                        _saveDraftSilently();
                      },
                      title: const Text('Include ASME B16 data'),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _b16SizeController,
                      decoration: const InputDecoration(
                        labelText: 'B16 size/details',
                      ),
                    ),
                  ],
                  if (showSurfaceFinish) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _surfaceFinishController,
                      decoration: const InputDecoration(
                        labelText: 'Surface finish',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _surfaceFinishReadingController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            'Actual surface finish reading (${_customization.surfaceFinishUnit})',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const _SectionHeader(title: 'Disposition'),
                  DropdownButtonFormField<String>(
                    initialValue: _acceptanceStatus,
                    decoration: const InputDecoration(
                      labelText: 'Acceptance status',
                    ),
                    items: _acceptanceOptions
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status.toUpperCase()),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _acceptanceStatus = value;
                      });
                      _saveDraftSilently();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _markingsController,
                    decoration: const InputDecoration(labelText: 'Markings'),
                  ),
                  const SizedBox(height: 12),
                  _TriStateChoiceRow(
                    label: 'Marking acceptable',
                    yesSelected: _markingAcceptable && !_markingAcceptableNa,
                    noSelected: !_markingAcceptable && !_markingAcceptableNa,
                    naSelected: _markingAcceptableNa,
                    onYes: () {
                      setState(() {
                        _markingAcceptable = true;
                        _markingAcceptableNa = false;
                      });
                      _saveDraftSilently();
                    },
                    onNo: () {
                      setState(() {
                        _markingAcceptable = false;
                        _markingAcceptableNa = false;
                      });
                      _saveDraftSilently();
                    },
                    onNa: () {
                      setState(() {
                        _markingAcceptable = false;
                        _markingAcceptableNa = true;
                      });
                      _saveDraftSilently();
                    },
                  ),
                  const SizedBox(height: 12),
                  _TriStateChoiceRow(
                    label: 'MTR acceptable',
                    yesSelected: _mtrAcceptable && !_mtrAcceptableNa,
                    noSelected: !_mtrAcceptable && !_mtrAcceptableNa,
                    naSelected: _mtrAcceptableNa,
                    onYes: () {
                      setState(() {
                        _mtrAcceptable = true;
                        _mtrAcceptableNa = false;
                      });
                      _saveDraftSilently();
                    },
                    onNo: () {
                      setState(() {
                        _mtrAcceptable = false;
                        _mtrAcceptableNa = false;
                      });
                      _saveDraftSilently();
                    },
                    onNa: () {
                      setState(() {
                        _mtrAcceptable = false;
                        _mtrAcceptableNa = true;
                      });
                      _saveDraftSilently();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentsController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Comments'),
                  ),
                  const SizedBox(height: 12),
                  const _SectionHeader(title: 'QC Defaults'),
                  TextField(
                    controller: _qcInspectorController,
                    decoration: const InputDecoration(
                      labelText: 'QC inspector printed name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _qcManagerController,
                    decoration: const InputDecoration(
                      labelText: 'QC manager printed name',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (_customization.hasSavedInspectorSignature &&
                          _customization.savedInspectorSignaturePath
                              .trim()
                              .isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: _applySavedInspectorSignature,
                          icon: const Icon(Icons.draw_outlined),
                          label: Text(
                            _qcInspectorController.text.trim().isEmpty
                                ? 'Apply Saved Signature'
                                : 'Apply Saved Signature for ${_qcInspectorController.text.trim()}',
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _captureSignature(forManager: false),
                        icon: const Icon(Icons.draw_outlined),
                        label: Text(
                          _qcSignaturePath.trim().isEmpty
                              ? 'Capture Inspector Signature'
                              : 'Re-sign Inspector',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _importSignature(forManager: false),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Import Inspector Signature'),
                      ),
                      if (_qcSignaturePath.trim().isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _openFile(_qcSignaturePath),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Preview Inspector Signature'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _clearSignature(forManager: false),
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Clear Inspector Signature'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _captureSignature(forManager: true),
                        icon: const Icon(Icons.draw_outlined),
                        label: Text(
                          _qcManagerSignaturePath.trim().isEmpty
                              ? 'Capture Manager Signature'
                              : 'Re-sign Manager',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _importSignature(forManager: true),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Import Manager Signature'),
                      ),
                      if (_qcManagerSignaturePath.trim().isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _openFile(_qcManagerSignaturePath),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Preview Manager Signature'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _clearSignature(forManager: true),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Clear Manager Signature'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _qcSignaturePath.trim().isNotEmpty
                        ? 'Inspector signature attached.'
                        : 'No inspector signature attached to this draft yet.',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _qcManagerSignaturePath.trim().isNotEmpty
                        ? 'Manager signature attached.'
                        : 'No manager signature attached yet.',
                  ),
                  const SizedBox(height: 18),
                  const _SectionHeader(title: 'Media'),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final source =
                                await showModalBottomSheet<PhotoCaptureSource>(
                                  context: context,
                                  builder: (context) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(
                                            Icons.photo_camera_outlined,
                                          ),
                                          title: const Text('Take Photo'),
                                          onTap: () {
                                            Navigator.pop(
                                              context,
                                              PhotoCaptureSource.camera,
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.photo_library_outlined,
                                          ),
                                          title: const Text(
                                            'Choose From Gallery',
                                          ),
                                          onTap: () {
                                            Navigator.pop(
                                              context,
                                              PhotoCaptureSource.gallery,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                            if (source == null) {
                              return;
                            }
                            await _addPhoto(source);
                          },
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text('Add Photo (${_photoPaths.length}/4)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addScans,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text('Add Scans (${_scanPaths.length}/8)'),
                        ),
                      ),
                    ],
                  ),
                  if (_photoPaths.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Photos',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (var index = 0; index < _photoPaths.length; index++)
                      _MediaListTile(
                        title: _fileNameOf(_photoPaths[index]),
                        onOpen: () => _openFile(_photoPaths[index]),
                        onRemove: () =>
                            _removeMediaAt(isPhoto: true, index: index),
                      ),
                  ],
                  if (_scanPaths.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Scans',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (var index = 0; index < _scanPaths.length; index++)
                      _MediaListTile(
                        title: _fileNameOf(_scanPaths[index]),
                        onOpen: () => _openFile(_scanPaths[index]),
                        onRemove: () =>
                            _removeMediaAt(isPhoto: false, index: index),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () async {
              await _saveDraftNow();
              await widget.appState.completeDraft(
                widget.appState.draftById(widget.draftId),
              );
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isEditingExistingMaterial
                        ? 'Material updated from draft.'
                        : 'Material saved from draft.',
                  ),
                ),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text(
              _isEditingExistingMaterial
                  ? 'Update Material'
                  : 'Complete Material',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await _saveDraftNow();
              if (!context.mounted) {
                return;
              }
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save_as_outlined),
            label: const Text('Save Draft and Close'),
          ),
        ],
      ),
    );
  }
}

String _fileNameOf(String path) {
  return path.split(RegExp(r'[\\/]')).last;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TriStateChoiceRow extends StatelessWidget {
  const _TriStateChoiceRow({
    required this.label,
    required this.yesSelected,
    required this.noSelected,
    required this.naSelected,
    required this.onYes,
    required this.onNo,
    required this.onNa,
  });

  final String label;
  final bool yesSelected;
  final bool noSelected;
  final bool naSelected;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final VoidCallback onNa;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Yes'),
              selected: yesSelected,
              onSelected: (_) => onYes(),
            ),
            ChoiceChip(
              label: const Text('No'),
              selected: noSelected,
              onSelected: (_) => onNo(),
            ),
            ChoiceChip(
              label: const Text('N/A'),
              selected: naSelected,
              onSelected: (_) => onNa(),
            ),
          ],
        ),
      ],
    );
  }
}

class _MediaListTile extends StatelessWidget {
  const _MediaListTile({
    required this.title,
    required this.onOpen,
    required this.onRemove,
  });

  final String title;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        onTap: onOpen,
        trailing: IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ),
    );
  }
}
