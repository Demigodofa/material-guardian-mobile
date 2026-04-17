import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../app/models.dart';

class MaterialGuardianSnapshotStore {
  Future<MaterialGuardianSnapshot> load() async {
    final file = await _snapshotFile();
    final backupFile = await _backupSnapshotFile();
    final primarySnapshot = await _loadFromFile(file);
    if (primarySnapshot != null) {
      return primarySnapshot;
    }

    final backupSnapshot = await _loadFromFile(backupFile);
    if (backupSnapshot != null) {
      try {
        await save(backupSnapshot);
      } catch (error, stackTrace) {
        debugPrint(
          'Material snapshot restore from backup failed: $error\n$stackTrace',
        );
      }
      return backupSnapshot;
    }

    return const MaterialGuardianSnapshot();
  }

  Future<void> save(MaterialGuardianSnapshot snapshot) async {
    final file = await _snapshotFile();
    final backupFile = await _backupSnapshotFile();
    final tempFile = await _tempSnapshotFile();
    await file.parent.create(recursive: true);
    final encoded = const JsonEncoder.withIndent(
      '  ',
    ).convert(snapshot.toJson());
    await tempFile.writeAsString(encoded, flush: true);

    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    if (await file.exists()) {
      await file.rename(backupFile.path);
    }
    await tempFile.rename(file.path);
    await file.copy(backupFile.path);
  }

  Future<File> _snapshotFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/material_guardian_snapshot.json');
  }

  Future<File> _backupSnapshotFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/material_guardian_snapshot.backup.json');
  }

  Future<File> _tempSnapshotFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/material_guardian_snapshot.tmp.json');
  }

  Future<MaterialGuardianSnapshot?> _loadFromFile(File file) async {
    if (!await file.exists()) {
      return null;
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return const MaterialGuardianSnapshot();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Snapshot root JSON must be an object.');
      }
      return MaterialGuardianSnapshot.fromJson(decoded);
    } catch (error, stackTrace) {
      debugPrint('Material snapshot load failed for ${file.path}: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}

class MaterialGuardianSnapshot {
  const MaterialGuardianSnapshot({
    this.jobs = const [],
    this.drafts = const [],
    this.localTrialJobsConsumed = 0,
  });

  final List<JobRecord> jobs;
  final List<MaterialDraft> drafts;
  final int localTrialJobsConsumed;

  Map<String, dynamic> toJson() {
    return {
      'jobs': jobs.map((job) => job.toJson()).toList(growable: false),
      'drafts': drafts.map((draft) => draft.toJson()).toList(growable: false),
      'localTrialJobsConsumed': localTrialJobsConsumed,
    };
  }

  factory MaterialGuardianSnapshot.fromJson(Map<String, dynamic> json) {
    return MaterialGuardianSnapshot(
      jobs: ((json['jobs'] as List<dynamic>?) ?? const [])
          .map((item) => JobRecord.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      drafts: ((json['drafts'] as List<dynamic>?) ?? const [])
          .map((item) => MaterialDraft.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      localTrialJobsConsumed:
          (json['localTrialJobsConsumed'] as num?)?.toInt() ?? 0,
    );
  }
}
