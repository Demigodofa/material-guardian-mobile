import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import 'android_export_bridge.dart';
import 'storage_utils.dart';

enum PhotoCaptureSource { camera, gallery }

class MaterialMediaService {
  MaterialMediaService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  static const MethodChannel _mediaChannel = MethodChannel(
    'com.asme.receiving/media',
  );

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
    return _copyNormalizedImageToDirectory(
      sourcePath: pickedFile.path,
      targetDirectory: targetDirectory,
      targetBaseName:
          '${safeBaseName(materialLabel, fallback: 'material')}_photo_$nextIndex',
    );
  }

  Future<String> saveCapturedPhoto({
    required String sourcePath,
    required String jobNumber,
    required String materialLabel,
    required int nextIndex,
  }) async {
    final targetDirectory = await appSupportSubdirectory([
      'job_media',
      safeBaseName(jobNumber, fallback: 'job'),
      'photos',
    ]);
    final savedPath = await _copyNormalizedImageToDirectory(
      sourcePath: sourcePath,
      targetDirectory: targetDirectory,
      targetBaseName:
          '${safeBaseName(materialLabel, fallback: 'material')}_photo_$nextIndex',
    );
    await deletePath(sourcePath);
    return savedPath;
  }

  Future<String> saveCapturedScan({
    required String sourcePath,
    required String jobNumber,
    required String materialLabel,
    required int nextIndex,
  }) async {
    final targetDirectory = await appSupportSubdirectory([
      'job_media',
      safeBaseName(jobNumber, fallback: 'job'),
      'scans',
    ]);
    final savedPath = await _copyNormalizedImageToDirectory(
      sourcePath: sourcePath,
      targetDirectory: targetDirectory,
      targetBaseName:
          '${safeBaseName(materialLabel, fallback: 'material')}_scan_$nextIndex',
    );
    await deletePath(sourcePath);
    return savedPath;
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
      final targetBaseName =
          '${safeBaseName(materialLabel, fallback: 'material')}_scan_${startingIndex + index}';
      final targetPath = isPdfPath(file.path!)
          ? await copyFileToDirectory(
              sourcePath: file.path!,
              targetDirectory: targetDirectory,
              targetBaseName: targetBaseName,
            )
          : await _copyNormalizedImageToDirectory(
              sourcePath: file.path!,
              targetDirectory: targetDirectory,
              targetBaseName: targetBaseName,
            );
      imported.add(targetPath);
    }
    return imported;
  }

  Future<List<String>> scanDocumentsWithDeviceScanner({
    required String jobNumber,
    required String materialLabel,
    required int nextIndex,
    required int pageLimit,
  }) async {
    if (!Platform.isAndroid) {
      return const [];
    }

    final rawResults =
        await _mediaChannel.invokeMethod<List<dynamic>>('scanDocuments', {
          'jobNumber': jobNumber,
          'materialLabel': materialLabel,
          'nextIndex': nextIndex,
          'pageLimit': pageLimit,
        }) ??
        const <dynamic>[];

    final paths = <String>[];
    for (final entry in rawResults) {
      if (entry is Map) {
        final path = entry['path']?.toString().trim() ?? '';
        if (path.isNotEmpty) {
          paths.add(path);
        }
      }
    }
    return paths;
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
    if (isPdfPath(normalized)) {
      final previewFile = File(pdfPreviewSiblingPath(normalized));
      if (await previewFile.exists()) {
        await previewFile.delete();
      }
    }
  }

  Future<bool> openPath(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final openTarget = await _resolveOpenTarget(normalized);
    if (openTarget == null) {
      return false;
    }
    final result = await OpenFilex.open(openTarget);
    return result.type == ResultType.done;
  }

  Future<bool> openExport({
    required String exportRootPath,
    required String jobNumber,
  }) async {
    if (Platform.isAndroid) {
      try {
        final opened = await AndroidExportBridge.openDownloadsExport(
          sourceRootPath: exportRootPath,
          downloadsSubdirectory:
              'MaterialGuardian/${safeBaseName(jobNumber, fallback: 'job')}',
        );
        if (opened) {
          return true;
        }
      } catch (_) {
        // Fall back to the generic file opener if the Android bridge fails.
      }
    }
    return openPath(exportRootPath);
  }

  Future<String?> _resolveOpenTarget(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return path;
    }

    final directory = Directory(path);
    if (!await directory.exists()) {
      return null;
    }

    final zipPath =
        '$path${path.endsWith(r'\') || path.endsWith('/') ? '' : Platform.pathSeparator}${path.split(RegExp(r'[\\/]')).last}.zip';
    final zipFile = File(zipPath);
    if (await zipFile.exists()) {
      return zipPath;
    }

    final packetDirectory = Directory(
      '$path${path.endsWith(r'\') || path.endsWith('/') ? '' : Platform.pathSeparator}material_packets',
    );
    if (!await packetDirectory.exists()) {
      return null;
    }

    final packetFiles =
        packetDirectory
            .listSync()
            .whereType<File>()
            .where((entry) => isPdfPath(entry.path))
            .toList(growable: false)
          ..sort((left, right) => left.path.compareTo(right.path));
    if (packetFiles.isEmpty) {
      return null;
    }
    return packetFiles.first.path;
  }

  Future<String> _copyNormalizedImageToDirectory({
    required String sourcePath,
    required Directory targetDirectory,
    required String targetBaseName,
  }) async {
    final sourceBytes = await File(sourcePath).readAsBytes();
    final normalizedBytes = _normalizeImageBytes(sourceBytes);
    if (normalizedBytes == null) {
      return copyFileToDirectory(
        sourcePath: sourcePath,
        targetDirectory: targetDirectory,
        targetBaseName: targetBaseName,
        forcedExtension: '.jpg',
      );
    }
    return writeBytesToDirectory(
      bytes: normalizedBytes,
      targetDirectory: targetDirectory,
      targetBaseName: targetBaseName,
      extension: '.jpg',
    );
  }

  Uint8List? _normalizeImageBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return null;
    }
    final baked = img.bakeOrientation(decoded);
    return Uint8List.fromList(img.encodeJpg(baked, quality: 92));
  }
}
