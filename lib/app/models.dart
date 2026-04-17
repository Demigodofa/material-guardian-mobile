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

class B16StandardOption {
  const B16StandardOption({
    required this.suffix,
    required this.shortLabel,
    required this.scope,
  });

  final String suffix;
  final String shortLabel;
  final String scope;

  String get code => 'B16.$suffix';
  String get dropdownLabel => '$code  $shortLabel';
  String get reportLabel => '$code $shortLabel';
}

const List<B16StandardOption> kB16StandardCatalog = [
  B16StandardOption(
    suffix: '1',
    shortLabel: 'Gray iron flanges/fittings',
    scope: 'Gray iron flanges/flanged fittings, Cl 25/125/250.',
  ),
  B16StandardOption(
    suffix: '3',
    shortLabel: 'Malleable iron THD fittings',
    scope: 'Malleable iron THD fittings, Cl 150/300.',
  ),
  B16StandardOption(
    suffix: '4',
    shortLabel: 'Gray iron THD fittings',
    scope: 'Gray iron THD fittings, Cl 125/250.',
  ),
  B16StandardOption(
    suffix: '5',
    shortLabel: 'Flanges <=24 NPS',
    scope: 'Pipe flanges/flanged fittings, NPS 1/2-24.',
  ),
  B16StandardOption(
    suffix: '9',
    shortLabel: 'BW fittings 1/2-48',
    scope: 'Factory-made wrought BW fittings, NPS 1/2-48.',
  ),
  B16StandardOption(
    suffix: '10',
    shortLabel: 'Valve face-to-face',
    scope: 'Valve face-to-face / end-to-end dimensions.',
  ),
  B16StandardOption(
    suffix: '11',
    shortLabel: 'Forged fittings 2M-9M',
    scope: 'Forged SW/THD fittings; THD Cl 2000/3000/6000, SW Cl 3000/6000/9000.',
  ),
  B16StandardOption(
    suffix: '14',
    shortLabel: 'Plugs/bushings/locknuts',
    scope: 'Ferrous plugs, bushings, locknuts, pipe threads.',
  ),
  B16StandardOption(
    suffix: '15',
    shortLabel: 'Cast Cu THD fittings',
    scope: 'Cast Cu alloy THD fittings, Cl 125/250.',
  ),
  B16StandardOption(
    suffix: '18',
    shortLabel: 'Cast Cu solder fittings',
    scope: 'Cast Cu alloy solder-joint pressure fittings.',
  ),
  B16StandardOption(
    suffix: '20',
    shortLabel: 'Metallic flange gaskets',
    scope: 'Metallic gaskets for pipe flanges.',
  ),
  B16StandardOption(
    suffix: '21',
    shortLabel: 'Nonmetallic flange gaskets',
    scope: 'Nonmetallic flat gaskets for pipe flanges.',
  ),
  B16StandardOption(
    suffix: '22',
    shortLabel: 'Wrought Cu solder fittings',
    scope: 'Wrought Cu / Cu alloy solder-joint pressure fittings.',
  ),
  B16StandardOption(
    suffix: '24',
    shortLabel: 'Cast Cu flanges/valves',
    scope: 'Cast Cu alloy flanges, flanged fittings, and valves, Cl 150-2500.',
  ),
  B16StandardOption(
    suffix: '25',
    shortLabel: 'BW end prep / bevels',
    scope: 'Buttwelding end prep / bevels.',
  ),
  B16StandardOption(
    suffix: '26',
    shortLabel: 'Cast Cu flared fittings',
    scope: 'Cast Cu alloy fittings for flared Cu tube.',
  ),
  B16StandardOption(
    suffix: '28',
    shortLabel: 'Historical short-radius elbows',
    scope: 'Historical: short-radius elbows/returns; now included in B16.9.',
  ),
  B16StandardOption(
    suffix: '33',
    shortLabel: 'Gas valves 1/2-2',
    scope: 'Metallic gas valves, NPS 1/2-2, up to 175 psi.',
  ),
  B16StandardOption(
    suffix: '34',
    shortLabel: 'Valves flanged/THD/WE',
    scope: 'Valves - flanged, threaded, welding end.',
  ),
  B16StandardOption(
    suffix: '36',
    shortLabel: 'Orifice flanges',
    scope: 'Orifice flanges.',
  ),
  B16StandardOption(
    suffix: '38',
    shortLabel: 'Large gas valves',
    scope: 'Large metallic gas valves, NPS 2 1/2-12, 125 psig max.',
  ),
  B16StandardOption(
    suffix: '39',
    shortLabel: 'Malleable iron unions',
    scope: 'Malleable iron THD unions, Cl 150/250/300.',
  ),
  B16StandardOption(
    suffix: '40',
    shortLabel: 'Thermoplastic gas valves',
    scope: 'Thermoplastic gas shutoffs/valves for gas distribution.',
  ),
  B16StandardOption(
    suffix: '42',
    shortLabel: 'Ductile iron flanges',
    scope: 'Ductile iron flanges/flanged fittings, Cl 150/300.',
  ),
  B16StandardOption(
    suffix: '44',
    shortLabel: 'Aboveground gas valves',
    scope: 'Aboveground metallic gas valves, up to 5 psi.',
  ),
  B16StandardOption(
    suffix: '47',
    shortLabel: 'Large steel flanges',
    scope: 'Large-diameter steel flanges, NPS 26-60.',
  ),
  B16StandardOption(
    suffix: '48',
    shortLabel: 'Line blanks',
    scope: 'Line blanks, NPS 1/2-24, Cl 150-2500.',
  ),
  B16StandardOption(
    suffix: '49',
    shortLabel: 'Induction bends',
    scope: 'Factory-made wrought steel induction bends for transportation/distribution.',
  ),
  B16StandardOption(
    suffix: '50',
    shortLabel: 'Braze-joint Cu fittings',
    scope: 'Wrought Cu / Cu alloy braze-joint pressure fittings.',
  ),
  B16StandardOption(
    suffix: '51',
    shortLabel: 'Press-connect Cu fittings',
    scope: 'Cu / Cu alloy press-connect pressure fittings.',
  ),
  B16StandardOption(
    suffix: '52',
    shortLabel: 'Nonferrous forged fittings',
    scope: 'Forged nonferrous SW/THD fittings (Ti / Al alloys).',
  ),
];

const List<String> kDefaultPreferredB16Standards = ['5', '9', '11', '34'];

B16StandardOption? b16StandardBySuffix(String suffix) {
  final normalized = suffix.trim();
  for (final option in kB16StandardCatalog) {
    if (option.suffix == normalized) {
      return option;
    }
  }
  return null;
}

String formatB16StandardDropdownLabel(String suffix) {
  final option = b16StandardBySuffix(suffix);
  if (option == null) {
    return suffix.trim().isEmpty ? 'N/A' : 'B16.$suffix';
  }
  return option.dropdownLabel;
}

String formatB16StandardReportLabel(String suffix) {
  final option = b16StandardBySuffix(suffix);
  if (option == null) {
    return suffix.trim().isEmpty ? '' : 'B16.$suffix';
  }
  return option.reportLabel;
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
    required this.thickness2,
    required this.thickness3,
    required this.thickness4,
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
    required this.markingSelected,
    required this.mtrAcceptable,
    required this.mtrAcceptableNa,
    required this.mtrSelected,
    required this.acceptanceStatus,
    required this.comments,
    required this.qcInspectorName,
    required this.qcInspectorDate,
    required this.qcManagerName,
    required this.qcManagerDate,
    required this.qcManagerDateEnabled,
    required this.qcManagerDateManual,
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
  final String thickness2;
  final String thickness3;
  final String thickness4;
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
  final bool markingSelected;
  final bool mtrAcceptable;
  final bool mtrAcceptableNa;
  final bool mtrSelected;
  final String acceptanceStatus;
  final String comments;
  final String qcInspectorName;
  final DateTime qcInspectorDate;
  final String qcManagerName;
  final DateTime qcManagerDate;
  final bool qcManagerDateEnabled;
  final bool qcManagerDateManual;
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
      'thickness2': thickness2,
      'thickness3': thickness3,
      'thickness4': thickness4,
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
      'markingSelected': markingSelected,
      'mtrAcceptable': mtrAcceptable,
      'mtrAcceptableNa': mtrAcceptableNa,
      'mtrSelected': mtrSelected,
      'acceptanceStatus': acceptanceStatus,
      'comments': comments,
      'qcInspectorName': qcInspectorName,
      'qcInspectorDate': qcInspectorDate.toIso8601String(),
      'qcManagerName': qcManagerName,
      'qcManagerDate': qcManagerDate.toIso8601String(),
      'qcManagerDateEnabled': qcManagerDateEnabled,
      'qcManagerDateManual': qcManagerDateManual,
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
    final qcManagerName = json['qcManagerName'] as String? ?? '';
    final qcManagerSignaturePath =
        json['qcManagerSignaturePath'] as String? ?? '';
    final qcManagerDate =
        DateTime.tryParse(json['qcManagerDate'] as String? ?? '') ??
        DateTime.now();
    final qcManagerDateEnabled =
        json['qcManagerDateEnabled'] as bool? ??
        qcManagerName.trim().isNotEmpty ||
            qcManagerSignaturePath.trim().isNotEmpty ||
            json.containsKey('qcManagerDate');
    final qcManagerDateManual =
        json['qcManagerDateManual'] as bool? ?? qcManagerDateEnabled;
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
      thickness2: json['thickness2'] as String? ?? '',
      thickness3: json['thickness3'] as String? ?? '',
      thickness4: json['thickness4'] as String? ?? '',
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
      markingSelected: json['markingSelected'] as bool? ?? false,
      mtrAcceptable: json['mtrAcceptable'] as bool? ?? true,
      mtrAcceptableNa: json['mtrAcceptableNa'] as bool? ?? false,
      mtrSelected: json['mtrSelected'] as bool? ?? false,
      acceptanceStatus: json['acceptanceStatus'] as String? ?? 'accept',
      comments: json['comments'] as String? ?? '',
      qcInspectorName: json['qcInspectorName'] as String? ?? '',
      qcInspectorDate:
          DateTime.tryParse(json['qcInspectorDate'] as String? ?? '') ??
          DateTime.now(),
      qcManagerName: qcManagerName,
      qcManagerDate: qcManagerDate,
      qcManagerDateEnabled: qcManagerDateEnabled,
      qcManagerDateManual: qcManagerDateManual,
      qcSignaturePath: json['qcSignaturePath'] as String? ?? '',
      qcManagerSignaturePath: qcManagerSignaturePath,
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
    String? thickness2,
    String? thickness3,
    String? thickness4,
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
    bool? markingSelected,
    bool? mtrAcceptable,
    bool? mtrAcceptableNa,
    bool? mtrSelected,
    String? acceptanceStatus,
    String? comments,
    String? qcInspectorName,
    DateTime? qcInspectorDate,
    String? qcManagerName,
    DateTime? qcManagerDate,
    bool? qcManagerDateEnabled,
    bool? qcManagerDateManual,
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
      thickness2: thickness2 ?? this.thickness2,
      thickness3: thickness3 ?? this.thickness3,
      thickness4: thickness4 ?? this.thickness4,
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
      markingSelected: markingSelected ?? this.markingSelected,
      mtrAcceptable: mtrAcceptable ?? this.mtrAcceptable,
      mtrAcceptableNa: mtrAcceptableNa ?? this.mtrAcceptableNa,
      mtrSelected: mtrSelected ?? this.mtrSelected,
      acceptanceStatus: acceptanceStatus ?? this.acceptanceStatus,
      comments: comments ?? this.comments,
      qcInspectorName: qcInspectorName ?? this.qcInspectorName,
      qcInspectorDate: qcInspectorDate ?? this.qcInspectorDate,
      qcManagerName: qcManagerName ?? this.qcManagerName,
      qcManagerDate: qcManagerDate ?? this.qcManagerDate,
      qcManagerDateEnabled: qcManagerDateEnabled ?? this.qcManagerDateEnabled,
      qcManagerDateManual: qcManagerDateManual ?? this.qcManagerDateManual,
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
    required this.thickness2,
    required this.thickness3,
    required this.thickness4,
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
    required this.markingSelected,
    required this.mtrAcceptable,
    required this.mtrAcceptableNa,
    required this.mtrSelected,
    required this.comments,
    required this.acceptanceStatus,
    required this.qcInspectorName,
    required this.qcInspectorDate,
    required this.qcManagerName,
    required this.qcManagerDate,
    required this.qcManagerDateEnabled,
    required this.qcManagerDateManual,
    required this.qcSignaturePath,
    required this.qcManagerSignaturePath,
    required this.materialApproval,
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
  final String thickness2;
  final String thickness3;
  final String thickness4;
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
  final bool markingSelected;
  final bool mtrAcceptable;
  final bool mtrAcceptableNa;
  final bool mtrSelected;
  final String comments;
  final String acceptanceStatus;
  final String qcInspectorName;
  final DateTime qcInspectorDate;
  final String qcManagerName;
  final DateTime qcManagerDate;
  final bool qcManagerDateEnabled;
  final bool qcManagerDateManual;
  final String qcSignaturePath;
  final String qcManagerSignaturePath;
  final String materialApproval;
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
      'thickness2': thickness2,
      'thickness3': thickness3,
      'thickness4': thickness4,
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
      'markingSelected': markingSelected,
      'mtrAcceptable': mtrAcceptable,
      'mtrAcceptableNa': mtrAcceptableNa,
      'mtrSelected': mtrSelected,
      'comments': comments,
      'acceptanceStatus': acceptanceStatus,
      'qcInspectorName': qcInspectorName,
      'qcInspectorDate': qcInspectorDate.toIso8601String(),
      'qcManagerName': qcManagerName,
      'qcManagerDate': qcManagerDate.toIso8601String(),
      'qcManagerDateEnabled': qcManagerDateEnabled,
      'qcManagerDateManual': qcManagerDateManual,
      'qcSignaturePath': qcSignaturePath,
      'qcManagerSignaturePath': qcManagerSignaturePath,
      'materialApproval': materialApproval,
      'photoPaths': photoPaths,
      'scanPaths': scanPaths,
      'signatureApplied': signatureApplied,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MaterialDraft.fromJson(Map<String, dynamic> json) {
    final qcManagerName = json['qcManagerName'] as String? ?? '';
    final qcManagerSignaturePath =
        json['qcManagerSignaturePath'] as String? ?? '';
    final qcManagerDate =
        DateTime.tryParse(json['qcManagerDate'] as String? ?? '') ??
        DateTime.now();
    final qcManagerDateEnabled =
        json['qcManagerDateEnabled'] as bool? ??
        qcManagerName.trim().isNotEmpty ||
            qcManagerSignaturePath.trim().isNotEmpty ||
            json.containsKey('qcManagerDate');
    final qcManagerDateManual =
        json['qcManagerDateManual'] as bool? ?? qcManagerDateEnabled;
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
      thickness2: json['thickness2'] as String? ?? '',
      thickness3: json['thickness3'] as String? ?? '',
      thickness4: json['thickness4'] as String? ?? '',
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
      markingSelected: json['markingSelected'] as bool? ?? false,
      mtrAcceptable: json['mtrAcceptable'] as bool? ?? true,
      mtrAcceptableNa: json['mtrAcceptableNa'] as bool? ?? false,
      mtrSelected: json['mtrSelected'] as bool? ?? false,
      comments: json['comments'] as String? ?? '',
      acceptanceStatus: json['acceptanceStatus'] as String? ?? 'accept',
      qcInspectorName: json['qcInspectorName'] as String? ?? '',
      qcInspectorDate:
          DateTime.tryParse(json['qcInspectorDate'] as String? ?? '') ??
          DateTime.now(),
      qcManagerName: qcManagerName,
      qcManagerDate: qcManagerDate,
      qcManagerDateEnabled: qcManagerDateEnabled,
      qcManagerDateManual: qcManagerDateManual,
      qcSignaturePath: json['qcSignaturePath'] as String? ?? '',
      qcManagerSignaturePath: qcManagerSignaturePath,
      materialApproval: json['materialApproval'] as String? ?? 'approved',
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
    String? thickness2,
    String? thickness3,
    String? thickness4,
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
    bool? markingSelected,
    bool? mtrAcceptable,
    bool? mtrAcceptableNa,
    bool? mtrSelected,
    String? comments,
    String? acceptanceStatus,
    String? qcInspectorName,
    DateTime? qcInspectorDate,
    String? qcManagerName,
    DateTime? qcManagerDate,
    bool? qcManagerDateEnabled,
    bool? qcManagerDateManual,
    String? qcSignaturePath,
    String? qcManagerSignaturePath,
    String? materialApproval,
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
      thickness2: thickness2 ?? this.thickness2,
      thickness3: thickness3 ?? this.thickness3,
      thickness4: thickness4 ?? this.thickness4,
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
      markingSelected: markingSelected ?? this.markingSelected,
      mtrAcceptable: mtrAcceptable ?? this.mtrAcceptable,
      mtrAcceptableNa: mtrAcceptableNa ?? this.mtrAcceptableNa,
      mtrSelected: mtrSelected ?? this.mtrSelected,
      comments: comments ?? this.comments,
      acceptanceStatus: acceptanceStatus ?? this.acceptanceStatus,
      qcInspectorName: qcInspectorName ?? this.qcInspectorName,
      qcInspectorDate: qcInspectorDate ?? this.qcInspectorDate,
      qcManagerName: qcManagerName ?? this.qcManagerName,
      qcManagerDate: qcManagerDate ?? this.qcManagerDate,
      qcManagerDateEnabled: qcManagerDateEnabled ?? this.qcManagerDateEnabled,
      qcManagerDateManual: qcManagerDateManual ?? this.qcManagerDateManual,
      qcSignaturePath: qcSignaturePath ?? this.qcSignaturePath,
      qcManagerSignaturePath:
          qcManagerSignaturePath ?? this.qcManagerSignaturePath,
      materialApproval: materialApproval ?? this.materialApproval,
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
    required this.preferredB16Standards,
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
  final List<String> preferredB16Standards;
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
      'preferredB16Standards': preferredB16Standards,
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
    final preferredB16Standards =
        ((json['preferredB16Standards'] as List<dynamic>?) ?? const [])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
    return CustomizationSettings(
      receiveAsmeB16Parts: json['receiveAsmeB16Parts'] as bool? ?? true,
      preferredB16Standards: preferredB16Standards.isEmpty
          ? List<String>.from(kDefaultPreferredB16Standards)
          : preferredB16Standards,
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
    List<String>? preferredB16Standards,
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
      preferredB16Standards:
          preferredB16Standards ?? this.preferredB16Standards,
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
