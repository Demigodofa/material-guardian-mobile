import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import 'storage_utils.dart';

class CustomizationAssetService {
  Future<String?> importCompanyLogo() {
    return _pickAndStoreImage(targetBaseName: 'company_logo');
  }

  Future<String?> importSavedInspectorSignature() {
    return _pickAndStoreImage(targetBaseName: 'default_qc_inspector_signature');
  }

  Future<String> captureSavedInspectorSignature(Uint8List pngBytes) {
    return _storeGeneratedImage(
      pngBytes: pngBytes,
      targetBaseName: 'default_qc_inspector_signature',
    );
  }

  Future<void> clearAssetPath(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return;
    }
    final file = File(normalized);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> openAsset(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final result = await OpenFilex.open(normalized);
    return result.type == ResultType.done;
  }

  Future<String?> _pickAndStoreImage({required String targetBaseName}) async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: false,
    );
    final sourcePath = selection?.files.single.path;
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return null;
    }

    final targetDirectory = await appSupportSubdirectory(['customization']);
    return _normalizeAndStoreImage(
      sourcePath: sourcePath,
      targetDirectory: targetDirectory,
      targetBaseName: targetBaseName,
    );
  }

  Future<String> _storeGeneratedImage({
    required Uint8List pngBytes,
    required String targetBaseName,
  }) async {
    final targetDirectory = await appSupportSubdirectory(['customization']);
    return writeBytesToDirectory(
      bytes: pngBytes,
      targetDirectory: targetDirectory,
      targetBaseName: targetBaseName,
    );
  }

  Future<String> _normalizeAndStoreImage({
    required String sourcePath,
    required Directory targetDirectory,
    required String targetBaseName,
  }) async {
    final sourceBytes = await File(sourcePath).readAsBytes();
    final normalized = _normalizeImageBytes(
      sourceBytes,
      preferredExtension: p.extension(sourcePath).toLowerCase(),
    );
    if (normalized == null) {
      return copyFileToDirectory(
        sourcePath: sourcePath,
        targetDirectory: targetDirectory,
        targetBaseName: targetBaseName,
      );
    }
    return writeBytesToDirectory(
      bytes: normalized.bytes,
      targetDirectory: targetDirectory,
      targetBaseName: targetBaseName,
      extension: normalized.extension,
    );
  }

  _NormalizedAssetImage? _normalizeImageBytes(
    Uint8List bytes, {
    required String preferredExtension,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return null;
    }
    final baked = img.bakeOrientation(decoded);
    if (preferredExtension == '.png') {
      return _NormalizedAssetImage(
        bytes: Uint8List.fromList(img.encodePng(baked)),
        extension: '.png',
      );
    }
    return _NormalizedAssetImage(
      bytes: Uint8List.fromList(img.encodeJpg(baked, quality: 92)),
      extension: '.jpg',
    );
  }
}

class _NormalizedAssetImage {
  const _NormalizedAssetImage({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}
