import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/backend_auth_session_store.dart';
import '../data/customization_store.dart';
import '../data/material_guardian_snapshot_store.dart';
import '../services/android_export_bridge.dart';
import '../services/backend_api_service.dart';
import '../services/customization_asset_service.dart';
import '../services/job_export_service.dart';
import '../services/material_media_service.dart';
import '../services/storage_utils.dart';
import '../services/store_purchase_service.dart';
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
    required BackendAuthSessionStore authSessionStore,
    required StorePurchaseService storePurchaseService,
    required MaterialMediaService mediaService,
    required JobExportService exportService,
  }) : _jobs = jobs,
       _drafts = drafts,
       _customization = customization,
       _snapshotStore = snapshotStore,
       _customizationStore = customizationStore,
       _customizationAssetService = customizationAssetService,
       _backendApiService = backendApiService,
       _authSessionStore = authSessionStore,
       _storePurchaseService = storePurchaseService,
       _mediaService = mediaService,
       _exportService = exportService {
    _storePurchaseUpdatesSubscription = _storePurchaseService.purchaseUpdates
        .listen(_handleStorePurchaseUpdates);
  }

  factory MaterialGuardianAppState.seeded({
    BackendApiService? backendApiService,
    BackendAuthSessionStore? authSessionStore,
    StorePurchaseService? storePurchaseService,
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
            heatNumber: '',
            thickness1: '',
            thickness2: '',
            thickness3: '',
            thickness4: '',
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
            markingSelected: true,
            mtrAcceptable: true,
            mtrAcceptableNa: false,
            mtrSelected: true,
            acceptanceStatus: 'accept',
            comments: '',
            quantity: '2',
            qcInspectorName: 'Kevin Penfield',
            qcInspectorDate: DateTime(2026, 3, 31),
            qcManagerName: 'Shop QA',
            qcManagerDate: DateTime(2026, 3, 31),
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
        description: 'Unfinished receiving report',
        vendor: '',
        poNumber: '',
        productType: '',
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
        thickness2: '',
        thickness3: '',
        thickness4: '',
        width: '',
        length: '',
        diameter: '',
        diameterType: '',
        visualInspectionAcceptable: true,
        surfaceFinish: '',
        surfaceFinishReading: '',
        surfaceFinishUnit: customization.surfaceFinishUnit,
        markings: '',
        markingAcceptable: false,
        markingAcceptableNa: false,
        markingSelected: false,
        mtrAcceptable: false,
        mtrAcceptableNa: false,
        mtrSelected: false,
        comments: '',
        acceptanceStatus: 'accept',
        qcInspectorName: customization.defaultQcInspectorName,
        qcInspectorDate: DateTime(2026, 4, 1),
        qcManagerName: customization.defaultQcManagerName,
        qcManagerDate: DateTime(2026, 4, 1),
        qcSignaturePath: '',
        qcManagerSignaturePath: '',
        materialApproval: 'approved',
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
      authSessionStore: authSessionStore ?? InMemoryBackendAuthSessionStore(),
      storePurchaseService:
          storePurchaseService ?? _defaultStorePurchaseService(),
      mediaService: MaterialMediaService(),
      exportService: JobExportService(),
    );
  }

  factory MaterialGuardianAppState.seededSignedIn({
    BackendApiService? backendApiService,
    BackendAuthSessionStore? authSessionStore,
    StorePurchaseService? storePurchaseService,
  }) {
    final appState = MaterialGuardianAppState.seeded(
      backendApiService: backendApiService,
      authSessionStore: authSessionStore,
      storePurchaseService: storePurchaseService,
    );
    final signedInAt = DateTime(2026, 4, 3, 12);
    final activeEntitlement = BackendEntitlementSnapshot(
      productCode: 'material_guardian',
      planCode: 'material_guardian_individual_yearly',
      accessState: 'paid',
      seatAvailability: 'assigned',
      subscriptionState: 'active',
      trialRemaining: 0,
      organizationId: null,
      startsAt: signedInAt,
      endsAt: null,
    );
    appState._backendAuthSession = const StoredBackendAuthSession(
      accessToken: 'debug-seeded-access-token',
      refreshToken: 'debug-seeded-refresh-token',
    );
    appState._backendMe = BackendMeSnapshot(
      user: BackendUserSummary(
        id: 'debug_user',
        email: 'debug@materialguardian.test',
        displayName: 'Debug Solo User',
        status: 'active',
        createdAt: signedInAt,
        lastLoginAt: signedInAt,
      ),
      memberships: const <BackendMembershipSummary>[],
      currentSeatOrganizationId: null,
      currentSeatStatus: 'not_applicable',
      trialState: null,
      activeEntitlement: activeEntitlement,
      activeSession: BackendSessionSnapshot(
        id: 'debug-session',
        deviceLabel: 'Debug Seeded Session',
        platform: 'android',
        status: 'active',
        issuedAt: signedInAt,
        lastSeenAt: signedInAt,
        revokedAt: null,
      ),
    );
    appState._backendEntitlement = activeEntitlement;
    return appState;
  }

  static Future<MaterialGuardianAppState> create({
    BackendApiService? backendApiService,
    BackendAuthSessionStore? authSessionStore,
    StorePurchaseService? storePurchaseService,
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
      authSessionStore:
          authSessionStore ?? SharedPreferencesBackendAuthSessionStore(),
      storePurchaseService:
          storePurchaseService ?? _defaultStorePurchaseService(),
      mediaService: MaterialMediaService(),
      exportService: JobExportService(),
    );
    await appState.refreshBackendHealth();
    await appState.restoreBackendSession();
    await appState.loadPurchaseCatalog();
    return appState;
  }

  final MaterialGuardianSnapshotStore _snapshotStore;
  final CustomizationStore _customizationStore;
  final CustomizationAssetService _customizationAssetService;
  final BackendApiService _backendApiService;
  final BackendAuthSessionStore _authSessionStore;
  final StorePurchaseService _storePurchaseService;
  final MaterialMediaService _mediaService;
  final JobExportService _exportService;
  late final StreamSubscription<List<StorePurchaseUpdate>>
  _storePurchaseUpdatesSubscription;

  List<JobRecord> _jobs;
  List<MaterialDraft> _drafts;
  CustomizationSettings _customization;
  BackendHealthSnapshot? _backendHealth;
  String? _backendHealthError;
  StoredBackendAuthSession? _backendAuthSession;
  BackendAuthStartSnapshot? _pendingBackendAuthStart;
  BackendSessionConflictSnapshot? _pendingSessionConflict;
  String? _pendingSessionReplacementId;
  BackendMeSnapshot? _backendMe;
  BackendEntitlementSnapshot? _backendEntitlement;
  BackendOrganizationSummary? _backendOrganization;
  List<BackendPlanSnapshot> _backendPlans = const <BackendPlanSnapshot>[];
  Map<String, StoreProductSnapshot> _storeProductsById =
      const <String, StoreProductSnapshot>{};
  List<String> _lastMissingStoreProductIds = const <String>[];
  String? _lastStoreCatalogError;
  String? _backendAccountError;
  String? _purchaseStatusMessage;
  String? _purchaseError;
  bool _isCheckingBackendHealth = false;
  bool _isAuthenticatingBackend = false;
  bool _isRefreshingBackendAccount = false;
  bool _isLoadingPurchaseCatalog = false;
  bool _isPurchasing = false;
  bool _isRestoringPurchases = false;
  bool _isStoreAvailable = false;
  bool _shouldSurfaceSalesAuthError = false;
  final Map<String, String?> _pendingPurchaseOrganizationIdsByProductId =
      <String, String?>{};

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
  StoredBackendAuthSession? get backendAuthSession => _backendAuthSession;
  BackendAuthStartSnapshot? get pendingBackendAuthStart =>
      _pendingBackendAuthStart;
  BackendSessionConflictSnapshot? get pendingSessionConflict =>
      _pendingSessionConflict;
  String? get pendingSessionReplacementId => _pendingSessionReplacementId;
  BackendMeSnapshot? get backendMe => _backendMe;
  BackendEntitlementSnapshot? get backendEntitlement => _backendEntitlement;
  BackendOrganizationSummary? get backendOrganization => _backendOrganization;
  List<BackendPlanSnapshot> get backendPlans =>
      List.unmodifiable(_backendPlans);
  Map<String, StoreProductSnapshot> get storeProductsById =>
      Map.unmodifiable(_storeProductsById);
  String get currentStorePlatform => _storePlatform();
  List<String> get lastMissingStoreProductIds =>
      List.unmodifiable(_lastMissingStoreProductIds);
  String? get lastStoreCatalogError => _lastStoreCatalogError;
  String? get backendAccountError => _backendAccountError;
  String? get purchaseStatusMessage => _purchaseStatusMessage;
  String? get purchaseError => _purchaseError;
  bool get isAuthenticatingBackend => _isAuthenticatingBackend;
  bool get isRefreshingBackendAccount => _isRefreshingBackendAccount;
  bool get isLoadingPurchaseCatalog => _isLoadingPurchaseCatalog;
  bool get isPurchasing => _isPurchasing;
  bool get isRestoringPurchases => _isRestoringPurchases;
  bool get isStoreAvailable => _isStoreAvailable;
  bool get shouldSurfaceSalesAuthError => _shouldSurfaceSalesAuthError;
  bool get isSignedIn => _backendAuthSession != null && _backendMe != null;
  bool get hasPendingSessionReplacement => _pendingSessionReplacementId != null;
  BackendEntitlementSnapshot? get effectiveBackendEntitlement =>
      _backendEntitlement ?? _backendMe?.activeEntitlement;
  BackendMembershipSummary? get activeOrganizationMembership =>
      _membershipForCurrentEntitlement();
  bool get hasBusinessMembership => activeOrganizationMembership != null;
  bool get isBusinessAdmin => activeOrganizationMembership?.isAdmin ?? false;
  bool get hasAdminLikeWorkspaceAccess =>
      !hasBusinessMembership || isBusinessAdmin;
  bool get shouldShowAccountEntry => isSignedIn && hasAdminLikeWorkspaceAccess;
  bool get shouldShowCustomizationEntry => isSignedIn;
  bool get shouldUseSalesLaunch => !isSignedIn;
  bool get hasUsableJobAccess {
    final accessState = effectiveBackendEntitlement?.accessState;
    return accessState == 'paid' || accessState == 'trial';
  }

  bool get isTrialAccess => effectiveBackendEntitlement?.accessState == 'trial';
  bool get isLockedFromSubscription =>
      effectiveBackendEntitlement?.accessState == 'locked';
  bool get isSeatBlocked =>
      effectiveBackendEntitlement?.accessState == 'no_seat' ||
      effectiveBackendEntitlement?.seatAvailability == 'unassigned';
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
    final existingIndex = _jobs.indexWhere((job) => job.id == jobId);
    if (existingIndex < 0) {
      return;
    }
    final job = _jobs[existingIndex];
    final relatedDrafts = _drafts
        .where((draft) => draft.jobId == jobId)
        .toList(growable: false);
    await _deleteJobFiles(job, relatedDrafts);
    _jobs = _jobs.where((job) => job.id != jobId).toList(growable: false);
    _drafts = _drafts
        .where((draft) => draft.jobId != jobId)
        .toList(growable: false);
    notifyListeners();
    await _persistSnapshot();
  }

  Future<void> _deleteJobFiles(
    JobRecord job,
    List<MaterialDraft> relatedDrafts,
  ) async {
    final safeJobNumber = safeBaseName(job.jobNumber, fallback: 'job');
    final cleanupDirectories = <String>{
      if (job.exportPath.trim().isNotEmpty) job.exportPath.trim(),
      (await appSupportSubdirectory(['exports', safeJobNumber])).path,
      (await appSupportSubdirectory(['job_media', safeJobNumber])).path,
    };

    for (final material in job.materials) {
      cleanupDirectories.addAll(_jobMediaRootsForMaterialRecord(material));
    }
    for (final draft in relatedDrafts) {
      cleanupDirectories.addAll(_jobMediaRootsForDraft(draft));
    }

    for (final directoryPath in cleanupDirectories) {
      await _deleteDirectoryIfPresent(directoryPath);
    }

    final exportZipPaths = <String>{
      if (job.exportPath.trim().isNotEmpty) _zipPathForExportRoot(job.exportPath),
      _zipPathForExportRoot(
        (await appSupportSubdirectory(['exports', safeJobNumber])).path,
      ),
    };
    for (final zipPath in exportZipPaths) {
      await _deleteFileIfPresent(zipPath);
    }

    final downloadsDirectories = <String>{
      'MaterialGuardian/$safeJobNumber',
      if (job.exportPath.trim().isNotEmpty)
        'MaterialGuardian/${_exportRootBaseName(job.exportPath)}',
    };
    for (final downloadsDirectory in downloadsDirectories) {
      try {
        await AndroidExportBridge.deleteDownloadsExport(
          downloadsSubdirectory: downloadsDirectory,
        );
      } catch (error, stackTrace) {
        debugPrint('Job delete Downloads cleanup failed: $error\n$stackTrace');
      }
    }
  }

  Set<String> _jobMediaRootsForMaterialRecord(MaterialRecord material) {
    return {
      ..._jobMediaRootsFromPaths(material.photoPaths),
      ..._jobMediaRootsFromPaths(material.scanPaths),
      if (material.qcSignaturePath.trim().isNotEmpty)
        ..._jobMediaRootsFromPaths([material.qcSignaturePath]),
      if (material.qcManagerSignaturePath.trim().isNotEmpty)
        ..._jobMediaRootsFromPaths([material.qcManagerSignaturePath]),
    };
  }

  Set<String> _jobMediaRootsForDraft(MaterialDraft draft) {
    return {
      ..._jobMediaRootsFromPaths(draft.photoPaths),
      ..._jobMediaRootsFromPaths(draft.scanPaths),
      if (draft.qcSignaturePath.trim().isNotEmpty)
        ..._jobMediaRootsFromPaths([draft.qcSignaturePath]),
      if (draft.qcManagerSignaturePath.trim().isNotEmpty)
        ..._jobMediaRootsFromPaths([draft.qcManagerSignaturePath]),
    };
  }

  Set<String> _jobMediaRootsFromPaths(List<String> paths) {
    final roots = <String>{};
    for (final rawPath in paths) {
      final normalized = rawPath.trim();
      if (normalized.isEmpty) {
        continue;
      }
      final file = File(normalized);
      final firstParent = file.parent;
      if (firstParent.path == normalized) {
        continue;
      }
      final secondParent = firstParent.parent;
      if (secondParent.path == firstParent.path) {
        continue;
      }
      roots.add(secondParent.path);
    }
    return roots;
  }

  Future<void> _deleteDirectoryIfPresent(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return;
    }
    final directory = Directory(normalized);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> _deleteFileIfPresent(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return;
    }
    final file = File(normalized);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _zipPathForExportRoot(String exportRootPath) {
    final normalized = exportRootPath.trim();
    if (normalized.isEmpty) {
      return normalized;
    }
    final separator = normalized.endsWith(r'\') || normalized.endsWith('/')
        ? ''
        : Platform.pathSeparator;
    final baseName = _exportRootBaseName(normalized);
    return '$normalized$separator$baseName.zip';
  }

  String _exportRootBaseName(String exportRootPath) {
    final normalized = exportRootPath.trim();
    if (normalized.isEmpty) {
      return 'job';
    }
    final trimmed = normalized.replaceAll(RegExp(r'[\\/]+$'), '');
    final segments = trimmed.split(RegExp(r'[\\/]'));
    return segments.isEmpty ? 'job' : segments.last;
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
      thickness2: '',
      thickness3: '',
      thickness4: '',
      width: '',
      length: '',
      diameter: '',
      diameterType: '',
      visualInspectionAcceptable: true,
      surfaceFinish: '',
      surfaceFinishReading: '',
      surfaceFinishUnit: _customization.surfaceFinishUnit,
      markings: '',
      markingAcceptable: false,
      markingAcceptableNa: false,
      markingSelected: false,
      mtrAcceptable: false,
      mtrAcceptableNa: false,
      mtrSelected: false,
      comments: '',
      acceptanceStatus: 'accept',
      qcInspectorName: _customization.defaultQcInspectorName,
      qcInspectorDate: DateTime.now(),
      qcManagerName: _customization.defaultQcManagerName,
      qcManagerDate: DateTime.now(),
      qcSignaturePath: '',
      qcManagerSignaturePath: '',
      materialApproval: 'approved',
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
      thickness2: material.thickness2,
      thickness3: material.thickness3,
      thickness4: material.thickness4,
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
      markingSelected: material.markingSelected,
      mtrAcceptable: material.mtrAcceptable,
      mtrAcceptableNa: material.mtrAcceptableNa,
      mtrSelected: material.mtrSelected,
      comments: material.comments,
      acceptanceStatus: material.acceptanceStatus,
      qcInspectorName: material.qcInspectorName,
      qcInspectorDate: material.qcInspectorDate,
      qcManagerName: material.qcManagerName,
      qcManagerDate: material.qcManagerDate,
      qcSignaturePath: material.qcSignaturePath,
      qcManagerSignaturePath: material.qcManagerSignaturePath,
      materialApproval: material.materialApproval,
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
    final job = jobById(draft.jobId);
    MaterialRecord? existingMaterial;
    if (existingMaterialId.isNotEmpty) {
      for (final material in job.materials) {
        if (material.id == existingMaterialId) {
          existingMaterial = material;
          break;
        }
      }
    }
    final material = MaterialRecord(
      id: existingMaterialId.isEmpty
          ? 'mat-${DateTime.now().microsecondsSinceEpoch}'
          : existingMaterialId,
      tag: draft.materialTag.trim().isEmpty
          ? (draft.description.trim().isEmpty
                ? 'Receiving report item'
                : draft.description.trim())
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
      thickness2: draft.thickness2.trim(),
      thickness3: draft.thickness3.trim(),
      thickness4: draft.thickness4.trim(),
      width: draft.width.trim(),
      length: draft.length.trim(),
      diameter: draft.diameter.trim(),
      diameterType: draft.diameterType.trim(),
      visualInspectionAcceptable: draft.visualInspectionAcceptable,
      b16DimensionsAcceptable: draft.b16Size.trim(),
      surfaceFinishCode: draft.surfaceFinish.trim(),
      surfaceFinishReading: draft.surfaceFinishReading.trim(),
      surfaceFinishUnit: draft.surfaceFinishUnit.trim(),
      markings: draft.markings.trim(),
      markingAcceptable: draft.markingAcceptable,
      markingAcceptableNa: draft.markingAcceptableNa,
      markingSelected: draft.markingSelected,
      mtrAcceptable: draft.mtrAcceptable,
      mtrAcceptableNa: draft.mtrAcceptableNa,
      mtrSelected: draft.mtrSelected,
      acceptanceStatus: draft.acceptanceStatus.trim().isEmpty
          ? 'accept'
          : draft.acceptanceStatus.trim(),
      comments: draft.comments.trim(),
      qcInspectorName: draft.qcInspectorName.trim(),
      qcInspectorDate: draft.qcInspectorDate,
      qcManagerName: draft.qcManagerName.trim(),
      qcManagerDate: draft.qcManagerDate,
      qcSignaturePath: draft.qcSignaturePath.trim(),
      qcManagerSignaturePath: draft.qcManagerSignaturePath.trim(),
      materialApproval: draft.materialApproval.trim().isEmpty
          ? 'approved'
          : draft.materialApproval.trim(),
      offloadStatus: '',
      pdfStatus: '',
      pdfStoragePath: '',
      photoPaths: draft.photoPaths,
      scanPaths: draft.scanPaths,
      photoCount: draft.photoPaths.length,
      createdAt: existingMaterial?.createdAt ?? DateTime.now(),
    );

    final updatedMaterials = existingMaterial == null
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

  Future<void> loadPurchaseCatalog() async {
    _isLoadingPurchaseCatalog = true;
    _purchaseError = null;
    _lastStoreCatalogError = null;
    _lastMissingStoreProductIds = const <String>[];
    notifyListeners();

    try {
      final plans = await _backendApiService.fetchPlans();
      final storeAvailable = await _storePurchaseService.isAvailable();
      final productIds = plans
          .map((plan) => plan.storeProductIdForPlatform(_storePlatform()))
          .whereType<String>()
          .where((productId) => productId.trim().isNotEmpty)
          .toSet();
      final queryResult = storeAvailable
          ? await _storePurchaseService.queryProducts(productIds)
          : const StoreProductQueryResult(
              products: <StoreProductSnapshot>[],
              notFoundIds: <String>[],
              errorMessage: null,
            );

      _backendPlans = plans;
      _isStoreAvailable = storeAvailable;
      _storeProductsById = <String, StoreProductSnapshot>{
        for (final product in queryResult.products) product.id: product,
      };
      _lastMissingStoreProductIds = queryResult.notFoundIds;
      _lastStoreCatalogError = queryResult.errorMessage;

      if (!storeAvailable) {
        _purchaseError =
            'The store is unavailable on this build or device. Use the Play-installed internal test app.';
      } else if (queryResult.errorMessage != null &&
          queryResult.errorMessage!.trim().isNotEmpty) {
        _purchaseError =
            'Store catalog lookup failed: ${queryResult.errorMessage}';
      } else if (queryResult.notFoundIds.isNotEmpty) {
        _purchaseError =
            'Play did not return these product IDs: ${queryResult.notFoundIds.join(', ')}';
      } else if (productIds.isNotEmpty && queryResult.products.isEmpty) {
        _purchaseError =
            'Play billing is available, but no subscription product details were returned for this account/build yet.';
      }
    } catch (error) {
      _purchaseError = error.toString();
    } finally {
      _isLoadingPurchaseCatalog = false;
      notifyListeners();
    }
  }

  Future<void> restoreBackendSession() async {
    final storedSession = await _authSessionStore.load();
    if (storedSession == null) {
      return;
    }

    _backendAuthSession = storedSession;
    await refreshBackendAccount(showFailureMessage: false);
  }

  Future<void> startBackendSignIn({
    required String email,
    String? displayName,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      _backendAccountError = 'Email is required to start sign-in.';
      notifyListeners();
      return;
    }
    if (!_looksLikeEmail(normalizedEmail)) {
      _backendAccountError = 'Enter a valid email address.';
      notifyListeners();
      return;
    }

    _isAuthenticatingBackend = true;
    _shouldSurfaceSalesAuthError = true;
    _backendAccountError = null;
    _pendingSessionConflict = null;
    _pendingSessionReplacementId = null;
    notifyListeners();

    try {
      _pendingBackendAuthStart = await _backendApiService.startAuth(
        email: normalizedEmail,
        displayName: displayName?.trim().isEmpty ?? true
            ? null
            : displayName!.trim(),
      );
    } catch (error) {
      _backendAccountError = error.toString();
    } finally {
      _isAuthenticatingBackend = false;
      notifyListeners();
    }
  }

  Future<void> completeBackendSignIn({
    required String code,
    String? deviceLabel,
    String? platform,
  }) async {
    final authStart = _pendingBackendAuthStart;
    if (authStart == null) {
      _backendAccountError = 'Start sign-in before entering a code.';
      notifyListeners();
      return;
    }

    _isAuthenticatingBackend = true;
    _shouldSurfaceSalesAuthError = true;
    _backendAccountError = null;
    notifyListeners();

    try {
      final result = await _backendApiService.completeAuth(
        flowId: authStart.flowId,
        email: authStart.deliveryTarget,
        code: code.trim(),
        deviceLabel: deviceLabel?.trim().isEmpty ?? true
            ? _defaultDeviceLabel()
            : deviceLabel!.trim(),
        platform: platform ?? _defaultSessionPlatform(),
      );

      if (result.requiresSessionReplacement) {
        _pendingSessionReplacementId = result.pendingSessionId;
        _pendingSessionConflict = result.conflict;
        _backendAccountError =
            'Another active session exists. Replace it to finish signing in.';
        return;
      }

      await _acceptAuthenticatedBackendResult(result);
    } catch (error) {
      _backendAccountError = _describeBackendAuthError(error);
    } finally {
      _isAuthenticatingBackend = false;
      notifyListeners();
    }
  }

  Future<void> replacePendingBackendSession() async {
    final pendingSessionId = _pendingSessionReplacementId;
    if (pendingSessionId == null) {
      return;
    }

    _isAuthenticatingBackend = true;
    _shouldSurfaceSalesAuthError = true;
    _backendAccountError = null;
    notifyListeners();

    try {
      final result = await _backendApiService.replaceSession(
        pendingSessionId: pendingSessionId,
      );
      await _acceptAuthenticatedBackendResult(result);
    } catch (error) {
      _backendAccountError = _describeBackendAuthError(error);
    } finally {
      _isAuthenticatingBackend = false;
      notifyListeners();
    }
  }

  Future<void> createOrganization({required String name}) async {
    final session = _backendAuthSession;
    if (session == null) {
      _backendAccountError = 'Sign in before creating an organization.';
      notifyListeners();
      return;
    }

    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      _backendAccountError = 'Organization name is required.';
      notifyListeners();
      return;
    }

    _isAuthenticatingBackend = true;
    _backendAccountError = null;
    notifyListeners();

    try {
      final result = await _backendApiService.createOrganization(
        name: normalizedName,
        accessToken: session.accessToken,
      );
      _backendOrganization = result.organization;
      await _hydrateBackendAccount(accessToken: session.accessToken);
    } catch (error) {
      _backendAccountError = error.toString();
    } finally {
      _isAuthenticatingBackend = false;
      notifyListeners();
    }
  }

  Future<void> refreshBackendAccount({bool showFailureMessage = true}) async {
    final session = _backendAuthSession;
    if (session == null) {
      return;
    }

    _isRefreshingBackendAccount = true;
    _backendAccountError = null;
    notifyListeners();

    try {
      final refreshed = await _backendApiService.refreshSession(
        refreshToken: session.refreshToken,
      );
      await _acceptAuthenticatedBackendResult(
        refreshed,
        hydrateFromAccessToken: true,
      );
    } catch (error) {
      await _clearBackendAuthState(
        errorMessage: showFailureMessage
            ? 'Saved backend session could not be refreshed. Sign in again.'
            : null,
      );
    } finally {
      _isRefreshingBackendAccount = false;
      notifyListeners();
    }
  }

  Future<void> purchasePlan({required String planCode}) async {
    final session = _backendAuthSession;
    if (session == null) {
      _purchaseError = 'Sign in before purchasing a plan.';
      notifyListeners();
      return;
    }

    BackendPlanSnapshot? plan;
    for (final currentPlan in _backendPlans) {
      if (currentPlan.planCode == planCode) {
        plan = currentPlan;
        break;
      }
    }
    if (plan == null) {
      _purchaseError =
          'Plan $planCode is not available in the billing catalog.';
      notifyListeners();
      return;
    }

    final productId = plan.storeProductIdForPlatform(_storePlatform());
    if (productId == null || productId.trim().isEmpty) {
      _purchaseError = 'This plan is not available for the current platform.';
      notifyListeners();
      return;
    }

    if (!_storeProductsById.containsKey(productId)) {
      _purchaseError = 'Store product $productId has not been loaded yet.';
      notifyListeners();
      return;
    }

    final organizationId = _currentPurchaseOrganizationIdForPlan(plan);
    if (plan.isBusiness && (organizationId == null || organizationId.isEmpty)) {
      _purchaseError =
          'Create or select your organization before buying a business plan.';
      notifyListeners();
      return;
    }

    _isPurchasing = true;
    _purchaseError = null;
    _purchaseStatusMessage = 'Starting purchase for ${plan.displayPrice}.';
    _pendingPurchaseOrganizationIdsByProductId[productId] = organizationId;
    notifyListeners();

    try {
      await _storePurchaseService.buyProduct(productId);
    } catch (error) {
      _isPurchasing = false;
      _purchaseError = error.toString();
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    _isRestoringPurchases = true;
    _purchaseError = null;
    _purchaseStatusMessage = 'Checking the store for existing purchases.';
    notifyListeners();

    try {
      await _storePurchaseService.restorePurchases();
      _purchaseStatusMessage = null;
    } catch (error) {
      _purchaseStatusMessage = null;
      _purchaseError = error.toString();
    } finally {
      _isRestoringPurchases = false;
      notifyListeners();
    }
  }

  Future<void> logoutBackend() async {
    final session = _backendAuthSession;
    if (session == null) {
      return;
    }

    _isAuthenticatingBackend = true;
    _backendAccountError = null;
    notifyListeners();

    try {
      await _backendApiService.logout(accessToken: session.accessToken);
    } catch (_) {
      // Clear local auth state even if the server-side revoke request fails.
    } finally {
      await _clearBackendAuthState();
      _isAuthenticatingBackend = false;
      notifyListeners();
    }
  }

  Future<void> redeemOrganizationAccess({
    required String organizationId,
    required String code,
  }) async {
    final session = _backendAuthSession;
    if (session == null) {
      _backendAccountError = 'Sign in before redeeming an organization code.';
      notifyListeners();
      return;
    }

    _isAuthenticatingBackend = true;
    _backendAccountError = null;
    notifyListeners();

    try {
      await _backendApiService.redeemOrganizationAccess(
        organizationId: organizationId.trim(),
        code: code.trim(),
        accessToken: session.accessToken,
      );
      await _hydrateBackendAccount(accessToken: session.accessToken);
    } catch (error) {
      _backendAccountError = error.toString();
    } finally {
      _isAuthenticatingBackend = false;
      notifyListeners();
    }
  }

  Future<BackendInviteOrganizationMemberResult?> inviteOrganizationMember({
    required String organizationId,
    required String email,
    String? displayName,
    String role = 'member',
  }) async {
    final session = _backendAuthSession;
    if (session == null) {
      _backendAccountError = 'Sign in before inviting organization members.';
      notifyListeners();
      return null;
    }

    _isAuthenticatingBackend = true;
    _backendAccountError = null;
    notifyListeners();

    try {
      final result = await _backendApiService.inviteOrganizationMember(
        organizationId: organizationId,
        accessToken: session.accessToken,
        email: email.trim(),
        displayName: displayName?.trim().isEmpty ?? true
            ? null
            : displayName!.trim(),
        role: role,
      );
      _backendOrganization = result.organization;
      return result;
    } catch (error) {
      _backendAccountError = error.toString();
      return null;
    } finally {
      _isAuthenticatingBackend = false;
      notifyListeners();
    }
  }

  Future<void> resendOrganizationMemberAccess({
    required String organizationId,
    required String membershipId,
  }) async {
    final session = _backendAuthSession;
    if (session == null) {
      _backendAccountError = 'Sign in before resending organization access.';
      notifyListeners();
      return;
    }

    _isAuthenticatingBackend = true;
    _backendAccountError = null;
    notifyListeners();

    try {
      final result = await _backendApiService.resendOrganizationMemberAccess(
        organizationId: organizationId,
        membershipId: membershipId,
        accessToken: session.accessToken,
      );
      _backendOrganization = result.organization;
    } catch (error) {
      _backendAccountError = error.toString();
    } finally {
      _isAuthenticatingBackend = false;
      notifyListeners();
    }
  }

  Future<void> updateOrganizationMemberSeat({
    required String organizationId,
    required String membershipId,
    required bool assignSeat,
  }) async {
    final session = _backendAuthSession;
    if (session == null) {
      _backendAccountError = 'Sign in before updating organization seats.';
      notifyListeners();
      return;
    }

    _isAuthenticatingBackend = true;
    _backendAccountError = null;
    notifyListeners();

    try {
      final result = await _backendApiService.updateOrganizationMemberSeat(
        organizationId: organizationId,
        membershipId: membershipId,
        accessToken: session.accessToken,
        assignSeat: assignSeat,
      );
      _backendOrganization = result.organization;
      await _hydrateBackendAccount(accessToken: session.accessToken);
    } catch (error) {
      _backendAccountError = error.toString();
    } finally {
      _isAuthenticatingBackend = false;
      notifyListeners();
    }
  }

  Future<void> removeOrganizationMember({
    required String organizationId,
    required String membershipId,
  }) async {
    final session = _backendAuthSession;
    if (session == null) {
      _backendAccountError = 'Sign in before removing organization members.';
      notifyListeners();
      return;
    }

    _isAuthenticatingBackend = true;
    _backendAccountError = null;
    notifyListeners();

    try {
      final result = await _backendApiService.removeOrganizationMember(
        organizationId: organizationId,
        membershipId: membershipId,
        accessToken: session.accessToken,
      );
      _backendOrganization = result.organization;
      await _hydrateBackendAccount(accessToken: session.accessToken);
    } catch (error) {
      _backendAccountError = error.toString();
    } finally {
      _isAuthenticatingBackend = false;
      notifyListeners();
    }
  }

  Future<void> _acceptAuthenticatedBackendResult(
    BackendAuthResult result, {
    bool hydrateFromAccessToken = true,
  }) async {
    final accessToken = result.accessToken;
    final refreshToken = result.refreshToken;
    if (!result.isAuthenticated ||
        accessToken == null ||
        refreshToken == null) {
      throw StateError(
        'Backend auth did not finish with an authenticated session.',
      );
    }

    _pendingBackendAuthStart = null;
    _pendingSessionConflict = null;
    _pendingSessionReplacementId = null;
    _shouldSurfaceSalesAuthError = false;
    _backendAuthSession = StoredBackendAuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _authSessionStore.save(_backendAuthSession!);

    if (hydrateFromAccessToken) {
      await _hydrateBackendAccount(accessToken: accessToken);
    }
  }

  Future<void> _hydrateBackendAccount({required String accessToken}) async {
    final me = await _backendApiService.fetchMe(accessToken: accessToken);
    final entitlement = await _backendApiService.fetchCurrentEntitlement(
      accessToken: accessToken,
    );

    BackendOrganizationSummary? organization;
    final adminMembership = _firstAdminMembership(me.memberships);
    if (adminMembership != null && adminMembership.isAccepted) {
      try {
        organization = await _backendApiService.fetchOrganizationSummary(
          organizationId: adminMembership.organizationId,
          accessToken: accessToken,
        );
      } catch (_) {
        organization = null;
      }
    }

    _backendMe = me;
    _backendEntitlement = entitlement;
    _backendOrganization = organization;
    _backendAccountError = null;
  }

  Future<void> _handleStorePurchaseUpdates(
    List<StorePurchaseUpdate> updates,
  ) async {
    if (updates.isEmpty) {
      return;
    }

    for (final update in updates) {
      if (update.isPending) {
        _isPurchasing = true;
        _isRestoringPurchases = false;
        _purchaseStatusMessage =
            'Waiting for the store to finish ${update.productId}.';
        _purchaseError = null;
        notifyListeners();
        continue;
      }

      if (update.isCanceled) {
        _isPurchasing = false;
        _isRestoringPurchases = false;
        _purchaseStatusMessage = 'Purchase canceled.';
        _purchaseError = null;
        _pendingPurchaseOrganizationIdsByProductId.remove(update.productId);
        notifyListeners();
        continue;
      }

      if (update.isError) {
        _isPurchasing = false;
        _isRestoringPurchases = false;
        _purchaseError = update.errorMessage ?? 'The store purchase failed.';
        _purchaseStatusMessage = null;
        _pendingPurchaseOrganizationIdsByProductId.remove(update.productId);
        if (update.pendingCompletePurchase) {
          await _storePurchaseService.completePurchase(update.productId);
        }
        notifyListeners();
        continue;
      }

      if (!update.isPurchased && !update.isRestored) {
        continue;
      }

      final session = _backendAuthSession;
      BackendPlanSnapshot? plan;
      for (final currentPlan in _backendPlans) {
        if (currentPlan.storeProductIdForPlatform(_storePlatform()) ==
            update.productId) {
          plan = currentPlan;
          break;
        }
      }
      if (session == null || plan == null) {
        _isPurchasing = false;
        _isRestoringPurchases = false;
        _purchaseError =
            'Purchase completed in the store, but the app could not match it to a signed-in plan.';
        _purchaseStatusMessage = null;
        if (update.pendingCompletePurchase) {
          await _storePurchaseService.completePurchase(update.productId);
        }
        notifyListeners();
        continue;
      }

      final organizationId =
          _pendingPurchaseOrganizationIdsByProductId[update.productId] ??
          _currentPurchaseOrganizationIdForPlan(plan);

      try {
        await _backendApiService.verifyPurchase(
          provider: update.provider,
          accessToken: session.accessToken,
          planCode: plan.planCode,
          organizationId: organizationId,
          providerTransactionRef:
              update.providerTransactionRef ??
              update.purchaseId ??
              '${update.productId}-${DateTime.now().millisecondsSinceEpoch}',
          providerOriginalRef: update.providerOriginalRef ?? update.purchaseId,
          rawStatus: update.status,
          googleProductId: update.provider == 'google' ? update.productId : null,
          googlePurchaseToken: update.provider == 'google'
              ? (update.providerOriginalRef ?? update.purchaseId)
              : null,
        );
        await _hydrateBackendAccount(accessToken: session.accessToken);
        _purchaseStatusMessage = update.isRestored
            ? 'Purchase restored and verified.'
            : 'Purchase verified. Your backend access has been refreshed.';
        _purchaseError = null;
      } catch (error) {
        _purchaseError = error.toString();
        _purchaseStatusMessage = null;
      } finally {
        _isPurchasing = false;
        _isRestoringPurchases = false;
        _pendingPurchaseOrganizationIdsByProductId.remove(update.productId);
        if (update.pendingCompletePurchase) {
          await _storePurchaseService.completePurchase(update.productId);
        }
        notifyListeners();
      }
    }
  }

  BackendMembershipSummary? _firstAdminMembership(
    List<BackendMembershipSummary> memberships,
  ) {
    for (final membership in memberships) {
      if (membership.isAdmin) {
        return membership;
      }
    }
    return null;
  }

  String _describeBackendAuthError(Object error) {
    if (error is BackendApiException) {
      switch (error.statusCode) {
        case 400:
          return 'That sign-in code was not accepted. Start sign-in again and use the newest code.';
        case 401:
          return 'The backend session is no longer valid. Start sign-in again.';
        case 404:
          return 'That sign-in flow no longer exists. Start sign-in again.';
        case 409:
          return 'That sign-in code was already used. Start sign-in again for a fresh code.';
        case 410:
          return 'That sign-in code expired. Start sign-in again for a fresh code.';
        case 500:
          return 'The backend hit an internal error while signing in. Start sign-in again. If it repeats, stop here.';
      }
    }
    return error.toString();
  }

  Future<void> _clearBackendAuthState({String? errorMessage}) async {
    _backendAuthSession = null;
    _pendingBackendAuthStart = null;
    _pendingSessionConflict = null;
    _pendingSessionReplacementId = null;
    _shouldSurfaceSalesAuthError = false;
    _backendMe = null;
    _backendEntitlement = null;
    _backendOrganization = null;
    _backendAccountError = errorMessage;
    await _authSessionStore.clear();
  }

  String? _currentPurchaseOrganizationIdForPlan(BackendPlanSnapshot plan) {
    if (!plan.isBusiness) {
      return null;
    }

    if (_backendOrganization != null) {
      return _backendOrganization!.id;
    }

    final membership = _firstAdminMembership(
      _backendMe?.memberships ?? const [],
    );
    return membership?.organizationId;
  }

  BackendMembershipSummary? _membershipForCurrentEntitlement() {
    final memberships =
        _backendMe?.memberships ?? const <BackendMembershipSummary>[];
    if (memberships.isEmpty) {
      return null;
    }

    final organizationId =
        _backendOrganization?.id ??
        effectiveBackendEntitlement?.organizationId ??
        _backendMe?.currentSeatOrganizationId;
    if (organizationId != null && organizationId.trim().isNotEmpty) {
      for (final membership in memberships) {
        if (membership.organizationId == organizationId) {
          return membership;
        }
      }
    }

    for (final membership in memberships) {
      if (membership.isAccepted) {
        return membership;
      }
    }

    return memberships.first;
  }

  String _storePlatform() {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }

  @override
  void dispose() {
    _storePurchaseUpdatesSubscription.cancel();
    _storePurchaseService.dispose();
    super.dispose();
  }

  String _defaultDeviceLabel() {
    if (kIsWeb) {
      return 'Web Browser';
    }
    if (Platform.isAndroid) {
      return 'Android Device';
    }
    if (Platform.isIOS) {
      return 'iPhone';
    }
    if (Platform.isMacOS) {
      return 'Mac';
    }
    if (Platform.isWindows) {
      return 'Windows';
    }
    if (Platform.isLinux) {
      return 'Linux';
    }
    return 'Unknown Device';
  }

  bool _looksLikeEmail(String value) {
    const pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    return RegExp(pattern).hasMatch(value);
  }

  String _defaultSessionPlatform() {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return 'web';
  }

  Future<JobExportResult> exportJob(String jobId) async {
    final job = jobById(jobId);
    final exportResult = await _exportService.exportJob(
      job: job,
      customization: _customization,
    );

    if (exportResult.packetCount == 0) {
      return exportResult;
    }

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

StorePurchaseService _defaultStorePurchaseService() {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    return InAppStorePurchaseService();
  }
  return const NoopStorePurchaseService();
}
