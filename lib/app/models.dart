enum UnitSystem {
  imperial('Imperial'),
  metric('Metric');

  const UnitSystem(this.label);

  final String label;

  static UnitSystem fromName(String? value) {
    return UnitSystem.values.where((item) => item.name == value).firstOrNull ??
        UnitSystem.imperial;
  }
}

class JobRecord {
  const JobRecord({
    required this.id,
    required this.jobNumber,
    required this.description,
    required this.notes,
    required this.createdAt,
    required this.exportedAt,
    required this.exportPath,
    required this.materials,
  });

  final String id;
  final String jobNumber;
  final String description;
  final String notes;
  final DateTime createdAt;
  final DateTime? exportedAt;
  final String exportPath;
  final List<MaterialRecord> materials;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobNumber': jobNumber,
      'description': description,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'exportedAt': exportedAt?.toIso8601String(),
      'exportPath': exportPath,
      'materials': materials
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }

  factory JobRecord.fromJson(Map<String, dynamic> json) {
    return JobRecord(
      id: json['id'] as String? ?? '',
      jobNumber: json['jobNumber'] as String? ?? '',
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? ''),
      exportPath: json['exportPath'] as String? ?? '',
      materials: ((json['materials'] as List<dynamic>?) ?? const [])
          .map((item) => MaterialRecord.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  JobRecord copyWith({
    String? id,
    String? jobNumber,
    String? description,
    String? notes,
    DateTime? createdAt,
    DateTime? exportedAt,
    bool clearExportedAt = false,
    String? exportPath,
    List<MaterialRecord>? materials,
  }) {
    return JobRecord(
      id: id ?? this.id,
      jobNumber: jobNumber ?? this.jobNumber,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      exportedAt: clearExportedAt ? null : (exportedAt ?? this.exportedAt),
      exportPath: exportPath ?? this.exportPath,
      materials: materials ?? this.materials,
    );
  }
}

class MaterialRecord {
  const MaterialRecord({
    required this.id,
    required this.tag,
    required this.description,
    required this.vendor,
    required this.quantity,
    required this.poNumber,
    required this.productType,
    required this.specificationPrefix,
    required this.gradeType,
    required this.fittingStandard,
    required this.fittingSuffix,
    required this.dimensionUnit,
    required this.heatNumber,
    required this.thickness1,
    required this.width,
    required this.length,
    required this.diameter,
    required this.diameterType,
    required this.visualInspectionAcceptable,
    required this.b16DimensionsAcceptable,
    required this.surfaceFinishCode,
    required this.surfaceFinishReading,
    required this.surfaceFinishUnit,
    required this.markings,
    required this.markingAcceptable,
    required this.markingAcceptableNa,
    required this.mtrAcceptable,
    required this.mtrAcceptableNa,
    required this.acceptanceStatus,
    required this.comments,
    required this.qcInspectorName,
    required this.qcManagerName,
    required this.qcSignaturePath,
    required this.qcManagerSignaturePath,
    required this.materialApproval,
    required this.offloadStatus,
    required this.pdfStatus,
    required this.pdfStoragePath,
    required this.photoPaths,
    required this.scanPaths,
    required this.photoCount,
    required this.createdAt,
  });

  final String id;
  final String tag;
  final String description;
  final String vendor;
  final String quantity;
  final String poNumber;
  final String productType;
  final String specificationPrefix;
  final String gradeType;
  final String fittingStandard;
  final String fittingSuffix;
  final UnitSystem dimensionUnit;
  final String heatNumber;
  final String thickness1;
  final String width;
  final String length;
  final String diameter;
  final String diameterType;
  final bool visualInspectionAcceptable;
  final String b16DimensionsAcceptable;
  final String surfaceFinishCode;
  final String surfaceFinishReading;
  final String surfaceFinishUnit;
  final String markings;
  final bool markingAcceptable;
  final bool markingAcceptableNa;
  final bool mtrAcceptable;
  final bool mtrAcceptableNa;
  final String acceptanceStatus;
  final String comments;
  final String qcInspectorName;
  final String qcManagerName;
  final String qcSignaturePath;
  final String qcManagerSignaturePath;
  final String materialApproval;
  final String offloadStatus;
  final String pdfStatus;
  final String pdfStoragePath;
  final List<String> photoPaths;
  final List<String> scanPaths;
  final int photoCount;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag': tag,
      'description': description,
      'vendor': vendor,
      'quantity': quantity,
      'poNumber': poNumber,
      'productType': productType,
      'specificationPrefix': specificationPrefix,
      'gradeType': gradeType,
      'fittingStandard': fittingStandard,
      'fittingSuffix': fittingSuffix,
      'dimensionUnit': dimensionUnit.name,
      'heatNumber': heatNumber,
      'thickness1': thickness1,
      'width': width,
      'length': length,
      'diameter': diameter,
      'diameterType': diameterType,
      'visualInspectionAcceptable': visualInspectionAcceptable,
      'b16DimensionsAcceptable': b16DimensionsAcceptable,
      'surfaceFinishCode': surfaceFinishCode,
      'surfaceFinishReading': surfaceFinishReading,
      'surfaceFinishUnit': surfaceFinishUnit,
      'markings': markings,
      'markingAcceptable': markingAcceptable,
      'markingAcceptableNa': markingAcceptableNa,
      'mtrAcceptable': mtrAcceptable,
      'mtrAcceptableNa': mtrAcceptableNa,
      'acceptanceStatus': acceptanceStatus,
      'comments': comments,
      'qcInspectorName': qcInspectorName,
      'qcManagerName': qcManagerName,
      'qcSignaturePath': qcSignaturePath,
      'qcManagerSignaturePath': qcManagerSignaturePath,
      'materialApproval': materialApproval,
      'offloadStatus': offloadStatus,
      'pdfStatus': pdfStatus,
      'pdfStoragePath': pdfStoragePath,
      'photoPaths': photoPaths,
      'scanPaths': scanPaths,
      'photoCount': photoCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MaterialRecord.fromJson(Map<String, dynamic> json) {
    return MaterialRecord(
      id: json['id'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      description: json['description'] as String? ?? '',
      vendor: json['vendor'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      poNumber: json['poNumber'] as String? ?? '',
      productType: json['productType'] as String? ?? '',
      specificationPrefix: json['specificationPrefix'] as String? ?? '',
      gradeType: json['gradeType'] as String? ?? '',
      fittingStandard: json['fittingStandard'] as String? ?? '',
      fittingSuffix: json['fittingSuffix'] as String? ?? '',
      dimensionUnit: UnitSystem.fromName(json['dimensionUnit'] as String?),
      heatNumber: json['heatNumber'] as String? ?? '',
      thickness1: json['thickness1'] as String? ?? '',
      width: json['width'] as String? ?? '',
      length: json['length'] as String? ?? '',
      diameter: json['diameter'] as String? ?? '',
      diameterType: json['diameterType'] as String? ?? '',
      visualInspectionAcceptable:
          json['visualInspectionAcceptable'] as bool? ?? true,
      b16DimensionsAcceptable: json['b16DimensionsAcceptable'] as String? ?? '',
      surfaceFinishCode: json['surfaceFinishCode'] as String? ?? '',
      surfaceFinishReading: json['surfaceFinishReading'] as String? ?? '',
      surfaceFinishUnit: json['surfaceFinishUnit'] as String? ?? '',
      markings: json['markings'] as String? ?? '',
      markingAcceptable: json['markingAcceptable'] as bool? ?? true,
      markingAcceptableNa: json['markingAcceptableNa'] as bool? ?? false,
      mtrAcceptable: json['mtrAcceptable'] as bool? ?? true,
      mtrAcceptableNa: json['mtrAcceptableNa'] as bool? ?? false,
      acceptanceStatus: json['acceptanceStatus'] as String? ?? 'accept',
      comments: json['comments'] as String? ?? '',
      qcInspectorName: json['qcInspectorName'] as String? ?? '',
      qcManagerName: json['qcManagerName'] as String? ?? '',
      qcSignaturePath: json['qcSignaturePath'] as String? ?? '',
      qcManagerSignaturePath: json['qcManagerSignaturePath'] as String? ?? '',
      materialApproval: json['materialApproval'] as String? ?? 'approved',
      offloadStatus: json['offloadStatus'] as String? ?? '',
      pdfStatus: json['pdfStatus'] as String? ?? '',
      pdfStoragePath: json['pdfStoragePath'] as String? ?? '',
      photoPaths: ((json['photoPaths'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      scanPaths: ((json['scanPaths'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      photoCount: json['photoCount'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  MaterialRecord copyWith({
    String? id,
    String? tag,
    String? description,
    String? vendor,
    String? quantity,
    String? poNumber,
    String? productType,
    String? specificationPrefix,
    String? gradeType,
    String? fittingStandard,
    String? fittingSuffix,
    UnitSystem? dimensionUnit,
    String? heatNumber,
    String? thickness1,
    String? width,
    String? length,
    String? diameter,
    String? diameterType,
    bool? visualInspectionAcceptable,
    String? b16DimensionsAcceptable,
    String? surfaceFinishCode,
    String? surfaceFinishReading,
    String? surfaceFinishUnit,
    String? markings,
    bool? markingAcceptable,
    bool? markingAcceptableNa,
    bool? mtrAcceptable,
    bool? mtrAcceptableNa,
    String? acceptanceStatus,
    String? comments,
    String? qcInspectorName,
    String? qcManagerName,
    String? qcSignaturePath,
    String? qcManagerSignaturePath,
    String? materialApproval,
    String? offloadStatus,
    String? pdfStatus,
    String? pdfStoragePath,
    List<String>? photoPaths,
    List<String>? scanPaths,
    int? photoCount,
    DateTime? createdAt,
  }) {
    return MaterialRecord(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      description: description ?? this.description,
      vendor: vendor ?? this.vendor,
      quantity: quantity ?? this.quantity,
      poNumber: poNumber ?? this.poNumber,
      productType: productType ?? this.productType,
      specificationPrefix: specificationPrefix ?? this.specificationPrefix,
      gradeType: gradeType ?? this.gradeType,
      fittingStandard: fittingStandard ?? this.fittingStandard,
      fittingSuffix: fittingSuffix ?? this.fittingSuffix,
      dimensionUnit: dimensionUnit ?? this.dimensionUnit,
      heatNumber: heatNumber ?? this.heatNumber,
      thickness1: thickness1 ?? this.thickness1,
      width: width ?? this.width,
      length: length ?? this.length,
      diameter: diameter ?? this.diameter,
      diameterType: diameterType ?? this.diameterType,
      visualInspectionAcceptable:
          visualInspectionAcceptable ?? this.visualInspectionAcceptable,
      b16DimensionsAcceptable:
          b16DimensionsAcceptable ?? this.b16DimensionsAcceptable,
      surfaceFinishCode: surfaceFinishCode ?? this.surfaceFinishCode,
      surfaceFinishReading: surfaceFinishReading ?? this.surfaceFinishReading,
      surfaceFinishUnit: surfaceFinishUnit ?? this.surfaceFinishUnit,
      markings: markings ?? this.markings,
      markingAcceptable: markingAcceptable ?? this.markingAcceptable,
      markingAcceptableNa: markingAcceptableNa ?? this.markingAcceptableNa,
      mtrAcceptable: mtrAcceptable ?? this.mtrAcceptable,
      mtrAcceptableNa: mtrAcceptableNa ?? this.mtrAcceptableNa,
      acceptanceStatus: acceptanceStatus ?? this.acceptanceStatus,
      comments: comments ?? this.comments,
      qcInspectorName: qcInspectorName ?? this.qcInspectorName,
      qcManagerName: qcManagerName ?? this.qcManagerName,
      qcSignaturePath: qcSignaturePath ?? this.qcSignaturePath,
      qcManagerSignaturePath:
          qcManagerSignaturePath ?? this.qcManagerSignaturePath,
      materialApproval: materialApproval ?? this.materialApproval,
      offloadStatus: offloadStatus ?? this.offloadStatus,
      pdfStatus: pdfStatus ?? this.pdfStatus,
      pdfStoragePath: pdfStoragePath ?? this.pdfStoragePath,
      photoPaths: photoPaths ?? this.photoPaths,
      scanPaths: scanPaths ?? this.scanPaths,
      photoCount: photoCount ?? this.photoCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MaterialDraft {
  const MaterialDraft({
    required this.id,
    required this.jobId,
    required this.sourceMaterialId,
    required this.materialTag,
    required this.description,
    required this.vendor,
    required this.quantity,
    required this.poNumber,
    required this.productType,
    required this.specificationPrefix,
    required this.gradeType,
    required this.fittingStandard,
    required this.fittingSuffix,
    required this.unitSystem,
    required this.heatNumber,
    required this.includesB16Data,
    required this.b16Size,
    required this.thickness1,
    required this.width,
    required this.length,
    required this.diameter,
    required this.diameterType,
    required this.visualInspectionAcceptable,
    required this.surfaceFinish,
    required this.surfaceFinishReading,
    required this.surfaceFinishUnit,
    required this.markings,
    required this.markingAcceptable,
    required this.markingAcceptableNa,
    required this.mtrAcceptable,
    required this.mtrAcceptableNa,
    required this.comments,
    required this.acceptanceStatus,
    required this.qcInspectorName,
    required this.qcManagerName,
    required this.qcSignaturePath,
    required this.qcManagerSignaturePath,
    required this.photoPaths,
    required this.scanPaths,
    required this.signatureApplied,
    required this.updatedAt,
  });

  final String id;
  final String jobId;
  final String sourceMaterialId;
  final String materialTag;
  final String description;
  final String vendor;
  final String quantity;
  final String poNumber;
  final String productType;
  final String specificationPrefix;
  final String gradeType;
  final String fittingStandard;
  final String fittingSuffix;
  final UnitSystem unitSystem;
  final String heatNumber;
  final bool includesB16Data;
  final String b16Size;
  final String thickness1;
  final String width;
  final String length;
  final String diameter;
  final String diameterType;
  final bool visualInspectionAcceptable;
  final String surfaceFinish;
  final String surfaceFinishReading;
  final String surfaceFinishUnit;
  final String markings;
  final bool markingAcceptable;
  final bool markingAcceptableNa;
  final bool mtrAcceptable;
  final bool mtrAcceptableNa;
  final String comments;
  final String acceptanceStatus;
  final String qcInspectorName;
  final String qcManagerName;
  final String qcSignaturePath;
  final String qcManagerSignaturePath;
  final List<String> photoPaths;
  final List<String> scanPaths;
  final bool signatureApplied;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'sourceMaterialId': sourceMaterialId,
      'materialTag': materialTag,
      'description': description,
      'vendor': vendor,
      'quantity': quantity,
      'poNumber': poNumber,
      'productType': productType,
      'specificationPrefix': specificationPrefix,
      'gradeType': gradeType,
      'fittingStandard': fittingStandard,
      'fittingSuffix': fittingSuffix,
      'unitSystem': unitSystem.name,
      'heatNumber': heatNumber,
      'includesB16Data': includesB16Data,
      'b16Size': b16Size,
      'thickness1': thickness1,
      'width': width,
      'length': length,
      'diameter': diameter,
      'diameterType': diameterType,
      'visualInspectionAcceptable': visualInspectionAcceptable,
      'surfaceFinish': surfaceFinish,
      'surfaceFinishReading': surfaceFinishReading,
      'surfaceFinishUnit': surfaceFinishUnit,
      'markings': markings,
      'markingAcceptable': markingAcceptable,
      'markingAcceptableNa': markingAcceptableNa,
      'mtrAcceptable': mtrAcceptable,
      'mtrAcceptableNa': mtrAcceptableNa,
      'comments': comments,
      'acceptanceStatus': acceptanceStatus,
      'qcInspectorName': qcInspectorName,
      'qcManagerName': qcManagerName,
      'qcSignaturePath': qcSignaturePath,
      'qcManagerSignaturePath': qcManagerSignaturePath,
      'photoPaths': photoPaths,
      'scanPaths': scanPaths,
      'signatureApplied': signatureApplied,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MaterialDraft.fromJson(Map<String, dynamic> json) {
    return MaterialDraft(
      id: json['id'] as String? ?? '',
      jobId: json['jobId'] as String? ?? '',
      sourceMaterialId: json['sourceMaterialId'] as String? ?? '',
      materialTag: json['materialTag'] as String? ?? '',
      description: json['description'] as String? ?? '',
      vendor: json['vendor'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      poNumber: json['poNumber'] as String? ?? '',
      productType: json['productType'] as String? ?? '',
      specificationPrefix: json['specificationPrefix'] as String? ?? '',
      gradeType: json['gradeType'] as String? ?? '',
      fittingStandard: json['fittingStandard'] as String? ?? '',
      fittingSuffix: json['fittingSuffix'] as String? ?? '',
      unitSystem: UnitSystem.fromName(json['unitSystem'] as String?),
      heatNumber: json['heatNumber'] as String? ?? '',
      includesB16Data: json['includesB16Data'] as bool? ?? false,
      b16Size: json['b16Size'] as String? ?? '',
      thickness1: json['thickness1'] as String? ?? '',
      width: json['width'] as String? ?? '',
      length: json['length'] as String? ?? '',
      diameter: json['diameter'] as String? ?? '',
      diameterType: json['diameterType'] as String? ?? '',
      visualInspectionAcceptable:
          json['visualInspectionAcceptable'] as bool? ?? true,
      surfaceFinish: json['surfaceFinish'] as String? ?? '',
      surfaceFinishReading: json['surfaceFinishReading'] as String? ?? '',
      surfaceFinishUnit: json['surfaceFinishUnit'] as String? ?? '',
      markings: json['markings'] as String? ?? '',
      markingAcceptable: json['markingAcceptable'] as bool? ?? true,
      markingAcceptableNa: json['markingAcceptableNa'] as bool? ?? false,
      mtrAcceptable: json['mtrAcceptable'] as bool? ?? true,
      mtrAcceptableNa: json['mtrAcceptableNa'] as bool? ?? false,
      comments: json['comments'] as String? ?? '',
      acceptanceStatus: json['acceptanceStatus'] as String? ?? 'accept',
      qcInspectorName: json['qcInspectorName'] as String? ?? '',
      qcManagerName: json['qcManagerName'] as String? ?? '',
      qcSignaturePath: json['qcSignaturePath'] as String? ?? '',
      qcManagerSignaturePath: json['qcManagerSignaturePath'] as String? ?? '',
      photoPaths: ((json['photoPaths'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      scanPaths: ((json['scanPaths'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      signatureApplied: json['signatureApplied'] as bool? ?? false,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  MaterialDraft copyWith({
    String? id,
    String? jobId,
    String? sourceMaterialId,
    String? materialTag,
    String? description,
    String? vendor,
    String? quantity,
    String? poNumber,
    String? productType,
    String? specificationPrefix,
    String? gradeType,
    String? fittingStandard,
    String? fittingSuffix,
    UnitSystem? unitSystem,
    String? heatNumber,
    bool? includesB16Data,
    String? b16Size,
    String? thickness1,
    String? width,
    String? length,
    String? diameter,
    String? diameterType,
    bool? visualInspectionAcceptable,
    String? surfaceFinish,
    String? surfaceFinishReading,
    String? surfaceFinishUnit,
    String? markings,
    bool? markingAcceptable,
    bool? markingAcceptableNa,
    bool? mtrAcceptable,
    bool? mtrAcceptableNa,
    String? comments,
    String? acceptanceStatus,
    String? qcInspectorName,
    String? qcManagerName,
    String? qcSignaturePath,
    String? qcManagerSignaturePath,
    List<String>? photoPaths,
    List<String>? scanPaths,
    bool? signatureApplied,
    DateTime? updatedAt,
  }) {
    return MaterialDraft(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      sourceMaterialId: sourceMaterialId ?? this.sourceMaterialId,
      materialTag: materialTag ?? this.materialTag,
      description: description ?? this.description,
      vendor: vendor ?? this.vendor,
      quantity: quantity ?? this.quantity,
      poNumber: poNumber ?? this.poNumber,
      productType: productType ?? this.productType,
      specificationPrefix: specificationPrefix ?? this.specificationPrefix,
      gradeType: gradeType ?? this.gradeType,
      fittingStandard: fittingStandard ?? this.fittingStandard,
      fittingSuffix: fittingSuffix ?? this.fittingSuffix,
      unitSystem: unitSystem ?? this.unitSystem,
      heatNumber: heatNumber ?? this.heatNumber,
      includesB16Data: includesB16Data ?? this.includesB16Data,
      b16Size: b16Size ?? this.b16Size,
      thickness1: thickness1 ?? this.thickness1,
      width: width ?? this.width,
      length: length ?? this.length,
      diameter: diameter ?? this.diameter,
      diameterType: diameterType ?? this.diameterType,
      visualInspectionAcceptable:
          visualInspectionAcceptable ?? this.visualInspectionAcceptable,
      surfaceFinish: surfaceFinish ?? this.surfaceFinish,
      surfaceFinishReading: surfaceFinishReading ?? this.surfaceFinishReading,
      surfaceFinishUnit: surfaceFinishUnit ?? this.surfaceFinishUnit,
      markings: markings ?? this.markings,
      markingAcceptable: markingAcceptable ?? this.markingAcceptable,
      markingAcceptableNa: markingAcceptableNa ?? this.markingAcceptableNa,
      mtrAcceptable: mtrAcceptable ?? this.mtrAcceptable,
      mtrAcceptableNa: mtrAcceptableNa ?? this.mtrAcceptableNa,
      comments: comments ?? this.comments,
      acceptanceStatus: acceptanceStatus ?? this.acceptanceStatus,
      qcInspectorName: qcInspectorName ?? this.qcInspectorName,
      qcManagerName: qcManagerName ?? this.qcManagerName,
      qcSignaturePath: qcSignaturePath ?? this.qcSignaturePath,
      qcManagerSignaturePath:
          qcManagerSignaturePath ?? this.qcManagerSignaturePath,
      photoPaths: photoPaths ?? this.photoPaths,
      scanPaths: scanPaths ?? this.scanPaths,
      signatureApplied: signatureApplied ?? this.signatureApplied,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CustomizationSettings {
  const CustomizationSettings({
    required this.receiveAsmeB16Parts,
    required this.surfaceFinishRequired,
    required this.surfaceFinishUnit,
    required this.defaultQcInspectorName,
    required this.defaultQcManagerName,
    required this.hasSavedInspectorSignature,
    required this.savedInspectorSignaturePath,
    required this.includeCompanyLogoOnReports,
    required this.companyLogoPath,
  });

  final bool receiveAsmeB16Parts;
  final bool surfaceFinishRequired;
  final String surfaceFinishUnit;
  final String defaultQcInspectorName;
  final String defaultQcManagerName;
  final bool hasSavedInspectorSignature;
  final String savedInspectorSignaturePath;
  final bool includeCompanyLogoOnReports;
  final String companyLogoPath;

  Map<String, Object?> toJson() {
    return {
      'receiveAsmeB16Parts': receiveAsmeB16Parts,
      'surfaceFinishRequired': surfaceFinishRequired,
      'surfaceFinishUnit': surfaceFinishUnit,
      'defaultQcInspectorName': defaultQcInspectorName,
      'defaultQcManagerName': defaultQcManagerName,
      'hasSavedInspectorSignature': hasSavedInspectorSignature,
      'savedInspectorSignaturePath': savedInspectorSignaturePath,
      'includeCompanyLogoOnReports': includeCompanyLogoOnReports,
      'companyLogoPath': companyLogoPath,
    };
  }

  factory CustomizationSettings.fromJson(Map<String, Object?> json) {
    return CustomizationSettings(
      receiveAsmeB16Parts: json['receiveAsmeB16Parts'] as bool? ?? true,
      surfaceFinishRequired: json['surfaceFinishRequired'] as bool? ?? false,
      surfaceFinishUnit: json['surfaceFinishUnit'] as String? ?? 'u-in',
      defaultQcInspectorName: json['defaultQcInspectorName'] as String? ?? '',
      defaultQcManagerName: json['defaultQcManagerName'] as String? ?? '',
      hasSavedInspectorSignature:
          json['hasSavedInspectorSignature'] as bool? ?? false,
      savedInspectorSignaturePath:
          json['savedInspectorSignaturePath'] as String? ?? '',
      includeCompanyLogoOnReports:
          json['includeCompanyLogoOnReports'] as bool? ?? false,
      companyLogoPath: json['companyLogoPath'] as String? ?? '',
    );
  }

  CustomizationSettings copyWith({
    bool? receiveAsmeB16Parts,
    bool? surfaceFinishRequired,
    String? surfaceFinishUnit,
    String? defaultQcInspectorName,
    String? defaultQcManagerName,
    bool? hasSavedInspectorSignature,
    String? savedInspectorSignaturePath,
    bool? includeCompanyLogoOnReports,
    String? companyLogoPath,
  }) {
    return CustomizationSettings(
      receiveAsmeB16Parts: receiveAsmeB16Parts ?? this.receiveAsmeB16Parts,
      surfaceFinishRequired:
          surfaceFinishRequired ?? this.surfaceFinishRequired,
      surfaceFinishUnit: surfaceFinishUnit ?? this.surfaceFinishUnit,
      defaultQcInspectorName:
          defaultQcInspectorName ?? this.defaultQcInspectorName,
      defaultQcManagerName: defaultQcManagerName ?? this.defaultQcManagerName,
      hasSavedInspectorSignature:
          hasSavedInspectorSignature ?? this.hasSavedInspectorSignature,
      savedInspectorSignaturePath:
          savedInspectorSignaturePath ?? this.savedInspectorSignaturePath,
      includeCompanyLogoOnReports:
          includeCompanyLogoOnReports ?? this.includeCompanyLogoOnReports,
      companyLogoPath: companyLogoPath ?? this.companyLogoPath,
    );
  }
}
