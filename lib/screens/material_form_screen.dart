import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../app/material_guardian_state.dart';
import '../app/models.dart';
import '../services/material_media_service.dart';
import '../services/storage_utils.dart';
import '../util/formatting.dart';
import '../widgets/in_app_camera_capture_overlay.dart';
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
  static const _descriptionMaxLength = 40;
  static const _poNumberMaxLength = 20;
  static const _vendorMaxLength = 20;
  static const _quantityMaxLength = 6;
  static const _gradeTypeMaxLength = 12;
  static const _dimensionValueMaxLength = 10;
  static const _qcNameMaxLength = 20;

  static const List<String> _productTypeOptions = [
    'Tube',
    'Pipe',
    'Plate',
    'Fitting',
    'Bar',
    'Other',
  ];
  static const List<String> _specificationPrefixOptions = ['', 'A', 'SA'];
  static const List<String> _fittingStandardOptions = ['N/A', 'B16'];
  static const List<String> _fittingSuffixOptions = ['5', '9', '11', '34'];
  static const List<String> _diameterTypeOptions = ['', 'O.D.', 'I.D.'];
  static const List<String> _surfaceFinishOptions = [
    '',
    'SF1',
    'SF2',
    'SF3',
    'SF4',
  ];

  late final MaterialDraft _initialDraft;
  late final TextEditingController _materialTagController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _vendorController;
  late final TextEditingController _poNumberController;
  late final TextEditingController _productTypeController;
  late final TextEditingController _specificationPrefixController;
  late final TextEditingController _gradeTypeController;
  late final TextEditingController _fittingStandardController;
  late final TextEditingController _fittingSuffixController;
  late final TextEditingController _quantityController;
  late final TextEditingController _thickness1Controller;
  late final TextEditingController _thickness2Controller;
  late final TextEditingController _thickness3Controller;
  late final TextEditingController _thickness4Controller;
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
  late DateTime _qcInspectorDate;
  late DateTime _qcManagerDate;
  late UnitSystem _unitSystem;
  late bool _signatureApplied;
  late bool _visualInspectionAcceptable;
  late bool _markingAcceptable;
  late bool _markingAcceptableNa;
  late bool _markingSelected;
  late bool _mtrAcceptable;
  late bool _mtrAcceptableNa;
  late bool _mtrSelected;
  late String _acceptanceStatus;
  late String _materialApproval;
  late List<String> _photoPaths;
  late List<String> _scanPaths;
  late String _qcSignaturePath;
  late String _qcManagerSignaturePath;
  var _allowImmediatePop = false;

  static const List<String> _acceptanceOptions = ['accept', 'reject'];
  static const List<String> _materialApprovalOptions = ['approved', 'rejected'];
  static final List<TextInputFormatter> _surfaceFinishReadingInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
  ];

  static List<TextInputFormatter> _maxLengthFormatters(int maxLength) => [
    LengthLimitingTextInputFormatter(maxLength),
  ];

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
    _quantityController,
    _thickness1Controller,
    _thickness2Controller,
    _thickness3Controller,
    _thickness4Controller,
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
    _initialDraft = draft;
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
    _quantityController = TextEditingController(text: draft.quantity);
    _thickness1Controller = TextEditingController(text: draft.thickness1);
    _thickness2Controller = TextEditingController(text: draft.thickness2);
    _thickness3Controller = TextEditingController(text: draft.thickness3);
    _thickness4Controller = TextEditingController(text: draft.thickness4);
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
    _qcInspectorDate = draft.qcInspectorDate;
    _qcManagerDate = draft.qcManagerDate;
    _unitSystem = draft.unitSystem;
    _signatureApplied = draft.signatureApplied;
    _visualInspectionAcceptable = draft.visualInspectionAcceptable;
    _markingAcceptable = draft.markingAcceptable;
    _markingAcceptableNa = draft.markingAcceptableNa;
    _markingSelected = draft.markingSelected;
    _mtrAcceptable = draft.mtrAcceptable;
    _mtrAcceptableNa = draft.mtrAcceptableNa;
    _mtrSelected = draft.mtrSelected;
    _acceptanceStatus = draft.acceptanceStatus;
    _materialApproval = draft.materialApproval;
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
      heatNumber: '',
      quantity: _quantityController.text,
      thickness1: _thickness1Controller.text,
      thickness2: _thickness2Controller.text,
      thickness3: _thickness3Controller.text,
      thickness4: _thickness4Controller.text,
      width: _widthController.text,
      length: _lengthController.text,
      diameter: _diameterController.text,
      diameterType: _diameterTypeController.text,
      unitSystem: _unitSystem,
      includesB16Data:
          _customization.receiveAsmeB16Parts ||
          _fittingStandardController.text.trim() == 'B16' ||
          _fittingSuffixController.text.trim().isNotEmpty ||
          _b16SizeController.text.trim().isNotEmpty,
      b16Size: _b16SizeController.text,
      visualInspectionAcceptable: _visualInspectionAcceptable,
      surfaceFinish: _surfaceFinishController.text,
      surfaceFinishReading: _surfaceFinishReadingController.text,
      surfaceFinishUnit: _customization.surfaceFinishUnit,
      markings: _markingsController.text,
      markingAcceptable: _markingAcceptable,
      markingAcceptableNa: _markingAcceptableNa,
      markingSelected: _markingSelected,
      mtrAcceptable: _mtrAcceptable,
      mtrAcceptableNa: _mtrAcceptableNa,
      mtrSelected: _mtrSelected,
      comments: _commentsController.text,
      acceptanceStatus: _acceptanceStatus,
      materialApproval: _materialApproval,
      qcInspectorName: _qcInspectorController.text,
      qcInspectorDate: _qcInspectorDate,
      qcManagerName: _qcManagerController.text,
      qcManagerDate: _qcManagerDate,
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

  String _formatDateForField(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$month/$day/${local.year}';
  }

  Future<void> _pickQcDate({required bool forManager}) async {
    final initialDate = forManager ? _qcManagerDate : _qcInspectorDate;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || selectedDate == null) {
      return;
    }
    setState(() {
      if (forManager) {
        _qcManagerDate = selectedDate;
      } else {
        _qcInspectorDate = selectedDate;
      }
    });
    await _saveDraftNow();
  }

  bool get _hasDraftChanges =>
      _currentDraftPayload().toJson().toString() !=
      _initialDraft.toJson().toString();

  Future<void> _handleBackNavigation() async {
    if (_allowImmediatePop || !_hasDraftChanges) {
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      return;
    }

    final action = await _showExitReceivingReportDialog(context);
    if (!mounted || action == null || action == _MaterialFormExitAction.keep) {
      return;
    }

    if (action == _MaterialFormExitAction.leave) {
      await _saveDraftNow();
    } else if (action == _MaterialFormExitAction.deleteDraft) {
      await widget.appState.deleteDraft(widget.draftId);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _allowImmediatePop = true;
    });
    Navigator.pop(context);
  }

  Future<String?> _addPhotoOnce(PhotoCaptureSource source) async {
    if (_photoPaths.length >= 4) {
      _showMessage('A material can keep up to 4 photos.');
      return null;
    }

    final addedPath = await widget.appState.mediaService.addPhoto(
      jobNumber: widget.appState.jobById(widget.jobId).jobNumber,
      materialLabel: _materialLabelForFiles,
      source: source,
      nextIndex: _photoPaths.length + 1,
    );
    if (addedPath == null || !mounted) {
      return null;
    }
    setState(() {
      _photoPaths = [..._photoPaths, addedPath];
    });
    await _saveDraftNow();
    return addedPath;
  }

  Future<void> _importScans() async {
    final remainingSlots = 8 - _scanPaths.length;
    if (remainingSlots <= 0) {
      _showMessage('A material can keep up to 8 scans.');
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

  Future<void> _replacePhotoAt(int index) async {
    final source = await _showPhotoSourceSheet(context);
    if (!mounted || source == null) {
      return;
    }

    if (source == PhotoCaptureSource.camera) {
      await _capturePhotosInApp(replaceIndex: index);
      return;
    }

    final replacementPath = await widget.appState.mediaService.addPhoto(
      jobNumber: widget.appState.jobById(widget.jobId).jobNumber,
      materialLabel: _materialLabelForFiles,
      source: source,
      nextIndex: index + 1,
    );
    if (replacementPath == null || !mounted) {
      return;
    }
    final resolvedReplacementPath = replacementPath;

    final previousPath = _photoPaths[index];
    await widget.appState.mediaService.deletePath(previousPath);
    if (!mounted) {
      return;
    }

    setState(() {
      final nextPaths = [..._photoPaths];
      nextPaths[index] = resolvedReplacementPath;
      _photoPaths = nextPaths;
    });
    await _saveDraftNow();
  }

  Future<void> _replaceScanAt(int index) async {
    final source = await _showScanSourceSheet(context);
    if (!mounted || source == null) {
      return;
    }

    String? replacementPath;
    if (source == _ScanSource.camera) {
      await _scanDocumentsWithDeviceScanner(replaceIndex: index);
      return;
    } else {
      final importedPaths = await widget.appState.mediaService.addScans(
        jobNumber: widget.appState.jobById(widget.jobId).jobNumber,
        materialLabel: _materialLabelForFiles,
        startingIndex: index + 1,
        remainingSlots: 1,
      );
      if (importedPaths.isNotEmpty) {
        replacementPath = importedPaths.first;
      }
    }

    if (replacementPath == null || !mounted) {
      return;
    }
    final resolvedReplacementPath = replacementPath;

    final previousPath = _scanPaths[index];
    await widget.appState.mediaService.deletePath(previousPath);
    if (!mounted) {
      return;
    }

    setState(() {
      final nextPaths = [..._scanPaths];
      nextPaths[index] = resolvedReplacementPath;
      _scanPaths = nextPaths;
    });
    await _saveDraftNow();
  }

  Future<void> _handleExistingMediaTap({
    required bool isPhoto,
    required int index,
  }) async {
    final action = await _showMediaOptionsDialog(context);
    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _MediaAction.retake:
        if (isPhoto) {
          await _replacePhotoAt(index);
        } else {
          await _replaceScanAt(index);
        }
        return;
      case _MediaAction.delete:
        await _removeMediaAt(isPhoto: isPhoto, index: index);
        return;
      case _MediaAction.cancel:
        return;
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<List<CapturedMediaItem>?> _showInAppCaptureOverlay({
    required String title,
    required int maxCount,
    required int currentCount,
    required String acceptLabel,
    int? replaceIndex,
  }) {
    return Navigator.of(context).push<List<CapturedMediaItem>>(
      MaterialPageRoute<List<CapturedMediaItem>>(
        builder: (context) {
          return InAppCameraCaptureOverlay(
            title: title,
            maxCount: maxCount,
            currentCount: currentCount,
            replaceIndex: replaceIndex == null ? null : replaceIndex + 1,
            acceptLabel: acceptLabel,
          );
        },
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _capturePhotosInApp({int? replaceIndex}) async {
    final captures = await _showInAppCaptureOverlay(
      title: 'Material Photos',
      maxCount: 4,
      currentCount: _photoPaths.length,
      replaceIndex: replaceIndex,
      acceptLabel: 'Use Photo',
    );
    if (!mounted || captures == null || captures.isEmpty) {
      return;
    }

    final jobNumber = widget.appState.jobById(widget.jobId).jobNumber;
    final nextPaths = [..._photoPaths];
    for (final capture in captures) {
      final savedPath = await widget.appState.mediaService.saveCapturedPhoto(
        sourcePath: capture.tempPath,
        jobNumber: jobNumber,
        materialLabel: _materialLabelForFiles,
        nextIndex: capture.index,
      );
      final targetIndex = capture.index - 1;
      if (targetIndex < nextPaths.length) {
        final previousPath = nextPaths[targetIndex];
        if (previousPath != savedPath) {
          await widget.appState.mediaService.deletePath(previousPath);
        }
        nextPaths[targetIndex] = savedPath;
      } else {
        nextPaths.add(savedPath);
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _photoPaths = nextPaths;
    });
    await _saveDraftNow();
  }

  Future<void> _captureScansInApp({int? replaceIndex}) async {
    final captures = await _showInAppCaptureOverlay(
      title: 'MTR/CoC Scans',
      maxCount: 8,
      currentCount: _scanPaths.length,
      replaceIndex: replaceIndex,
      acceptLabel: 'Use Scan',
    );
    if (!mounted || captures == null || captures.isEmpty) {
      return;
    }

    final jobNumber = widget.appState.jobById(widget.jobId).jobNumber;
    final nextPaths = [..._scanPaths];
    for (final capture in captures) {
      final savedPath = await widget.appState.mediaService.saveCapturedScan(
        sourcePath: capture.tempPath,
        jobNumber: jobNumber,
        materialLabel: _materialLabelForFiles,
        nextIndex: capture.index,
      );
      final targetIndex = capture.index - 1;
      if (targetIndex < nextPaths.length) {
        final previousPath = nextPaths[targetIndex];
        if (previousPath != savedPath) {
          await widget.appState.mediaService.deletePath(previousPath);
        }
        nextPaths[targetIndex] = savedPath;
      } else {
        nextPaths.add(savedPath);
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _scanPaths = nextPaths;
    });
    await _saveDraftNow();
  }

  Future<void> _scanDocumentsWithDeviceScanner({int? replaceIndex}) async {
    final remainingSlots = replaceIndex == null ? 8 - _scanPaths.length : 1;
    if (remainingSlots <= 0) {
      _showMessage('A material can keep up to 8 scans.');
      return;
    }

    try {
      final scannedPaths = await widget.appState.mediaService
          .scanDocumentsWithDeviceScanner(
            jobNumber: widget.appState.jobById(widget.jobId).jobNumber,
            materialLabel: _materialLabelForFiles,
            nextIndex:
                replaceIndex == null ? _scanPaths.length + 1 : replaceIndex + 1,
            pageLimit: remainingSlots,
          );
      if (!mounted || scannedPaths.isEmpty) {
        return;
      }

      if (replaceIndex != null) {
        final previousPath = _scanPaths[replaceIndex];
        final replacementPath = scannedPaths.first;
        if (previousPath != replacementPath) {
          await widget.appState.mediaService.deletePath(previousPath);
        }
        if (!mounted) {
          return;
        }
        setState(() {
          final nextPaths = [..._scanPaths];
          nextPaths[replaceIndex] = replacementPath;
          _scanPaths = nextPaths;
        });
      } else {
        setState(() {
          _scanPaths = [..._scanPaths, ...scannedPaths];
        });
      }
      await _saveDraftNow();
      if (replaceIndex == null && mounted && _scanPaths.length < 8) {
        final scanAnother = await _showScanAnotherDialog(context);
        if (scanAnother == true && mounted) {
          await _scanDocumentsWithDeviceScanner();
        }
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(
        'Document scanner unavailable on this device right now. Falling back to camera capture.',
      );
      await _captureScansInApp(replaceIndex: replaceIndex);
    }
  }

  Future<void> _handlePhotoAction() async {
    final source = await _showPhotoSourceSheet(context);
    if (!mounted || source == null) {
      return;
    }
    if (source == PhotoCaptureSource.camera) {
      await _capturePhotosInApp();
      return;
    }
    await _addPhotoOnce(source);
  }

  Future<void> _handleScanAction() async {
    final source = await _showScanSourceSheet(context);
    if (!mounted || source == null) {
      return;
    }
    if (source == _ScanSource.importFiles) {
      await _importScans();
      return;
    }
    await _scanDocumentsWithDeviceScanner();
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

  Future<void> _saveMaterialReceiving() async {
    try {
      final currentDraft = _currentDraftPayload();
      await widget.appState.saveDraft(currentDraft);
      await widget.appState.completeDraft(currentDraft);
      if (!mounted) {
        return;
      }
      setState(() {
        _allowImmediatePop = true;
      });
      _showMessage(
        _isEditingExistingMaterial
            ? 'Material receiving updated.'
            : 'Material receiving saved.',
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Save failed'),
            content: Text(error.toString()),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.appState.jobById(widget.jobId);
    final baseListPadding = screenListPadding(context);
    final listPadding = baseListPadding.copyWith(
      bottom: baseListPadding.bottom + 96,
    );
    final showB16 =
        _customization.receiveAsmeB16Parts ||
        _fittingStandardController.text.trim() == 'B16' ||
        _fittingSuffixController.text.trim().isNotEmpty ||
        _b16SizeController.text.trim().isNotEmpty;
    final showSurfaceFinish =
        _customization.surfaceFinishRequired ||
        _surfaceFinishController.text.trim().isNotEmpty ||
        _surfaceFinishReadingController.text.trim().isNotEmpty;
    final canPopDirectly = _allowImmediatePop || !_hasDraftChanges;

    return PopScope(
      canPop: canPopDirectly,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: _handleBackNavigation,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(job.jobNumber),
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          minimum: const EdgeInsets.only(bottom: 16),
          child: centeredContent(
            child: ListView(
              padding: listPadding,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECEIVING INSPECTION\nREPORT',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                height: 1.15,
                              ),
                        ),
                        if (_isEditingExistingMaterial) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Editing saved material',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        TextField(
                          controller: _descriptionController,
                          inputFormatters: _maxLengthFormatters(
                            _descriptionMaxLength,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Material Description',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _poNumberController,
                                inputFormatters: _maxLengthFormatters(
                                  _poNumberMaxLength,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'PO #',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _vendorController,
                                inputFormatters: _maxLengthFormatters(
                                  _vendorMaxLength,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Vendor',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stackFields = constraints.maxWidth < 560;
                            if (stackFields) {
                              return Column(
                                children: [
                                  TextField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: _maxLengthFormatters(
                                      _quantityMaxLength,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Qty',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _LabeledDropdownField(
                                    value: _productTypeController.text,
                                    labelText: 'Product',
                                    options: _optionsWithCurrent(
                                      _productTypeController.text,
                                      _productTypeOptions,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _productTypeController.text =
                                            value ?? '';
                                      });
                                      _saveDraftSilently();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _LabeledDropdownField(
                                    value:
                                        _specificationPrefixController.text,
                                    labelText: 'A/SA',
                                    options: _optionsWithCurrent(
                                      _specificationPrefixController.text,
                                      _specificationPrefixOptions,
                                    ),
                                    labelBuilder: (value) =>
                                        value.isEmpty ? 'Blank' : value,
                                    onChanged: (value) {
                                      setState(() {
                                        _specificationPrefixController.text =
                                            value ?? '';
                                      });
                                      _saveDraftSilently();
                                    },
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: _maxLengthFormatters(
                                      _quantityMaxLength,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Qty',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: _LabeledDropdownField(
                                    value: _productTypeController.text,
                                    labelText: 'Product',
                                    options: _optionsWithCurrent(
                                      _productTypeController.text,
                                      _productTypeOptions,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _productTypeController.text =
                                            value ?? '';
                                      });
                                      _saveDraftSilently();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _LabeledDropdownField(
                                    value:
                                        _specificationPrefixController.text,
                                    labelText: 'A/SA',
                                    options: _optionsWithCurrent(
                                      _specificationPrefixController.text,
                                      _specificationPrefixOptions,
                                    ),
                                    labelBuilder: (value) =>
                                        value.isEmpty ? 'Blank' : value,
                                    onChanged: (value) {
                                      setState(() {
                                        _specificationPrefixController.text =
                                            value ?? '';
                                      });
                                      _saveDraftSilently();
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _gradeTypeController,
                          inputFormatters: _maxLengthFormatters(
                            _gradeTypeMaxLength,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Spec/Grade',
                          ),
                        ),
                        if (showB16) ...[
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stackFields = constraints.maxWidth < 560;
                              if (stackFields) {
                                return Column(
                                  children: [
                                    _LabeledDropdownField(
                                      value: _fittingStandardController.text,
                                      labelText: 'Fitting',
                                      options: _optionsWithCurrent(
                                        _fittingStandardController.text,
                                        _fittingStandardOptions,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _fittingStandardController.text =
                                              value ?? 'N/A';
                                          if (_fittingStandardController.text !=
                                              'B16') {
                                            _fittingSuffixController.text = '';
                                          }
                                        });
                                        _saveDraftSilently();
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _LabeledDropdownField(
                                      value: _fittingSuffixController.text,
                                      labelText: 'B16 Type',
                                      options: _optionsWithCurrent(
                                        _fittingSuffixController.text,
                                        _fittingSuffixOptions,
                                      ),
                                      enabled:
                                          _fittingStandardController.text ==
                                          'B16',
                                      labelBuilder: (value) =>
                                          value.isEmpty ? 'N/A' : value,
                                      onChanged: (value) {
                                        setState(() {
                                          _fittingSuffixController.text =
                                              value ?? '';
                                        });
                                        _saveDraftSilently();
                                      },
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(
                                    child: _LabeledDropdownField(
                                      value: _fittingStandardController.text,
                                      labelText: 'Fitting',
                                      options: _optionsWithCurrent(
                                        _fittingStandardController.text,
                                        _fittingStandardOptions,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _fittingStandardController.text =
                                              value ?? 'N/A';
                                          if (_fittingStandardController.text !=
                                              'B16') {
                                            _fittingSuffixController.text = '';
                                          }
                                        });
                                        _saveDraftSilently();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _LabeledDropdownField(
                                      value: _fittingSuffixController.text,
                                      labelText: 'B16 Type',
                                      options: _optionsWithCurrent(
                                        _fittingSuffixController.text,
                                        _fittingSuffixOptions,
                                      ),
                                      enabled:
                                          _fittingStandardController.text ==
                                          'B16',
                                      labelBuilder: (value) =>
                                          value.isEmpty ? 'N/A' : value,
                                      onChanged: (value) {
                                        setState(() {
                                          _fittingSuffixController.text =
                                              value ?? '';
                                        });
                                        _saveDraftSilently();
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        const _SectionHeader(title: 'Dimensions'),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: UnitSystem.values
                              .map(
                                (unitSystem) => ChoiceChip(
                                  label: Text(unitSystem.label),
                                  selected: _unitSystem == unitSystem,
                                  onSelected: (_) {
                                    setState(() {
                                      _unitSystem = unitSystem;
                                    });
                                    _saveDraftSilently();
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stackFields = constraints.maxWidth < 700;
                            Widget buildThicknessField(
                              TextEditingController controller,
                              String label,
                            ) {
                              return TextField(
                                controller: controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: _maxLengthFormatters(
                                  _dimensionValueMaxLength,
                                ),
                                decoration: InputDecoration(labelText: label),
                              );
                            }

                            if (stackFields) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: buildThicknessField(
                                          _thickness1Controller,
                                          'TH 1',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: buildThicknessField(
                                          _thickness2Controller,
                                          'TH 2',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: buildThicknessField(
                                          _thickness3Controller,
                                          'TH 3',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: buildThicknessField(
                                          _thickness4Controller,
                                          'TH 4',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: buildThicknessField(
                                    _thickness1Controller,
                                    'TH 1',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: buildThicknessField(
                                    _thickness2Controller,
                                    'TH 2',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: buildThicknessField(
                                    _thickness3Controller,
                                    'TH 3',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: buildThicknessField(
                                    _thickness4Controller,
                                    'TH 4',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stackFields = constraints.maxWidth < 700;
                            if (stackFields) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _widthController,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          inputFormatters: _maxLengthFormatters(
                                            _dimensionValueMaxLength,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'Width',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _lengthController,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          inputFormatters: _maxLengthFormatters(
                                            _dimensionValueMaxLength,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'Length',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _diameterController,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          inputFormatters: _maxLengthFormatters(
                                            _dimensionValueMaxLength,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'Diameter',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _LabeledDropdownField(
                                          value:
                                              _diameterTypeController.text,
                                          labelText: 'ID/OD',
                                          options: _optionsWithCurrent(
                                            _diameterTypeController.text,
                                            _diameterTypeOptions,
                                          ),
                                          labelBuilder: (value) =>
                                              value.isEmpty ? 'None' : value,
                                          onChanged: (value) {
                                            setState(() {
                                              _diameterTypeController.text =
                                                  value ?? '';
                                            });
                                            _saveDraftSilently();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _widthController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: _maxLengthFormatters(
                                      _dimensionValueMaxLength,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Width',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _lengthController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: _maxLengthFormatters(
                                      _dimensionValueMaxLength,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Length',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _diameterController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: _maxLengthFormatters(
                                      _dimensionValueMaxLength,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Diameter',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _LabeledDropdownField(
                                    value: _diameterTypeController.text,
                                    labelText: 'ID/OD',
                                    options: _optionsWithCurrent(
                                      _diameterTypeController.text,
                                      _diameterTypeOptions,
                                    ),
                                    labelBuilder: (value) =>
                                        value.isEmpty ? 'None' : value,
                                    onChanged: (value) {
                                      setState(() {
                                        _diameterTypeController.text =
                                            value ?? '';
                                      });
                                      _saveDraftSilently();
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _BinaryChoiceRow(
                          label: 'Visual inspection acceptable',
                          yesSelected: _visualInspectionAcceptable,
                          onYes: () {
                            setState(() {
                              _visualInspectionAcceptable = true;
                            });
                            _saveDraftSilently();
                          },
                          onNo: () {
                            setState(() {
                              _visualInspectionAcceptable = false;
                            });
                            _saveDraftSilently();
                          },
                        ),
                        if (showB16) ...[
                          const SizedBox(height: 12),
                          _LabeledDropdownField(
                            value: _b16SizeController.text,
                            labelText: 'B16 Dimensions',
                            options: _optionsWithCurrent(
                              _b16SizeController.text,
                              const ['', 'Yes', 'No'],
                            ),
                            labelBuilder: (value) =>
                                value.isEmpty ? 'N/A' : value,
                            onChanged: (value) {
                              setState(() {
                                _b16SizeController.text = value ?? '';
                              });
                              _saveDraftSilently();
                            },
                          ),
                        ],
                        if (showSurfaceFinish) ...[
                          const SizedBox(height: 12),
                          _LabeledDropdownField(
                            value: _surfaceFinishController.text,
                            labelText: 'Surface Finish',
                            options: _optionsWithCurrent(
                              _surfaceFinishController.text,
                              _surfaceFinishOptions,
                            ),
                            labelBuilder: (value) =>
                                value.isEmpty ? 'N/A' : value,
                            onChanged: (value) {
                              setState(() {
                                _surfaceFinishController.text = value ?? '';
                              });
                              _saveDraftSilently();
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _surfaceFinishReadingController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters:
                                      _surfaceFinishReadingInputFormatters,
                                  decoration: const InputDecoration(
                                    labelText: 'Actual Surface Finish Reading',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _customization.surfaceFinishUnit,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                        TextField(
                          controller: _markingsController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Actual Markings',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _TriStateChoiceRow(
                          label: 'Marking acceptable to Code/Standard',
                          hasSelection: _markingSelected,
                          yesSelected:
                              _markingSelected &&
                              _markingAcceptable &&
                              !_markingAcceptableNa,
                          noSelected:
                              _markingSelected &&
                              !_markingAcceptable &&
                              !_markingAcceptableNa,
                          naSelected: _markingSelected && _markingAcceptableNa,
                          onYes: () {
                            setState(() {
                              _markingAcceptable = true;
                              _markingAcceptableNa = false;
                              _markingSelected = true;
                            });
                            _saveDraftSilently();
                          },
                          onNo: () {
                            setState(() {
                              _markingAcceptable = false;
                              _markingAcceptableNa = false;
                              _markingSelected = true;
                            });
                            _saveDraftSilently();
                          },
                          onNa: () {
                            setState(() {
                              _markingAcceptable = false;
                              _markingAcceptableNa = true;
                              _markingSelected = true;
                            });
                            _saveDraftSilently();
                          },
                          onClear: () {
                            setState(() {
                              _markingAcceptable = false;
                              _markingAcceptableNa = false;
                              _markingSelected = false;
                            });
                            _saveDraftSilently();
                          },
                        ),
                        const SizedBox(height: 12),
                        _TriStateChoiceRow(
                          label: 'MTR/CoC acceptable to specification',
                          hasSelection: _mtrSelected,
                          yesSelected:
                              _mtrSelected &&
                              _mtrAcceptable &&
                              !_mtrAcceptableNa,
                          noSelected:
                              _mtrSelected &&
                              !_mtrAcceptable &&
                              !_mtrAcceptableNa,
                          naSelected: _mtrSelected && _mtrAcceptableNa,
                          onYes: () {
                            setState(() {
                              _mtrAcceptable = true;
                              _mtrAcceptableNa = false;
                              _mtrSelected = true;
                            });
                            _saveDraftSilently();
                          },
                          onNo: () {
                            setState(() {
                              _mtrAcceptable = false;
                              _mtrAcceptableNa = false;
                              _mtrSelected = true;
                            });
                            _saveDraftSilently();
                          },
                          onNa: () {
                            setState(() {
                              _mtrAcceptable = false;
                              _mtrAcceptableNa = true;
                              _mtrSelected = true;
                            });
                            _saveDraftSilently();
                          },
                          onClear: () {
                            setState(() {
                              _mtrAcceptable = false;
                              _mtrAcceptableNa = false;
                              _mtrSelected = false;
                            });
                            _saveDraftSilently();
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Disposition',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _acceptanceOptions
                              .map(
                                (status) => ChoiceChip(
                                  label: Text(
                                    status == 'accept' ? 'Accept' : 'Reject',
                                  ),
                                  selected: _acceptanceStatus == status,
                                  onSelected: (_) {
                                    setState(() {
                                      _acceptanceStatus = status;
                                    });
                                    _saveDraftSilently();
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _commentsController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Comments',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _SectionHeader(title: 'Quality Control'),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _qcInspectorController,
                                inputFormatters: _maxLengthFormatters(
                                  _qcNameMaxLength,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'QC Inspector',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _DateFieldButton(
                              label: 'Date',
                              value: _formatDateForField(_qcInspectorDate),
                              onPressed: () => _pickQcDate(forManager: false),
                            ),
                          ],
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
                              onPressed: () =>
                                  _captureSignature(forManager: false),
                              icon: const Icon(Icons.draw_outlined),
                              label: Text(
                                _qcSignaturePath.trim().isEmpty
                                    ? 'Capture Inspector Signature'
                                    : 'Re-sign Inspector',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _importSignature(forManager: false),
                              icon: const Icon(Icons.upload_file_outlined),
                              label: const Text('Import Inspector Signature'),
                            ),
                            if (_qcSignaturePath.trim().isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () => _openFile(_qcSignaturePath),
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text(
                                  'Preview Inspector Signature',
                                ),
                              ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              onPressed: () =>
                                  _clearSignature(forManager: false),
                              icon: const Icon(Icons.delete_sweep_outlined),
                              label: const Text('Clear Inspector Signature'),
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
                        if (_qcSignaturePath.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _SignaturePreviewCard(
                            label: 'QC inspector signature',
                            path: _qcSignaturePath,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'Material approval',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _materialApprovalOptions
                              .map(
                                (status) => ChoiceChip(
                                  label: Text(
                                    status == 'approved'
                                        ? 'Approved'
                                        : 'Rejected',
                                  ),
                                  selected: _materialApproval == status,
                                  onSelected: (_) {
                                    setState(() {
                                      _materialApproval = status;
                                    });
                                    _saveDraftSilently();
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _qcManagerController,
                                inputFormatters: _maxLengthFormatters(
                                  _qcNameMaxLength,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'QC Manager',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _DateFieldButton(
                              label: 'Date',
                              value: _formatDateForField(_qcManagerDate),
                              onPressed: () => _pickQcDate(forManager: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _captureSignature(forManager: true),
                              icon: const Icon(Icons.draw_outlined),
                              label: Text(
                                _qcManagerSignaturePath.trim().isEmpty
                                    ? 'Capture Manager Signature'
                                    : 'Re-sign Manager',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _importSignature(forManager: true),
                              icon: const Icon(Icons.upload_file_outlined),
                              label: const Text('Import Manager Signature'),
                            ),
                            if (_qcManagerSignaturePath.trim().isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openFile(_qcManagerSignaturePath),
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Preview Manager Signature'),
                              ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              onPressed: () =>
                                  _clearSignature(forManager: true),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Clear Manager Signature'),
                            ),
                          ],
                        ),
                        if (_qcManagerSignaturePath.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _SignaturePreviewCard(
                            label: 'QC manager signature',
                            path: _qcManagerSignaturePath,
                          ),
                        ],
                        const SizedBox(height: 18),
                        const _SectionHeader(title: 'Material photos'),
                        OutlinedButton.icon(
                          onPressed: _handlePhotoAction,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(
                            'Add material photos (${_photoPaths.length}/4)',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use these for arrival condition, markings, and visible damage.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        _ThumbnailRow(
                          paths: _photoPaths,
                          maxCount: 4,
                          itemLabel: 'photo',
                          onTap: (index) {
                            _handleExistingMediaTap(
                              isPhoto: true,
                              index: index,
                            );
                          },
                        ),
                        if (_photoPaths.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tap a thumbnail to retake or delete it.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 18),
                        const _SectionHeader(title: 'MTR/CoC scans'),
                        OutlinedButton.icon(
                          onPressed: _handleScanAction,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(
                            'Scan MTR/CoC PDFs (${_scanPaths.length}/8)',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Preferred: built-in document scanner with cleanup. Camera fallback still exports cleanly into the combined MTR PDF.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        _ThumbnailRow(
                          paths: _scanPaths,
                          maxCount: 8,
                          itemLabel: 'scan',
                          onTap: (index) {
                            _handleExistingMediaTap(
                              isPhoto: false,
                              index: index,
                            );
                          },
                        ),
                        if (_scanPaths.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tap a thumbnail to retake or delete it.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saveMaterialReceiving,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Save Material'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _saveDraftNow();
                    if (!context.mounted) {
                      return;
                    }
                    setState(() {
                      _allowImmediatePop = true;
                    });
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save_as_outlined),
                  label: const Text('Save Draft and Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<String> _optionsWithCurrent(String current, List<String> baseOptions) {
  if (current.trim().isEmpty || baseOptions.contains(current)) {
    return baseOptions;
  }
  return [...baseOptions, current];
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

class _DateFieldButton extends StatelessWidget {
  const _DateFieldButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 132),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _TriStateChoiceRow extends StatelessWidget {
  const _TriStateChoiceRow({
    required this.label,
    required this.hasSelection,
    required this.yesSelected,
    required this.noSelected,
    required this.naSelected,
    required this.onYes,
    required this.onNo,
    required this.onNa,
    required this.onClear,
  });

  final String label;
  final bool hasSelection;
  final bool yesSelected;
  final bool noSelected;
  final bool naSelected;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final VoidCallback onNa;
  final VoidCallback onClear;

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
            if (hasSelection)
              ChoiceChip(
                label: const Text('Clear'),
                selected: false,
                onSelected: (_) => onClear(),
              ),
          ],
        ),
      ],
    );
  }
}

class _BinaryChoiceRow extends StatelessWidget {
  const _BinaryChoiceRow({
    required this.label,
    required this.yesSelected,
    required this.onYes,
    required this.onNo,
  });

  final String label;
  final bool yesSelected;
  final VoidCallback onYes;
  final VoidCallback onNo;

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
              selected: !yesSelected,
              onSelected: (_) => onNo(),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabeledDropdownField extends StatelessWidget {
  const _LabeledDropdownField({
    required this.value,
    required this.labelText,
    required this.options,
    required this.onChanged,
    this.enabled = true,
    this.labelBuilder,
  });

  final String value;
  final String labelText;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String Function(String value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final resolvedValue = options.contains(value) ? value : null;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: enabled
                ? theme.colorScheme.onSurfaceVariant
                : theme.disabledColor,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey('$labelText|${resolvedValue ?? ''}|$enabled'),
          initialValue: resolvedValue,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          items: [
            for (final option in options)
              DropdownMenuItem<String>(
                value: option,
                child: Text(
                  labelBuilder?.call(option) ?? option,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class _SignaturePreviewCard extends StatelessWidget {
  const _SignaturePreviewCard({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    final exists = file.existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 96,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: exists
              ? Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const _MissingSignaturePreview(),
                )
              : const _MissingSignaturePreview(),
        ),
      ],
    );
  }
}

class _MissingSignaturePreview extends StatelessWidget {
  const _MissingSignaturePreview();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Signature file unavailable',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ThumbnailRow extends StatelessWidget {
  const _ThumbnailRow({
    required this.paths,
    required this.maxCount,
    required this.itemLabel,
    required this.onTap,
  });

  final List<String> paths;
  final int maxCount;
  final String itemLabel;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < maxCount; index++) ...[
            _ThumbnailCell(
              path: index < paths.length ? paths[index] : null,
              itemLabel: itemLabel,
              slotIndex: index + 1,
              onTap: index < paths.length ? () => onTap(index) : null,
            ),
            if (index != maxCount - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _ThumbnailCell extends StatelessWidget {
  const _ThumbnailCell({
    required this.path,
    required this.itemLabel,
    required this.slotIndex,
    this.onTap,
  });

  final String? path;
  final String itemLabel;
  final int slotIndex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedPath = path;
    final borderRadius = BorderRadius.circular(10);

    if (resolvedPath != null) {
      final previewFile = File(resolvedPath);
      final pdfPreviewFile = resolvedPath.toLowerCase().endsWith('.pdf')
          ? File(pdfPreviewSiblingPath(resolvedPath))
          : null;
      Widget child;
      if (_isPreviewableImagePath(resolvedPath) && previewFile.existsSync()) {
        child = ClipRRect(
          borderRadius: borderRadius,
          child: Image.file(
            previewFile,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        );
      } else if (pdfPreviewFile != null && pdfPreviewFile.existsSync()) {
        child = Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: borderRadius,
              child: Image.file(
                pdfPreviewFile,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        child = Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: borderRadius,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                resolvedPath.toLowerCase().endsWith('.pdf')
                    ? Icons.picture_as_pdf_outlined
                    : Icons.insert_drive_file_outlined,
                size: 20,
                color: const Color(0xFF4B5563),
              ),
              const SizedBox(height: 4),
              Text(
                resolvedPath.toLowerCase().endsWith('.pdf') ? 'PDF' : 'File',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        );
      }

      return Semantics(
        button: true,
        label:
            '${_capitalize(itemLabel)} $slotIndex attached. Tap to retake or delete.',
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: borderRadius,
            ),
            child: child,
          ),
        ),
      );
    }

    return Semantics(
      label: '${_capitalize(itemLabel)} slot $slotIndex empty.',
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          borderRadius: borderRadius,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              itemLabel == 'scan'
                  ? Icons.document_scanner_outlined
                  : Icons.add_a_photo_outlined,
              size: 18,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(height: 4),
            Text(
              '$slotIndex',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isPreviewableImagePath(String path) {
  final lowered = path.toLowerCase();
  return lowered.endsWith('.png') ||
      lowered.endsWith('.jpg') ||
      lowered.endsWith('.jpeg') ||
      lowered.endsWith('.webp');
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

enum _ScanSource { camera, importFiles }

enum _MediaAction { retake, delete, cancel }

enum _MaterialFormExitAction { keep, leave, deleteDraft }

Future<PhotoCaptureSource?> _showPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<PhotoCaptureSource>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context, PhotoCaptureSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose From Gallery'),
              onTap: () {
                Navigator.pop(context, PhotoCaptureSource.gallery);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<_ScanSource?> _showScanSourceSheet(BuildContext context) {
  return showModalBottomSheet<_ScanSource>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: const Text('Scan With Camera'),
              onTap: () {
                Navigator.pop(context, _ScanSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Import Existing Files'),
              onTap: () {
                Navigator.pop(context, _ScanSource.importFiles);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<bool?> _showScanAnotherDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Scan another document?'),
        content: const Text(
          'Keep scanning another MTR/CoC now, or stop and return to the report.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Scan Another'),
          ),
        ],
      );
    },
  );
}

Future<_MaterialFormExitAction?> _showExitReceivingReportDialog(
  BuildContext context,
) {
  return showDialog<_MaterialFormExitAction>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Exit receiving report?'),
        content: const Text(
          'This report will be autosaved as a draft when you leave. Keep editing, leave now, or delete the draft.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _MaterialFormExitAction.keep);
            },
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, _MaterialFormExitAction.leave);
            },
            child: const Text('Leave'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, _MaterialFormExitAction.deleteDraft);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Draft'),
          ),
        ],
      );
    },
  );
}

Future<_MediaAction?> _showMediaOptionsDialog(BuildContext context) {
  return showDialog<_MediaAction>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Media options'),
        content: const Text('Would you like to retake or delete this file?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _MediaAction.cancel);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, _MediaAction.delete);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, _MediaAction.retake);
            },
            child: const Text('Retake'),
          ),
        ],
      );
    },
  );
}
