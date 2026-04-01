import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../app/models.dart';

class MaterialGuardianSnapshotStore {
  Future<MaterialGuardianSnapshot> load() async {
    final file = await _snapshotFile();
    if (!await file.exists()) {
      return const MaterialGuardianSnapshot();
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return const MaterialGuardianSnapshot();
    }

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return MaterialGuardianSnapshot.fromJson(json);
  }

  Future<void> save(MaterialGuardianSnapshot snapshot) async {
    final file = await _snapshotFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(snapshot.toJson()),
    );
  }

  Future<File> _snapshotFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/material_guardian_snapshot.json');
  }
}

class MaterialGuardianSnapshot {
  const MaterialGuardianSnapshot({
    this.jobs = const [],
    this.drafts = const [],
  });

  final List<JobRecord> jobs;
  final List<MaterialDraft> drafts;

  Map<String, dynamic> toJson() {
    return {
      'jobs': jobs.map((job) => job.toJson()).toList(growable: false),
      'drafts': drafts.map((draft) => draft.toJson()).toList(growable: false),
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
    );
  }
}
