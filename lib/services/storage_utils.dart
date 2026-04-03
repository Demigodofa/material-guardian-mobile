import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
      extension == '.webp';
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

String pdfPreviewSiblingPath(String pdfPath) {
  final extension = p.extension(pdfPath);
  if (extension.isEmpty) {
    return '${pdfPath}_preview.jpg';
  }
  return pdfPath.replaceFirst(RegExp('${RegExp.escape(extension)}\$'), '_preview.jpg');
}
