import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const _dimensionValueMaxLength = 18;
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
  static const List<String> _diameterTypeOptions = ['', 'O.D.', 'I.D.'];
  static const List<String> _surfaceFinishOptions = [
    '',
    'SF1',
    'SF2',
    'SF3',
    'SF4',
  ];

  late final MaterialDraft _initialDraft;
  late MaterialDraft _savedDraftBaseline;
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
  late bool _qcManagerDateEnabled;
  late bool _qcManagerDateManual;
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
  Timer? _autosaveDebounce;
  Future<void> _draftSaveQueue = Future<void>.value();
  bool _isSubmitting = false;

  static const List<String> _acceptanceOptions = ['accept', 'reject'];
  static const List<String> _materialApprovalOptions = ['approved', 'rejected'];
  static final List<TextInputFormatter> _surfaceFinishReadingInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
  ];

  static List<TextInputFormatter> _maxLengthFormatters(int maxLength) => [
    LengthLimitingTextInputFormatter(maxLength),
  ];

  CustomizationSettings get _customization => widget.appState.customization;
  bool get _isEditingExistingMaterial =>
      _initialDraft.sourceMaterialId.trim().isNotEmpty;
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

  List<String> get _preferredB16SuffixOptions {
    final options = <String>[..._customization.preferredB16Standards];
    final current = _fittingSuffixController.text.trim();
    if (current.isNotEmpty && !options.contains(current)) {
      options.add(current);
    }
    return options;
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
    final draft = widget.appState.draftById(widget.draftId);
    _initialDraft = draft;
    _savedDraftBaseline = draft;
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
    _qcManagerDateEnabled = draft.qcManagerDateEnabled;
    _qcManagerDateManual = draft.qcManagerDateManual;
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
    _autosaveDebounce?.cancel();
    for (final controller in _autosaveControllers) {
      controller.removeListener(_saveDraftSilently);
      controller.dispose();
    }
    super.dispose();
  }

  MaterialDraft _currentDraftPayload() {
    return _initialDraft.copyWith(
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
      qcManagerDateEnabled: _qcManagerDateEnabled,
      qcManagerDateManual: _qcManagerDateManual,
      qcSignaturePath: _qcSignaturePath,
      qcManagerSignaturePath: _qcManagerSignaturePath,
      photoPaths: _photoPaths,
      scanPaths: _scanPaths,
      signatureApplied: _signatureApplied,
    );
  }

  void _saveDraftSilently() {
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(const Duration(milliseconds: 250), () {
      _queueDraftSave();
    });
  }

  Future<void> _saveDraftNow() {
    _autosaveDebounce?.cancel();
    return _queueDraftSave();
  }

  Future<void> _queueDraftSave() {
    final payload = _currentDraftPayload();
    _draftSaveQueue = _draftSaveQueue
        .catchError((_) {})
        .then((_) async {
          await widget.appState.saveDraft(payload);
          _savedDraftBaseline = payload;
        });
    return _draftSaveQueue;
  }

  String _formatDateForField(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$month/$day/${local.year}';
  }

  String get _dimensionHelperText => _unitSystem == UnitSystem.metric
      ? 'Enter measured dimensions in millimeters. Example: 600 or 12.5.'
      : 'Enter inches, fractions, or feet/inches. Examples: 23, 23 1/4, or 2\' 3".';

  Future<void> _pickQcDate({required bool forManager}) async {
    final initialDate = forManager
        ? (_qcManagerDateEnabled ? _qcManagerDate : DateTime.now())
        : _qcInspectorDate;
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
        _qcManagerDateEnabled = true;
        _qcManagerDateManual = true;
      } else {
        _qcInspectorDate = selectedDate;
      }
    });
    await _saveDraftNow();
  }

  Future<void> _clearQcManagerDate() async {
    setState(() {
      _qcManagerDateEnabled = false;
      _qcManagerDateManual = false;
    });
    await _saveDraftNow();
  }

  bool get _hasDraftChanges =>
      _currentDraftPayload().toJson().toString() !=
      _savedDraftBaseline.toJson().toString();

  Future<void> _handleBackNavigation() async {
    _autosaveDebounce?.cancel();
    await _draftSaveQueue.catchError((_) {});

    if (_allowImmediatePop || !_hasDraftChanges) {
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      return;
    }

    if (!mounted) {
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
    var savedCount = 0;
    var failedCount = 0;
    for (final capture in captures) {
      try {
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
        savedCount++;
      } catch (_) {
        failedCount++;
      }
    }
    if (!mounted) {
      return;
    }
    if (savedCount > 0) {
      setState(() {
        _photoPaths = nextPaths;
      });
      await _saveDraftNow();
    }
    if (failedCount > 0) {
      _showMessage(
        savedCount > 0
            ? 'Some photos could not be saved. Try the missing shots again.'
            : 'The photo could not be saved. Try again.',
      );
    }
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
    var savedCount = 0;
    var failedCount = 0;
    for (final capture in captures) {
      try {
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
        savedCount++;
      } catch (_) {
        failedCount++;
      }
    }
    if (!mounted) {
      return;
    }
    if (savedCount > 0) {
      setState(() {
        _scanPaths = nextPaths;
      });
      await _saveDraftNow();
    }
    if (failedCount > 0) {
      _showMessage(
        savedCount > 0
            ? 'Some scans could not be saved. Try the missing pages again.'
            : 'The scan could not be saved. Try again.',
      );
    }
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
            nextIndex: replaceIndex == null
                ? _scanPaths.length + 1
                : replaceIndex + 1,
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
        if (!_qcManagerDateEnabled || !_qcManagerDateManual) {
          _qcManagerDate = DateTime.now();
          _qcManagerDateEnabled = true;
        }
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
    final copiedPath = await widget.appState.mediaService.copyExistingSignature(
      sourcePath: sourcePath,
      jobNumber: widget.appState.jobById(widget.jobId).jobNumber,
      materialLabel: _materialLabelForFiles,
      targetLabel: 'qc_inspector',
    );
    setState(() {
      _qcSignaturePath = copiedPath;
      _signatureApplied = true;
    });
    await _saveDraftNow();
  }

  Future<void> _clearSignature({required bool forManager}) async {
    setState(() {
      if (forManager) {
        _qcManagerSignaturePath = '';
        if (!_qcManagerDateManual) {
          _qcManagerDateEnabled = false;
        }
      } else {
        _qcSignaturePath = '';
        _signatureApplied = false;
      }
    });
    await _saveDraftNow();
  }

  Future<void> _saveMaterialReceiving() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      final wasEditing = _isEditingExistingMaterial;
      final currentDraft = _currentDraftPayload();
      _autosaveDebounce?.cancel();
      await _draftSaveQueue.catchError((_) {});
      await widget.appState.saveDraft(currentDraft);
      await widget.appState.completeDraft(currentDraft);
      if (!mounted) {
        return;
      }
      setState(() {
        _allowImmediatePop = true;
      });
      _showMessage(
        wasEditing
            ? 'Material receiving updated.'
            : 'Material receiving saved.',
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
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

  Widget _buildOverviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final inspectorSigned = _qcSignaturePath.trim().isNotEmpty;
    final managerSigned = _qcManagerSignaturePath.trim().isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECEIVING INSPECTION\nREPORT',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isEditingExistingMaterial
                  ? 'Editing a saved receiving item. Every field change autosaves while you work.'
                  : 'Capture one material at a time. Every field change autosaves while you work.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatusPill(
                  label: 'Photos ${_photoPaths.length}/4',
                  background: const Color(0xFFE8F1FB),
                  foreground: const Color(0xFF16507A),
                ),
                _StatusPill(
                  label: 'Scans ${_scanPaths.length}/8',
                  background: const Color(0xFFEFF6FF),
                  foreground: const Color(0xFF1D4ED8),
                ),
                _StatusPill(
                  label: inspectorSigned
                      ? 'Inspector signature ready'
                      : 'Inspector signature pending',
                  background: inspectorSigned
                      ? const Color(0xFFE9F7EE)
                      : const Color(0xFFFFF4E5),
                  foreground: inspectorSigned
                      ? const Color(0xFF1E6B3C)
                      : const Color(0xFF8A5B14),
                ),
                _StatusPill(
                  label: managerSigned
                      ? 'Manager signature ready'
                      : 'Manager signature pending',
                  background: managerSigned
                      ? const Color(0xFFE9F7EE)
                      : const Color(0xFFF3F4F6),
                  foreground: managerSigned
                      ? const Color(0xFF1E6B3C)
                      : const Color(0xFF4B5563),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionTextField(
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      inputFormatters: _maxLengthFormatters(_dimensionValueMaxLength),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildMaterialSection(BuildContext context, {required bool showB16}) {
    return _FormSectionCard(
      icon: Icons.inventory_2_outlined,
      title: 'Material Details',
      subtitle:
          'Capture how this item should be identified in the report and packet export.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _descriptionController,
            inputFormatters: _maxLengthFormatters(_descriptionMaxLength),
            decoration: const InputDecoration(labelText: 'Material Description'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _poNumberController,
                  inputFormatters: _maxLengthFormatters(_poNumberMaxLength),
                  decoration: const InputDecoration(labelText: 'PO #'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _vendorController,
                  inputFormatters: _maxLengthFormatters(_vendorMaxLength),
                  decoration: const InputDecoration(labelText: 'Vendor'),
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
                      inputFormatters: _maxLengthFormatters(_quantityMaxLength),
                      decoration: const InputDecoration(labelText: 'Qty'),
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
                          _productTypeController.text = value ?? '';
                        });
                        _saveDraftSilently();
                      },
                    ),
                    const SizedBox(height: 12),
                    _LabeledDropdownField(
                      value: _specificationPrefixController.text,
                      labelText: 'A/SA',
                      options: _optionsWithCurrent(
                        _specificationPrefixController.text,
                        _specificationPrefixOptions,
                      ),
                      labelBuilder: (value) => value.isEmpty ? 'Blank' : value,
                      onChanged: (value) {
                        setState(() {
                          _specificationPrefixController.text = value ?? '';
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
                      inputFormatters: _maxLengthFormatters(_quantityMaxLength),
                      decoration: const InputDecoration(labelText: 'Qty'),
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
                          _productTypeController.text = value ?? '';
                        });
                        _saveDraftSilently();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _LabeledDropdownField(
                      value: _specificationPrefixController.text,
                      labelText: 'A/SA',
                      options: _optionsWithCurrent(
                        _specificationPrefixController.text,
                        _specificationPrefixOptions,
                      ),
                      labelBuilder: (value) => value.isEmpty ? 'Blank' : value,
                      onChanged: (value) {
                        setState(() {
                          _specificationPrefixController.text = value ?? '';
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
            inputFormatters: _maxLengthFormatters(_gradeTypeMaxLength),
            decoration: const InputDecoration(labelText: 'Spec/Grade'),
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
                            _fittingStandardController.text = value ?? 'N/A';
                            if (_fittingStandardController.text != 'B16') {
                              _fittingSuffixController.text = '';
                            }
                          });
                          _saveDraftSilently();
                        },
                      ),
                      const SizedBox(height: 12),
                      _LabeledDropdownField(
                        value: _fittingSuffixController.text,
                        labelText: 'B16 Standard',
                        options: _optionsWithCurrent(
                          _fittingSuffixController.text,
                          _preferredB16SuffixOptions,
                        ),
                        enabled: _fittingStandardController.text == 'B16',
                        labelBuilder: (value) => value.isEmpty
                            ? 'N/A'
                            : formatB16StandardDropdownLabel(value),
                        onChanged: (value) {
                          setState(() {
                            _fittingSuffixController.text = value ?? '';
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
                            _fittingStandardController.text = value ?? 'N/A';
                            if (_fittingStandardController.text != 'B16') {
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
                        labelText: 'B16 Standard',
                        options: _optionsWithCurrent(
                          _fittingSuffixController.text,
                          _preferredB16SuffixOptions,
                        ),
                        enabled: _fittingStandardController.text == 'B16',
                        labelBuilder: (value) => value.isEmpty
                            ? 'N/A'
                            : formatB16StandardDropdownLabel(value),
                        onChanged: (value) {
                          setState(() {
                            _fittingSuffixController.text = value ?? '';
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
        ],
      ),
    );
  }

  Widget _buildInspectionSection(
    BuildContext context, {
    required bool showB16,
    required bool showSurfaceFinish,
  }) {
    final theme = Theme.of(context);
    return _FormSectionCard(
      icon: Icons.straighten_outlined,
      title: 'Inspection',
      subtitle:
          'Record measured dimensions, markings, supporting docs, and final disposition.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InsetInfoPanel(
            title: 'Dimensions',
            subtitle: _dimensionHelperText,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    if (stackFields) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDimensionTextField(
                                  _thickness1Controller,
                                  'TH 1',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDimensionTextField(
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
                                child: _buildDimensionTextField(
                                  _thickness3Controller,
                                  'TH 3',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDimensionTextField(
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
                          child: _buildDimensionTextField(
                            _thickness1Controller,
                            'TH 1',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDimensionTextField(
                            _thickness2Controller,
                            'TH 2',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDimensionTextField(
                            _thickness3Controller,
                            'TH 3',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDimensionTextField(
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
                                child: _buildDimensionTextField(
                                  _widthController,
                                  'Width',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDimensionTextField(
                                  _lengthController,
                                  'Length',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDimensionTextField(
                                  _diameterController,
                                  'Diameter',
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
                                      _diameterTypeController.text = value ?? '';
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
                          child: _buildDimensionTextField(
                            _widthController,
                            'Width',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDimensionTextField(
                            _lengthController,
                            'Length',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDimensionTextField(
                            _diameterController,
                            'Diameter',
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
                                _diameterTypeController.text = value ?? '';
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
                    labelText: 'B16 Dimensions acceptable',
                    options: _optionsWithCurrent(
                      _b16SizeController.text,
                      const ['', 'Yes', 'No'],
                    ),
                    labelBuilder: (value) => value.isEmpty ? 'N/A' : value,
                    onChanged: (value) {
                      setState(() {
                        _b16SizeController.text = value ?? '';
                      });
                      _saveDraftSilently();
                    },
                  ),
                ],
              ],
            ),
          ),
          if (showSurfaceFinish) ...[
            const SizedBox(height: 14),
            _InsetInfoPanel(
              title: 'Surface Finish',
              subtitle:
                  'Use the requested finish and the actual measured reading from the part.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LabeledDropdownField(
                    value: _surfaceFinishController.text,
                    labelText: 'Surface Finish',
                    options: _optionsWithCurrent(
                      _surfaceFinishController.text,
                      _surfaceFinishOptions,
                    ),
                    labelBuilder: (value) => value.isEmpty ? 'N/A' : value,
                    onChanged: (value) {
                      setState(() {
                        _surfaceFinishController.text = value ?? '';
                      });
                      _saveDraftSilently();
                    },
                  ),
                  const SizedBox(height: 12),
                  const _CenteredSubsectionTitle(
                    title: 'Actual Surface Finish Reading',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _surfaceFinishReadingController,
                          keyboardType: TextInputType.number,
                          inputFormatters:
                              _surfaceFinishReadingInputFormatters,
                          decoration: const InputDecoration(labelText: 'Reading'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _customization.surfaceFinishUnit,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _InsetInfoPanel(
            title: 'Markings and Documentation',
            subtitle:
                'Record what is physically marked on the material and whether the supporting docs are acceptable.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CenteredSubsectionTitle(title: 'Actual Markings'),
                TextField(
                  controller: _markingsController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Markings found'),
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
              ],
            ),
          ),
          const SizedBox(height: 14),
          _InsetInfoPanel(
            title: 'Disposition',
            subtitle:
                'Finish the receiving review with the material decision and any brief notes.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  decoration: const InputDecoration(labelText: 'Comments'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureBlock({
    required BuildContext context,
    required String title,
    required TextEditingController nameController,
    required String nameLabel,
    required String dateLabel,
    required String dateValue,
    required VoidCallback onPickDate,
    required String signaturePath,
    required String previewLabel,
    required String readyLabel,
    required String pendingLabel,
    required String helperText,
    required VoidCallback onCapture,
    required VoidCallback onClear,
    VoidCallback? onUseSaved,
    bool showClearDateButton = false,
    VoidCallback? onClearDate,
  }) {
    final hasSignature = signaturePath.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E1EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusPill(
                label: hasSignature ? readyLabel : pendingLabel,
                background: hasSignature
                    ? const Color(0xFFE9F7EE)
                    : const Color(0xFFFFF4E5),
                foreground: hasSignature
                    ? const Color(0xFF1E6B3C)
                    : const Color(0xFF8A5B14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            helperText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackFields = constraints.maxWidth < 600;
              final dateField = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DateFieldButton(
                    label: dateLabel,
                    value: dateValue,
                    onPressed: onPickDate,
                  ),
                  if (showClearDateButton && onClearDate != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Clear date',
                      onPressed: onClearDate,
                      icon: const Icon(Icons.clear_rounded),
                    ),
                  ],
                ],
              );
              if (stackFields) {
                return Column(
                  children: [
                    TextField(
                      controller: nameController,
                      inputFormatters: _maxLengthFormatters(_qcNameMaxLength),
                      decoration: InputDecoration(labelText: nameLabel),
                    ),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: dateField),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      inputFormatters: _maxLengthFormatters(_qcNameMaxLength),
                      decoration: InputDecoration(labelText: nameLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  dateField,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onUseSaved != null)
                FilledButton.tonalIcon(
                  onPressed: onUseSaved,
                  icon: const Icon(Icons.draw_outlined),
                  label: const Text('Use Saved'),
                ),
              FilledButton.icon(
                onPressed: onCapture,
                icon: const Icon(Icons.edit_outlined),
                label: Text(hasSignature ? 'Re-sign' : 'Capture Signature'),
              ),
              OutlinedButton.icon(
                onPressed: hasSignature ? onClear : null,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SignaturePreviewCard(
            label: previewLabel,
            path: signaturePath,
            emptyLabel: 'No signature captured yet',
          ),
        ],
      ),
    );
  }

  Widget _buildQualityControlSection(BuildContext context) {
    final canUseSavedInspectorSignature =
        _customization.hasSavedInspectorSignature &&
        _customization.savedInspectorSignaturePath.trim().isNotEmpty;
    return _FormSectionCard(
      icon: Icons.verified_user_outlined,
      title: 'Signoff',
      subtitle:
          'Capture the QC signoff that should print into the exported receiving packet.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSignatureBlock(
            context: context,
            title: 'QC Inspector Signature',
            nameController: _qcInspectorController,
            nameLabel: 'QC Inspector',
            dateLabel: 'Date',
            dateValue: _formatDateForField(_qcInspectorDate),
            onPickDate: () => _pickQcDate(forManager: false),
            signaturePath: _qcSignaturePath,
            previewLabel: 'QC inspector signature',
            readyLabel: 'Ready',
            pendingLabel: 'Pending',
            helperText:
                'Use the saved inspector signature if you already set one in customization, or capture it directly on this report.',
            onCapture: () => _captureSignature(forManager: false),
            onClear: () => _clearSignature(forManager: false),
            onUseSaved:
                canUseSavedInspectorSignature ? _applySavedInspectorSignature : null,
          ),
          const SizedBox(height: 14),
          _InsetInfoPanel(
            title: 'Material Approval',
            subtitle: 'Set the overall approval outcome for this material.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _materialApprovalOptions
                  .map(
                    (status) => ChoiceChip(
                      label: Text(
                        status == 'approved' ? 'Approved' : 'Rejected',
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
          ),
          const SizedBox(height: 14),
          _buildSignatureBlock(
            context: context,
            title: 'QC Manager Signature',
            nameController: _qcManagerController,
            nameLabel: 'QC Manager',
            dateLabel: 'Manager Date',
            dateValue:
                _qcManagerDateEnabled ? _formatDateForField(_qcManagerDate) : '',
            onPickDate: () => _pickQcDate(forManager: true),
            signaturePath: _qcManagerSignaturePath,
            previewLabel: 'QC manager signature',
            readyLabel: 'Ready',
            pendingLabel: 'Optional',
            helperText:
                'Leave this blank until the manager signs. Capturing a signature sets today automatically unless you already chose a date.',
            onCapture: () => _captureSignature(forManager: true),
            onClear: () => _clearSignature(forManager: true),
            showClearDateButton: _qcManagerDateEnabled,
            onClearDate: _clearQcManagerDate,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaBlock({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int count,
    required int maxCount,
    required String actionLabel,
    required IconData icon,
    required VoidCallback onPressed,
    required List<String> paths,
    required String itemLabel,
    required ValueChanged<int> onTap,
  }) {
    return _InsetInfoPanel(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatusPill(
                  label: '$count / $maxCount attached',
                  background: count > 0
                      ? const Color(0xFFE9F7EE)
                      : const Color(0xFFF3F4F6),
                  foreground: count > 0
                      ? const Color(0xFF1E6B3C)
                      : const Color(0xFF4B5563),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(actionLabel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD8E1EA)),
            ),
            child: _ThumbnailRow(
              paths: paths,
              maxCount: maxCount,
              itemLabel: itemLabel,
              onTap: onTap,
            ),
          ),
          if (paths.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tap a thumbnail to retake or delete it.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(BuildContext context) {
    return _FormSectionCard(
      icon: Icons.attach_file_outlined,
      title: 'Attachments',
      subtitle:
          'Bundle jobsite photos and MTR/CoC scans into the exported receiving packet.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMediaBlock(
            context: context,
            title: 'Material Photos',
            subtitle:
                'Use these for arrival condition, markings, and visible damage.',
            count: _photoPaths.length,
            maxCount: 4,
            actionLabel: 'Add Photos',
            icon: Icons.add_a_photo_outlined,
            onPressed: _handlePhotoAction,
            paths: _photoPaths,
            itemLabel: 'photo',
            onTap: (index) =>
                _handleExistingMediaTap(isPhoto: true, index: index),
          ),
          const SizedBox(height: 14),
          _buildMediaBlock(
            context: context,
            title: 'MTR/CoC Scans',
            subtitle:
                'Preferred: built-in document scanner with cleanup. Camera fallback still exports into the combined MTR PDF.',
            count: _scanPaths.length,
            maxCount: 8,
            actionLabel: 'Add Scans',
            icon: Icons.picture_as_pdf_outlined,
            onPressed: _handleScanAction,
            paths: _scanPaths,
            itemLabel: 'scan',
            onTap: (index) =>
                _handleExistingMediaTap(isPhoto: false, index: index),
          ),
        ],
      ),
    );
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
                _buildOverviewCard(context),
                const SizedBox(height: 16),
                _buildMaterialSection(context, showB16: showB16),
                const SizedBox(height: 16),
                _buildInspectionSection(
                  context,
                  showB16: showB16,
                  showSurfaceFinish: showSurfaceFinish,
                ),
                const SizedBox(height: 16),
                _buildQualityControlSection(context),
                const SizedBox(height: 16),
                _buildAttachmentsSection(context),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _saveMaterialReceiving,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Save Material'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
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

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFF1D4ED8)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InsetInfoPanel extends StatelessWidget {
  const _InsetInfoPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E1EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CenteredSubsectionTitle extends StatelessWidget {
  const _CenteredSubsectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
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
  const _SignaturePreviewCard({
    required this.label,
    required this.path,
    this.emptyLabel = 'Signature file unavailable',
  });

  final String label;
  final String path;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final trimmedPath = path.trim();
    final file = trimmedPath.isEmpty ? null : File(trimmedPath);
    final exists = file?.existsSync() ?? false;
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
          child: exists && file != null
              ? Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _MissingSignaturePreview(message: emptyLabel),
                )
              : _MissingSignaturePreview(message: emptyLabel),
        ),
      ],
    );
  }
}

class _MissingSignaturePreview extends StatelessWidget {
  const _MissingSignaturePreview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
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
      if (!resolvedPath.toLowerCase().endsWith('.pdf') &&
          previewFile.existsSync()) {
        child = ClipRRect(
          borderRadius: borderRadius,
          child: Image.file(
            previewFile,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _thumbnailFallback(
              context,
              resolvedPath,
              borderRadius,
            ),
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
        child = _thumbnailFallback(context, resolvedPath, borderRadius);
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
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _thumbnailFallback(
  BuildContext context,
  String path,
  BorderRadius borderRadius,
) {
  final isPdf = path.toLowerCase().endsWith('.pdf');
  return Container(
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
          isPdf
              ? Icons.picture_as_pdf_outlined
              : Icons.insert_photo_outlined,
          size: 20,
          color: const Color(0xFF4B5563),
        ),
        const SizedBox(height: 4),
        Text(
          isPdf ? 'PDF' : 'Image',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: const Color(0xFF4B5563)),
        ),
      ],
    ),
  );
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
