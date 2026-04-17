import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class NormalizedImageAsset {
  const NormalizedImageAsset({
    required this.bytes,
    required this.extension,
  });

  final Uint8List bytes;
  final String extension;
}

Future<Directory> appSupportSubdirectory(List<String> segments) async {
  final root = await getApplicationSupportDirectory();
  return Directory(p.joinAll([root.path, ...segments]));
}

String sanitizeFileComponent(String value) {
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return normalized.replaceAll(RegExp(r'^_+|_+$'), '');
}

String safeBaseName(String value, {String fallback = 'item'}) {
  final cleaned = sanitizeFileComponent(value);
  return cleaned.isEmpty ? fallback : cleaned;
}

bool isImagePath(String path) {
  final extension = p.extension(path).toLowerCase();
  return extension == '.png' ||
      extension == '.jpg' ||
      extension == '.jpeg' ||
      extension == '.webp' ||
      extension == '.heic' ||
      extension == '.heif';
}

bool isPdfPath(String path) {
  return p.extension(path).toLowerCase() == '.pdf';
}

Future<String> copyFileToDirectory({
  required String sourcePath,
  required Directory targetDirectory,
  required String targetBaseName,
  String? forcedExtension,
}) async {
  await targetDirectory.create(recursive: true);
  final sourceFile = File(sourcePath);
  final extension =
      forcedExtension ?? p.extension(sourceFile.path).toLowerCase().trim();
  final targetPath = p.join(targetDirectory.path, '$targetBaseName$extension');
  await sourceFile.copy(targetPath);
  return targetPath;
}

Future<String> writeBytesToDirectory({
  required Uint8List bytes,
  required Directory targetDirectory,
  required String targetBaseName,
  String extension = '.png',
}) async {
  await targetDirectory.create(recursive: true);
  final normalizedExtension = extension.startsWith('.')
      ? extension
      : '.$extension';
  final targetPath = p.join(
    targetDirectory.path,
    '$targetBaseName$normalizedExtension',
  );
  await File(targetPath).writeAsBytes(bytes, flush: true);
  return targetPath;
}

String pdfPreviewSiblingPath(String pdfPath, {int pageNumber = 1}) {
  final extension = p.extension(pdfPath);
  final suffix = pageNumber <= 1 ? '_preview.jpg' : '_preview_$pageNumber.jpg';
  if (extension.isEmpty) {
    return '$pdfPath$suffix';
  }
  return pdfPath.replaceFirst(RegExp('${RegExp.escape(extension)}\$'), suffix);
}

Future<NormalizedImageAsset?> normalizeImageAsset(Uint8List bytes) async {
  final decoded = img.decodeImage(bytes);
  if (decoded != null) {
    final baked = img.bakeOrientation(decoded);
    return NormalizedImageAsset(
      bytes: Uint8List.fromList(img.encodeJpg(baked, quality: 92)),
      extension: '.jpg',
    );
  }

  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final pngBytes = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    frame.image.dispose();
    codec.dispose();
    if (pngBytes == null) {
      return null;
    }
    return NormalizedImageAsset(
      bytes: pngBytes.buffer.asUint8List(),
      extension: '.png',
    );
  } catch (_) {
    return null;
  }
}
