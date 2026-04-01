import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../app/models.dart';
import 'storage_utils.dart';

class JobExportResult {
  const JobExportResult({
    required this.exportRootPath,
    required this.packetPathsByMaterialId,
    required this.zipPath,
    required this.packetCount,
    required this.photoCount,
    required this.scanCount,
  });

  final String exportRootPath;
  final Map<String, String> packetPathsByMaterialId;
  final String zipPath;
  final int packetCount;
  final int photoCount;
  final int scanCount;
}

class JobExportService {
  Future<JobExportResult> exportJob({
    required JobRecord job,
    required CustomizationSettings customization,
  }) async {
    final exportDirectory = await appSupportSubdirectory([
      'exports',
      safeBaseName(job.jobNumber, fallback: 'job'),
      _timestampSegment(DateTime.now()),
    ]);
    if (await exportDirectory.exists()) {
      await exportDirectory.delete(recursive: true);
    }
    await exportDirectory.create(recursive: true);

    final packetDirectory = Directory(
      '${exportDirectory.path}${Platform.pathSeparator}material_packets',
    )..createSync(recursive: true);
    final sourceMediaDirectory = Directory(
      '${exportDirectory.path}${Platform.pathSeparator}source_media',
    )..createSync(recursive: true);

    final packetPathsByMaterialId = <String, String>{};
    var totalPhotos = 0;
    var totalScans = 0;

    for (var index = 0; index < job.materials.length; index++) {
      final material = job.materials[index];
      final packetFile = File(
        '${packetDirectory.path}${Platform.pathSeparator}'
        '${(index + 1).toString().padLeft(2, '0')}_${safeBaseName(material.description, fallback: material.tag)}_packet.pdf',
      );
      final packetBytes = await _buildPacketPdf(
        job: job,
        material: material,
        customization: customization,
      );
      await packetFile.writeAsBytes(packetBytes, flush: true);
      packetPathsByMaterialId[material.id] = packetFile.path;

      final materialMediaDirectory = Directory(
        '${sourceMediaDirectory.path}${Platform.pathSeparator}'
        '${(index + 1).toString().padLeft(2, '0')}_${safeBaseName(material.description, fallback: material.tag)}',
      )..createSync(recursive: true);

      for (final photoPath in material.photoPaths) {
        final copied = await _copyIfPresent(
          sourcePath: photoPath,
          targetDirectory: Directory(
            '${materialMediaDirectory.path}${Platform.pathSeparator}photos',
          )..createSync(recursive: true),
        );
        if (copied != null) {
          totalPhotos++;
        }
      }

      for (final scanPath in material.scanPaths) {
        final copied = await _copyIfPresent(
          sourcePath: scanPath,
          targetDirectory: Directory(
            '${materialMediaDirectory.path}${Platform.pathSeparator}scans',
          )..createSync(recursive: true),
        );
        if (copied != null) {
          totalScans++;
        }
      }
    }

    final infoFile = File(
      '${exportDirectory.path}${Platform.pathSeparator}export_info.txt',
    );
    await infoFile.writeAsString(
      [
        'Material Guardian export',
        'Job: ${job.jobNumber}',
        'Description: ${job.description}',
        'Materials: ${job.materials.length}',
        'Packet PDFs: ${packetPathsByMaterialId.length}',
        'Photos copied: $totalPhotos',
        'Scans copied: $totalScans',
      ].join('\n'),
      flush: true,
    );

    final zipPath = await _buildZip(exportDirectory);
    return JobExportResult(
      exportRootPath: exportDirectory.path,
      packetPathsByMaterialId: packetPathsByMaterialId,
      zipPath: zipPath,
      packetCount: packetPathsByMaterialId.length,
      photoCount: totalPhotos,
      scanCount: totalScans,
    );
  }

  Future<bool> sharePdfPackets(String exportRootPath) async {
    final packetFiles = latestPacketFiles(exportRootPath);
    if (packetFiles.isEmpty) {
      return false;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: packetFiles.map(XFile.new).toList(growable: false),
        text: 'Material Guardian packet PDFs',
      ),
    );
    return true;
  }

  Future<bool> shareZipBundle(String zipPath) async {
    if (zipPath.trim().isEmpty || !await File(zipPath).exists()) {
      return false;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zipPath)],
        text: 'Material Guardian export ZIP',
      ),
    );
    return true;
  }

  List<String> latestPacketFiles(String exportRootPath) {
    final packetDirectory = Directory(
      '$exportRootPath${Platform.pathSeparator}material_packets',
    );
    if (!packetDirectory.existsSync()) {
      return const [];
    }
    return packetDirectory
        .listSync()
        .whereType<File>()
        .where((file) => isPdfPath(file.path))
        .map((file) => file.path)
        .toList(growable: false)
      ..sort();
  }

  Future<Uint8List> _buildPacketPdf({
    required JobRecord job,
    required MaterialRecord material,
    required CustomizationSettings customization,
  }) async {
    final document = pw.Document();
    final logo = await _loadImage(
      customization.includeCompanyLogoOnReports
          ? customization.companyLogoPath
          : '',
    );
    final inspectorSignature = await _loadImage(material.qcSignaturePath);
    final managerSignature = await _loadImage(material.qcManagerSignaturePath);
    final inlineMedia = [
      ...material.scanPaths.where(isImagePath),
      ...material.photoPaths.where(isImagePath),
    ];

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            if (logo != null)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Image(logo, height: 48, fit: pw.BoxFit.contain),
              ),
            pw.Text(
              'Material Guardian Receiving Packet',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Job ${job.jobNumber}'),
            if (job.description.trim().isNotEmpty) pw.Text(job.description),
            if (job.notes.trim().isNotEmpty) pw.Text(job.notes),
            pw.SizedBox(height: 16),
            _fieldTable(<List<String>>[
              ['Tag', material.tag],
              ['Description', material.description],
              ['Vendor', material.vendor],
              ['Quantity', material.quantity],
              ['PO Number', material.poNumber],
              ['Product Type', material.productType],
              ['Specification', material.specificationPrefix],
              ['Grade', material.gradeType],
              ['Fitting Standard', material.fittingStandard],
              ['Fitting Suffix', material.fittingSuffix],
              ['Heat Number', material.heatNumber],
              ['Unit System', material.dimensionUnit.label],
              ['Thickness', material.thickness1],
              ['Width', material.width],
              ['Length', material.length],
              ['Diameter', material.diameter],
              ['Diameter Type', material.diameterType],
              ['B16', material.b16DimensionsAcceptable],
              ['Surface Finish', material.surfaceFinishCode],
              ['Surface Finish Reading', material.surfaceFinishReading],
              ['Surface Finish Unit', material.surfaceFinishUnit],
              [
                'Visual Inspection',
                material.visualInspectionAcceptable ? 'Yes' : 'No',
              ],
              ['Markings', material.markings],
              [
                'Marking Acceptable',
                material.markingAcceptableNa
                    ? 'N/A'
                    : material.markingAcceptable
                    ? 'Yes'
                    : 'No',
              ],
              [
                'MTR Acceptable',
                material.mtrAcceptableNa
                    ? 'N/A'
                    : material.mtrAcceptable
                    ? 'Yes'
                    : 'No',
              ],
              ['Acceptance Status', material.acceptanceStatus],
              ['Inspector', material.qcInspectorName],
              ['Manager', material.qcManagerName],
              ['Comments', material.comments],
            ]),
            pw.SizedBox(height: 16),
            if (material.scanPaths.where(isPdfPath).isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Attached scan PDFs included in export bundle:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 6),
                  for (final scanPath in material.scanPaths.where(isPdfPath))
                    pw.Text('- ${scanPath.split(Platform.pathSeparator).last}'),
                  pw.SizedBox(height: 12),
                ],
              ),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _signatureBlock(
                    'QC Inspector Signature',
                    inspectorSignature,
                  ),
                ),
                pw.SizedBox(width: 18),
                pw.Expanded(
                  child: _signatureBlock(
                    'QC Manager Signature',
                    managerSignature,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    for (final mediaPath in inlineMedia) {
      final image = await _loadImage(mediaPath);
      if (image == null) {
        continue;
      }
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                mediaPath.split(Platform.pathSeparator).last,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Uint8List.fromList(await document.save());
  }

  pw.Widget _fieldTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      data: <List<String>>[
        ['Field', 'Value'],
        ...rows.map((row) => [row[0], row[1].trim().isEmpty ? '-' : row[1]]),
      ],
    );
  }

  pw.Widget _signatureBlock(String title, pw.MemoryImage? image) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Container(
          height: 72,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          alignment: pw.Alignment.center,
          child: image == null
              ? pw.Text('No signature attached')
              : pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
        ),
      ],
    );
  }

  Future<pw.MemoryImage?> _loadImage(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final file = File(normalized);
    if (!await file.exists()) {
      return null;
    }
    if (!isImagePath(normalized)) {
      return null;
    }
    return pw.MemoryImage(await file.readAsBytes());
  }

  Future<String?> _copyIfPresent({
    required String sourcePath,
    required Directory targetDirectory,
  }) async {
    final normalized = sourcePath.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final sourceFile = File(normalized);
    if (!await sourceFile.exists()) {
      return null;
    }
    await targetDirectory.create(recursive: true);
    final targetPath =
        '${targetDirectory.path}${Platform.pathSeparator}${sourceFile.uri.pathSegments.last}';
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  Future<String> _buildZip(Directory exportDirectory) async {
    final zipPath =
        '${exportDirectory.path}${Platform.pathSeparator}${exportDirectory.uri.pathSegments.where((segment) => segment.isNotEmpty).last}.zip';
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    encoder.addDirectory(exportDirectory, includeDirName: false);
    encoder.close();
    return zipPath;
  }

  String _timestampSegment(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.year}${two(dateTime.month)}${two(dateTime.day)}_${two(dateTime.hour)}${two(dateTime.minute)}${two(dateTime.second)}';
  }
}
