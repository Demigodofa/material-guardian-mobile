import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import 'storage_utils.dart';

enum PhotoCaptureSource { camera, gallery }

class MaterialMediaService {
  MaterialMediaService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<String?> addPhoto({
    required String jobNumber,
    required String materialLabel,
    required PhotoCaptureSource source,
    required int nextIndex,
  }) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source == PhotoCaptureSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 90,
    );
    if (pickedFile == null) {
      return null;
    }

    final targetDirectory = await appSupportSubdirectory([
      'job_media',
      safeBaseName(jobNumber, fallback: 'job'),
      'photos',
    ]);
    return copyFileToDirectory(
      sourcePath: pickedFile.path,
      targetDirectory: targetDirectory,
      targetBaseName:
          '${safeBaseName(materialLabel, fallback: 'material')}_photo_$nextIndex',
      forcedExtension: '.jpg',
    );
  }

  Future<List<String>> addScans({
    required String jobNumber,
    required String materialLabel,
    required int startingIndex,
    required int remainingSlots,
  }) async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: true,
    );
    final files =
        selection?.files
            .where((file) => file.path != null && file.path!.trim().isNotEmpty)
            .toList(growable: false) ??
        const [];
    if (files.isEmpty) {
      return const [];
    }

    final targetDirectory = await appSupportSubdirectory([
      'job_media',
      safeBaseName(jobNumber, fallback: 'job'),
      'scans',
    ]);

    final imported = <String>[];
    for (
      var index = 0;
      index < files.length && index < remainingSlots;
      index++
    ) {
      final file = files[index];
      final targetPath = await copyFileToDirectory(
        sourcePath: file.path!,
        targetDirectory: targetDirectory,
        targetBaseName:
            '${safeBaseName(materialLabel, fallback: 'material')}_scan_${startingIndex + index}',
      );
      imported.add(targetPath);
    }
    return imported;
  }

  Future<String?> importSignature({
    required String jobNumber,
    required String materialLabel,
    required String targetLabel,
  }) async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: false,
    );
    final sourcePath = selection?.files.single.path;
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return null;
    }

    final targetDirectory = await appSupportSubdirectory([
      'job_media',
      safeBaseName(jobNumber, fallback: 'job'),
      'signatures',
    ]);
    return copyFileToDirectory(
      sourcePath: sourcePath,
      targetDirectory: targetDirectory,
      targetBaseName:
          '${safeBaseName(materialLabel, fallback: 'material')}_${safeBaseName(targetLabel)}_signature',
    );
  }

  Future<String> captureSignature({
    required String jobNumber,
    required String materialLabel,
    required String targetLabel,
    required Uint8List pngBytes,
  }) async {
    final targetDirectory = await appSupportSubdirectory([
      'job_media',
      safeBaseName(jobNumber, fallback: 'job'),
      'signatures',
    ]);
    return writeBytesToDirectory(
      bytes: pngBytes,
      targetDirectory: targetDirectory,
      targetBaseName:
          '${safeBaseName(materialLabel, fallback: 'material')}_${safeBaseName(targetLabel)}_signature',
    );
  }

  Future<void> deletePath(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return;
    }
    final file = File(normalized);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> openPath(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final result = await OpenFilex.open(normalized);
    return result.type == ResultType.done;
  }
}
