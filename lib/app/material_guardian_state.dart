import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/customization_store.dart';
import '../data/material_guardian_snapshot_store.dart';
import '../services/backend_api_service.dart';
import '../services/customization_asset_service.dart';
import '../services/job_export_service.dart';
import '../services/material_media_service.dart';
import 'models.dart';

class MaterialGuardianAppState extends ChangeNotifier {
  MaterialGuardianAppState._({
    required List<JobRecord> jobs,
    required List<MaterialDraft> drafts,
    required CustomizationSettings customization,
    required MaterialGuardianSnapshotStore snapshotStore,
    required CustomizationStore customizationStore,
    required CustomizationAssetService customizationAssetService,
    required BackendApiService backendApiService,
    required MaterialMediaService mediaService,
    required JobExportService exportService,
  }) : _jobs = jobs,
       _drafts = drafts,
       _customization = customization,
       _snapshotStore = snapshotStore,
       _customizationStore = customizationStore,
       _customizationAssetService = customizationAssetService,
       _backendApiService = backendApiService,
       _mediaService = mediaService,
       _exportService = exportService;

  factory MaterialGuardianAppState.seeded({
    BackendApiService? backendApiService,
  }) {
    final customization = CustomizationSettings(
      receiveAsmeB16Parts: true,
      surfaceFinishRequired: true,
      surfaceFinishUnit: 'u-in',
      defaultQcInspectorName: 'Kevin Penfield',
      defaultQcManagerName: 'Shop QA',
      hasSavedInspectorSignature: true,
      savedInspectorSignaturePath: '',
      includeCompanyLogoOnReports: true,
      companyLogoPath: '',
    );

    final jobs = <JobRecord>[
      JobRecord(
        id: 'job-1001',
        jobNumber: 'MG-24031',
        description: 'Valve and fitting receiving packet',
        notes: 'NEMO Overlay',
        createdAt: DateTime(2026, 3, 31, 9, 30),
        exportedAt: null,
        exportPath: '',
        materials: [
          MaterialRecord(
            id: 'mat-001',
            tag: 'V-101',
            description: '2" gate valve',
            vendor: 'NEMO Overlay',
            poNumber: 'PO-24031',
            productType: 'Valve',
            specificationPrefix: 'SA',
            gradeType: '105',
            fittingStandard: 'B16.34',
            fittingSuffix: '',
            dimensionUnit: UnitSystem.imperial,
            heatNumber: 'HT-44721',
            thickness1: '',
            width: '',
            length: '',
            diameter: '2',
            diameterType: 'Nominal',
            visualInspectionAcceptable: true,
            b16DimensionsAcceptable: 'Accept',
            surfaceFinishCode: '',
            surfaceFinishReading: '',
            surfaceFinishUnit: customization.surfaceFinishUnit,
            markings: '',
            markingAcceptable: true,
            markingAcceptableNa: false,
            mtrAcceptable: true,
            mtrAcceptableNa: false,
            acceptanceStatus: 'accept',
            comments: '',
            quantity: '2',
            qcInspectorName: 'Kevin Penfield',
            qcManagerName: 'Shop QA',
            qcSignaturePath: '',
            qcManagerSignaturePath: '',
            materialApproval: 'approved',
            offloadStatus: '',
            pdfStatus: '',
            pdfStoragePath: '',
            photoPaths: const [],
            scanPaths: const [],
            photoCount: 0,
            createdAt: DateTime(2026, 3, 31, 10, 0),
          ),
        ],
      ),
    ];

    final drafts = <MaterialDraft>[
      MaterialDraft(
        id: 'draft-001',
        jobId: 'job-1001',
        sourceMaterialId: '',
        materialTag: '',
        description: 'Unfinished support lug inspection',
        vendor: '',
        poNumber: '',
        productType: 'Support lug',
        specificationPrefix: '',
        gradeType: '',
        fittingStandard: '',
        fittingSuffix: '',
        heatNumber: '',
        quantity: '1',
        unitSystem: UnitSystem.imperial,
        includesB16Data: false,
        b16Size: '',
        thickness1: '',
        width: '',
        length: '',
        diameter: '',
        diameterType: '',
        visualInspectionAcceptable: true,
        surfaceFinish: '125 AARH',
        surfaceFinishReading: '',
        surfaceFinishUnit: customization.surfaceFinishUnit,
        markings: '',
        markingAcceptable: true,
        markingAcceptableNa: false,
        mtrAcceptable: true,
        mtrAcceptableNa: false,
        comments: '',
        acceptanceStatus: 'accept',
        qcInspectorName: customization.defaultQcInspectorName,
        qcManagerName: customization.defaultQcManagerName,
        qcSignaturePath: '',
        qcManagerSignaturePath: '',
        photoPaths: const [],
        scanPaths: const [],
        signatureApplied: false,
        updatedAt: DateTime(2026, 4, 1, 8, 20),
      ),
    ];

    return MaterialGuardianAppState._(
      jobs: jobs,
      drafts: drafts,
      customization: customization,
      snapshotStore: MaterialGuardianSnapshotStore(),
      customizationStore: CustomizationStore(),
      customizationAssetService: CustomizationAssetService(),
      backendApiService: backendApiService ?? BackendApiService(),
      mediaService: MaterialMediaService(),
      exportService: JobExportService(),
    );
  }

  static Future<MaterialGuardianAppState> create({
    BackendApiService? backendApiService,
  }) async {
    final snapshotStore = MaterialGuardianSnapshotStore();
    final customizationStore = CustomizationStore();
    final snapshot = await snapshotStore.load();
    final customization = await customizationStore.load();
    final appState = MaterialGuardianAppState._(
      jobs: snapshot.jobs,
      drafts: snapshot.drafts,
      customization: customization,
      snapshotStore: snapshotStore,
      customizationStore: customizationStore,
      customizationAssetService: CustomizationAssetService(),
      backendApiService: backendApiService ?? BackendApiService(),
      mediaService: MaterialMediaService(),
      exportService: JobExportService(),
    );
    await appState.refreshBackendHealth();
    return appState;
  }

  final MaterialGuardianSnapshotStore _snapshotStore;
  final CustomizationStore _customizationStore;
  final CustomizationAssetService _customizationAssetService;
  final BackendApiService _backendApiService;
  final MaterialMediaService _mediaService;
  final JobExportService _exportService;

  List<JobRecord> _jobs;
  List<MaterialDraft> _drafts;
  CustomizationSettings _customization;
  BackendHealthSnapshot? _backendHealth;
  String? _backendHealthError;
  bool _isCheckingBackendHealth = false;

  List<JobRecord> get jobs => List.unmodifiable(_jobs);
  List<MaterialDraft> get drafts => List.unmodifiable(_drafts);
  CustomizationSettings get customization => _customization;
  CustomizationAssetService get customizationAssetService =>
      _customizationAssetService;
  BackendApiService get backendApiService => _backendApiService;
  String get backendBaseUrl => _backendApiService.baseUrl;
  BackendHealthSnapshot? get backendHealth => _backendHealth;
  String? get backendHealthError => _backendHealthError;
  bool get isCheckingBackendHealth => _isCheckingBackendHealth;
  MaterialMediaService get mediaService => _mediaService;

  JobRecord jobById(String id) {
    return _jobs.firstWhere((job) => job.id == id);
  }

  MaterialDraft draftById(String id) {
    return _drafts.firstWhere((draft) => draft.id == id);
  }

  MaterialRecord materialById({
    required String jobId,
    required String materialId,
  }) {
    final job = jobById(jobId);
    return job.materials.firstWhere((material) => material.id == materialId);
  }

  List<MaterialDraft> draftsForJob(String jobId) {
    return _drafts
        .where((draft) => draft.jobId == jobId)
        .toList(growable: false);
  }

  Future<void> saveJob({
    required String jobNumber,
    required String description,
    required String notes,
  }) async {
    final cleanJobNumber = jobNumber.trim();
    if (cleanJobNumber.isEmpty) {
      return;
    }

    final existingIndex = _jobs.indexWhere(
      (item) => item.jobNumber == cleanJobNumber,
    );
    final nextJob = JobRecord(
      id: existingIndex >= 0
          ? _jobs[existingIndex].id
          : 'job-${DateTime.now().microsecondsSinceEpoch}',
      jobNumber: cleanJobNumber,
      description: description.trim(),
      notes: notes.trim(),
      createdAt: existingIndex >= 0
          ? _jobs[existingIndex].createdAt
          : DateTime.now(),
      exportedAt: existingIndex >= 0 ? _jobs[existingIndex].exportedAt : null,
      exportPath: existingIndex >= 0 ? _jobs[existingIndex].exportPath : '',
      materials: existingIndex >= 0 ? _jobs[existingIndex].materials : const [],
    );

    if (existingIndex >= 0) {
      final updated = [..._jobs];
      updated[existingIndex] = nextJob;
      _jobs = updated;
    } else {
      _jobs = [..._jobs, nextJob];
    }

    notifyListeners();
    await _persistSnapshot();
  }

  Future<void> deleteJob(String jobId) async {
    _jobs = _jobs.where((job) => job.id != jobId).toList(growable: false);
    _drafts = _drafts
        .where((draft) => draft.jobId != jobId)
        .toList(growable: false);
    notifyListeners();
    await _persistSnapshot();
  }

  Future<void> updateJob({
    required String jobId,
    required String jobNumber,
    required String description,
    required String notes,
  }) async {
    final cleanJobNumber = jobNumber.trim();
    if (cleanJobNumber.isEmpty) {
      return;
    }

    final existingIndex = _jobs.indexWhere((job) => job.id == jobId);
    if (existingIndex < 0) {
      return;
    }

    final currentJob = _jobs[existingIndex];
    final updatedJob = currentJob.copyWith(
      jobNumber: cleanJobNumber,
      description: description.trim(),
      notes: notes.trim(),
    );

    final updatedJobs = [..._jobs];
    updatedJobs[existingIndex] = updatedJob;
    _jobs = updatedJobs;
    notifyListeners();
    await _persistSnapshot();
  }

  Future<MaterialDraft> createBlankDraft({required String jobId}) async {
    final draft = MaterialDraft(
      id: 'draft-${DateTime.now().microsecondsSinceEpoch}',
      jobId: jobId,
      sourceMaterialId: '',
      materialTag: '',
      description: '',
      vendor: '',
      poNumber: '',
      productType: '',
      specificationPrefix: '',
      gradeType: '',
      fittingStandard: '',
      fittingSuffix: '',
      heatNumber: '',
      quantity: '',
      unitSystem: UnitSystem.imperial,
      includesB16Data: _customization.receiveAsmeB16Parts,
      b16Size: '',
      thickness1: '',
      width: '',
      length: '',
      diameter: '',
      diameterType: '',
      visualInspectionAcceptable: true,
      surfaceFinish: '',
      surfaceFinishReading: '',
      surfaceFinishUnit: _customization.surfaceFinishUnit,
      markings: '',
      markingAcceptable: true,
      markingAcceptableNa: false,
      mtrAcceptable: true,
      mtrAcceptableNa: false,
      comments: '',
      acceptanceStatus: 'accept',
      qcInspectorName: _customization.defaultQcInspectorName,
      qcManagerName: _customization.defaultQcManagerName,
      qcSignaturePath: '',
      qcManagerSignaturePath: '',
      photoPaths: const [],
      scanPaths: const [],
      signatureApplied: _customization.hasSavedInspectorSignature,
      updatedAt: DateTime.now(),
    );

    _drafts = [..._drafts, draft];
    notifyListeners();
    await _persistSnapshot();
    return draft;
  }

  Future<MaterialDraft> createEditDraft({
    required String jobId,
    required String materialId,
  }) async {
    final existingDraftIndex = _drafts.indexWhere(
      (draft) => draft.jobId == jobId && draft.sourceMaterialId == materialId,
    );
    if (existingDraftIndex >= 0) {
      return _drafts[existingDraftIndex];
    }

    final material = materialById(jobId: jobId, materialId: materialId);
    final draft = MaterialDraft(
      id: 'draft-${DateTime.now().microsecondsSinceEpoch}',
      jobId: jobId,
      sourceMaterialId: material.id,
      materialTag: material.tag,
      description: material.description,
      vendor: material.vendor,
      quantity: material.quantity,
      poNumber: material.poNumber,
      productType: material.productType,
      specificationPrefix: material.specificationPrefix,
      gradeType: material.gradeType,
      fittingStandard: material.fittingStandard,
      fittingSuffix: material.fittingSuffix,
      unitSystem: material.dimensionUnit,
      heatNumber: material.heatNumber,
      includesB16Data: material.b16DimensionsAcceptable.trim().isNotEmpty,
      b16Size: material.b16DimensionsAcceptable,
      thickness1: material.thickness1,
      width: material.width,
      length: material.length,
      diameter: material.diameter,
      diameterType: material.diameterType,
      visualInspectionAcceptable: material.visualInspectionAcceptable,
      surfaceFinish: material.surfaceFinishCode,
      surfaceFinishReading: material.surfaceFinishReading,
      surfaceFinishUnit: material.surfaceFinishUnit,
      markings: material.markings,
      markingAcceptable: material.markingAcceptable,
      markingAcceptableNa: material.markingAcceptableNa,
      mtrAcceptable: material.mtrAcceptable,
      mtrAcceptableNa: material.mtrAcceptableNa,
      comments: material.comments,
      acceptanceStatus: material.acceptanceStatus,
      qcInspectorName: material.qcInspectorName,
      qcManagerName: material.qcManagerName,
      qcSignaturePath: material.qcSignaturePath,
      qcManagerSignaturePath: material.qcManagerSignaturePath,
      photoPaths: material.photoPaths,
      scanPaths: material.scanPaths,
      signatureApplied: _customization.hasSavedInspectorSignature,
      updatedAt: DateTime.now(),
    );

    _drafts = [..._drafts, draft];
    notifyListeners();
    await _persistSnapshot();
    return draft;
  }

  Future<void> saveDraft(MaterialDraft draft) async {
    final nextDraft = draft.copyWith(updatedAt: DateTime.now());
    final index = _drafts.indexWhere((item) => item.id == draft.id);
    if (index >= 0) {
      final updated = [..._drafts];
      updated[index] = nextDraft;
      _drafts = updated;
    } else {
      _drafts = [..._drafts, nextDraft];
    }
    notifyListeners();
    await _persistSnapshot();
  }

  Future<void> deleteDraft(String draftId) async {
    _drafts = _drafts
        .where((draft) => draft.id != draftId)
        .toList(growable: false);
    notifyListeners();
    await _persistSnapshot();
  }

  Future<void> completeDraft(MaterialDraft draft) async {
    final existingMaterialId = draft.sourceMaterialId.trim();
    final material = MaterialRecord(
      id: existingMaterialId.isEmpty
          ? 'mat-${DateTime.now().microsecondsSinceEpoch}'
          : existingMaterialId,
      tag: draft.materialTag.trim().isEmpty
          ? 'UNASSIGNED'
          : draft.materialTag.trim(),
      description: draft.description.trim().isEmpty
          ? 'Receiving report item'
          : draft.description.trim(),
      vendor: draft.vendor.trim(),
      heatNumber: draft.heatNumber.trim(),
      quantity: draft.quantity.trim().isEmpty ? '1' : draft.quantity.trim(),
      poNumber: draft.poNumber.trim(),
      productType: draft.productType.trim(),
      specificationPrefix: draft.specificationPrefix.trim(),
      gradeType: draft.gradeType.trim(),
      fittingStandard: draft.fittingStandard.trim(),
      fittingSuffix: draft.fittingSuffix.trim(),
      dimensionUnit: draft.unitSystem,
      thickness1: draft.thickness1.trim(),
      width: draft.width.trim(),
      length: draft.length.trim(),
      diameter: draft.diameter.trim(),
      diameterType: draft.diameterType.trim(),
      visualInspectionAcceptable: draft.visualInspectionAcceptable,
      b16DimensionsAcceptable: draft.includesB16Data
          ? draft.b16Size.trim()
          : '',
      surfaceFinishCode: draft.surfaceFinish.trim(),
      surfaceFinishReading: draft.surfaceFinishReading.trim(),
      surfaceFinishUnit: draft.surfaceFinishUnit.trim(),
      markings: draft.markings.trim(),
      markingAcceptable: draft.markingAcceptable,
      markingAcceptableNa: draft.markingAcceptableNa,
      mtrAcceptable: draft.mtrAcceptable,
      mtrAcceptableNa: draft.mtrAcceptableNa,
      acceptanceStatus: draft.acceptanceStatus.trim().isEmpty
          ? 'accept'
          : draft.acceptanceStatus.trim(),
      comments: draft.comments.trim(),
      qcInspectorName: draft.qcInspectorName.trim(),
      qcManagerName: draft.qcManagerName.trim(),
      qcSignaturePath: draft.qcSignaturePath.trim(),
      qcManagerSignaturePath: draft.qcManagerSignaturePath.trim(),
      materialApproval: draft.acceptanceStatus.trim().toLowerCase() == 'accept'
          ? 'approved'
          : 'hold',
      offloadStatus: '',
      pdfStatus: '',
      pdfStoragePath: '',
      photoPaths: draft.photoPaths,
      scanPaths: draft.scanPaths,
      photoCount: draft.photoPaths.length,
      createdAt: existingMaterialId.isEmpty
          ? DateTime.now()
          : materialById(
              jobId: draft.jobId,
              materialId: existingMaterialId,
            ).createdAt,
    );

    final job = jobById(draft.jobId);
    final updatedMaterials = existingMaterialId.isEmpty
        ? [...job.materials, material]
        : [
            for (final existing in job.materials)
              if (existing.id == existingMaterialId) material else existing,
          ];
    final updatedJob = job.copyWith(materials: updatedMaterials);
    _jobs = [
      for (final existing in _jobs)
        if (existing.id == job.id) updatedJob else existing,
    ];
    _drafts = _drafts
        .where((item) => item.id != draft.id)
        .toList(growable: false);
    notifyListeners();
    await _persistSnapshot();
  }

  Future<void> deleteMaterial({
    required String jobId,
    required String materialId,
  }) async {
    _jobs = _jobs
        .map((job) {
          if (job.id != jobId) {
            return job;
          }
          return job.copyWith(
            materials: job.materials
                .where((material) => material.id != materialId)
                .toList(growable: false),
          );
        })
        .toList(growable: false);

    _drafts = _drafts
        .where(
          (draft) =>
              !(draft.jobId == jobId && draft.sourceMaterialId == materialId),
        )
        .toList(growable: false);
    notifyListeners();
    await _persistSnapshot();
  }

  Future<void> saveCustomization(CustomizationSettings nextSettings) async {
    _customization = nextSettings;
    notifyListeners();
    await _customizationStore.save(nextSettings);
  }

  Future<void> refreshBackendHealth() async {
    _isCheckingBackendHealth = true;
    notifyListeners();
    try {
      _backendHealth = await _backendApiService.fetchHealth();
      _backendHealthError = null;
    } catch (error) {
      _backendHealth = null;
      _backendHealthError = error.toString();
    } finally {
      _isCheckingBackendHealth = false;
      notifyListeners();
    }
  }

  Future<JobExportResult> exportJob(String jobId) async {
    final job = jobById(jobId);
    final exportResult = await _exportService.exportJob(
      job: job,
      customization: _customization,
    );

    final updatedJob = job.copyWith(
      exportedAt: DateTime.now(),
      exportPath: exportResult.exportRootPath,
      materials: [
        for (final material in job.materials)
          material.copyWith(
            pdfStatus:
                exportResult.packetPathsByMaterialId.containsKey(material.id)
                ? 'exported'
                : material.pdfStatus,
            pdfStoragePath:
                exportResult.packetPathsByMaterialId[material.id] ??
                material.pdfStoragePath,
          ),
      ],
    );

    _jobs = [
      for (final existing in _jobs)
        if (existing.id == jobId) updatedJob else existing,
    ];
    notifyListeners();
    await _persistSnapshot();
    return exportResult;
  }

  Future<bool> shareLatestExportPdfs(String jobId) async {
    final job = jobById(jobId);
    if (job.exportPath.trim().isEmpty) {
      return false;
    }
    return _exportService.sharePdfPackets(job.exportPath);
  }

  Future<bool> shareLatestExportZip(String jobId) async {
    final job = jobById(jobId);
    if (job.exportPath.trim().isEmpty) {
      return false;
    }
    final zipPath =
        '${job.exportPath}${job.exportPath.endsWith(r'\') || job.exportPath.endsWith('/') ? '' : Platform.pathSeparator}${job.exportPath.split(RegExp(r'[\\/]')).last}.zip';
    return _exportService.shareZipBundle(zipPath);
  }

  Future<void> _persistSnapshot() {
    return _snapshotStore.save(
      MaterialGuardianSnapshot(jobs: _jobs, drafts: _drafts),
    );
  }
}
