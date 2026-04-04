import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../app/models.dart';
import 'android_export_bridge.dart';
import 'storage_utils.dart';

class JobExportResult {
  const JobExportResult({
    required this.exportRootPath,
    required this.downloadsFolder,
    required this.packetPathsByMaterialId,
    required this.zipPath,
    required this.packetCount,
    required this.photoCount,
    required this.scanCount,
  });

  final String exportRootPath;
  final String downloadsFolder;
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
    final jobBaseName = safeBaseName(job.jobNumber, fallback: 'job');

    for (var index = 0; index < job.materials.length; index++) {
      final material = job.materials[index];
      final materialIndex = (index + 1).toString().padLeft(2, '0');
      final materialBaseName = safeBaseName(
        material.description,
        fallback: material.tag,
      );
      final packetFile = File(
        '${packetDirectory.path}${Platform.pathSeparator}'
        '${jobBaseName}_${materialIndex}_${materialBaseName}_packet.pdf',
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
        '${jobBaseName}_${materialIndex}_$materialBaseName',
      )..createSync(recursive: true);

      for (var photoIndex = 0; photoIndex < material.photoPaths.length; photoIndex++) {
        final photoPath = material.photoPaths[photoIndex];
        final copied = await _copyIfPresent(
          sourcePath: photoPath,
          targetDirectory: Directory(
            '${materialMediaDirectory.path}${Platform.pathSeparator}photos',
          )..createSync(recursive: true),
          targetBaseName:
              '${jobBaseName}_${materialIndex}_${materialBaseName}_photo_${(photoIndex + 1).toString().padLeft(2, '0')}',
        );
        if (copied != null) {
          totalPhotos++;
        }
      }

      for (var scanIndex = 0; scanIndex < material.scanPaths.length; scanIndex++) {
        final scanPath = material.scanPaths[scanIndex];
        final copied = await _copyIfPresent(
          sourcePath: scanPath,
          targetDirectory: Directory(
            '${materialMediaDirectory.path}${Platform.pathSeparator}scans',
          )..createSync(recursive: true),
          targetBaseName:
              '${jobBaseName}_${materialIndex}_${materialBaseName}_scan_${(scanIndex + 1).toString().padLeft(2, '0')}',
        );
        if (copied != null) {
          totalScans++;
        }
        if (isPdfPath(scanPath)) {
          final previewPath = pdfPreviewSiblingPath(scanPath);
          await _copyIfPresent(
            sourcePath: previewPath,
            targetDirectory: Directory(
              '${materialMediaDirectory.path}${Platform.pathSeparator}scans',
            )..createSync(recursive: true),
            targetBaseName:
                '${jobBaseName}_${materialIndex}_${materialBaseName}_scan_${(scanIndex + 1).toString().padLeft(2, '0')}_preview',
          );
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
    var downloadsFolder = '';
    try {
      downloadsFolder =
          await AndroidExportBridge.syncExportToDownloads(
            sourceRootPath: exportDirectory.path,
            downloadsSubdirectory:
                'MaterialGuardian/${safeBaseName(job.jobNumber, fallback: 'job')}',
          ) ??
          '';
    } catch (_) {
      downloadsFolder = '';
    }
    return JobExportResult(
      exportRootPath: exportDirectory.path,
      downloadsFolder: downloadsFolder,
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
    final documentScanPages = _documentScanImagePaths(material);
    final photoAttachments = _photoAttachmentPaths(material);
    final inspectionDateText = _formatExportDate(material.qcInspectorDate);
    final commentsText = [
      material.comments,
      material.description,
    ].where((value) => value.trim().isNotEmpty).join(' | ');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return [
            if (logo != null)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Image(logo, height: 30, fit: pw.BoxFit.contain),
                ),
              ),
            _reportHeaderBand('RECEIVING INSPECTION REPORT'),
            _reportGridRow([
              _ReportCell('Job No.', job.jobNumber, flex: 2),
              _ReportCell('Vendor', material.vendor, flex: 3),
            ]),
            _reportGridRow([
              _ReportCell('PO', material.poNumber, flex: 2),
              _ReportCell('Date', inspectionDateText, flex: 3),
            ]),
            _reportGridRow([
              _ReportCell('Quantity', material.quantity, flex: 1),
              _ReportCell('Product', material.productType, flex: 2),
              _ReportCell('Specification', material.specificationPrefix, flex: 1),
              _ReportCell('Grade/Type', material.gradeType, flex: 1),
              _ReportCell('Fitting', _fittingValue(material), flex: 1),
            ]),
            _reportGridRow([
              _ReportCell('Dimensions', material.dimensionUnit.label, flex: 1),
              _ReportCell('Width', material.width, flex: 1),
              _ReportCell('Length', material.length, flex: 1),
              _ReportCell('Diameter', material.diameter, flex: 1),
              _ReportCell('ID / OD', material.diameterType, flex: 1),
            ]),
            _reportGridRow([
              _ReportCell('TH 1', material.thickness1, flex: 1),
              _ReportCell('TH 2', material.thickness2, flex: 1),
              _ReportCell('TH 3', material.thickness3, flex: 1),
              _ReportCell('TH 4', material.thickness4, flex: 1),
            ]),
            if (material.surfaceFinishCode.trim().isNotEmpty ||
                material.surfaceFinishReading.trim().isNotEmpty ||
                material.surfaceFinishUnit.trim().isNotEmpty)
              _reportGridRow([
                _ReportCell('Surface Finish', material.surfaceFinishCode, flex: 2),
                _ReportCell(
                  'Reading',
                  material.surfaceFinishReading,
                  flex: 2,
                ),
                _ReportCell('Unit', material.surfaceFinishUnit, flex: 1),
              ]),
            if (material.b16DimensionsAcceptable.trim().isNotEmpty)
              _reportGridRow([
                _ReportCell(
                  'B16 Dimensions Acceptable',
                  material.b16DimensionsAcceptable,
                ),
              ]),
            _reportGridRow([
              _ReportCell(
                'Visual Inspection Acceptable',
                material.visualInspectionAcceptable ? 'Yes' : 'No',
                flex: 3,
              ),
              _ReportCell(
                'Disposition',
                _formatDisposition(material.acceptanceStatus),
                flex: 2,
              ),
            ]),
            _reportGridRow([
              _ReportCell('Actual Material Marking', material.markings),
            ]),
            _reportGridRow([
              _ReportCell(
                'Marking Acceptable to Code / Standard',
                !material.markingSelected
                    ? 'N/A'
                    : material.markingAcceptableNa
                    ? 'N/A'
                    : material.markingAcceptable
                    ? 'Yes'
                    : 'No',
                flex: 1,
              ),
              _ReportCell(
                'MTR / CoC Acceptable to Specification',
                !material.mtrSelected
                    ? 'N/A'
                    : material.mtrAcceptableNa
                    ? 'N/A'
                    : material.mtrAcceptable
                    ? 'Yes'
                    : 'No',
                flex: 1,
              ),
            ]),
            _reportGridRow([
              _ReportCell('Comments', commentsText),
            ]),
            _reportGridRow([
              _ReportCell(
                'Material Approval',
                _formatMaterialDisposition(material.materialApproval),
              ),
            ]),
            _reportHeaderBand('QUALITY CONTROL SIGNOFF', topSpacing: 10),
            _reportGridRow([
              _ReportCell('QC Inspector', material.qcInspectorName, flex: 2),
              _ReportCell(
                'Initials / Date',
                '${_valueOrDash(material.qcInspectorName)} / $inspectionDateText',
                flex: 3,
              ),
            ]),
            _reportGridRow([
              _ReportCell('QC Manager', material.qcManagerName, flex: 2),
              _ReportCell(
                'Initials / Date',
                '${_valueOrDash(material.qcManagerName)} / ${_formatExportDate(material.qcManagerDate)}',
                flex: 3,
              ),
            ]),
            pw.SizedBox(height: 8),
            _reportHeaderBand('SIGNATURES', topSpacing: 0),
            pw.SizedBox(height: 4),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _signatureBlock(
                    'QC Inspector Signature',
                    inspectorSignature,
                    printedName: material.qcInspectorName,
                    dateText: inspectionDateText,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _signatureBlock(
                    'QC Manager Signature',
                    managerSignature,
                    printedName: material.qcManagerName,
                    dateText: _formatExportDate(material.qcManagerDate),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final documentScanItems = <_ExportMediaItem>[];
    for (final mediaPath in documentScanPages) {
      final image = await _loadImage(mediaPath);
      if (image == null) {
        continue;
      }
      documentScanItems.add(
        _ExportMediaItem(
          label: p.basename(mediaPath),
          image: image,
        ),
      );
    }

    for (final scanItem in documentScanItems) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SCANNED DOCUMENT',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(scanItem.image, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final photoAttachmentItems = <_ExportMediaItem>[];
    for (final mediaPath in photoAttachments) {
      final image = await _loadImage(mediaPath);
      if (image == null) {
        continue;
      }
      photoAttachmentItems.add(
        _ExportMediaItem(
          label: p.basename(mediaPath),
          image: image,
        ),
      );
    }

    for (final mediaChunk in _chunked(photoAttachmentItems, 4)) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PHOTO / IMAGE ATTACHMENTS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    for (var rowIndex = 0; rowIndex < 2; rowIndex++) ...[
                      pw.Expanded(
                        child: pw.Row(
                          children: [
                            for (var columnIndex = 0; columnIndex < 2; columnIndex++) ...[
                              pw.Expanded(
                                child: _mediaTile(
                                  _chunkItemAt(
                                    mediaChunk,
                                    rowIndex * 2 + columnIndex,
                                  ),
                                ),
                              ),
                              if (columnIndex == 0) pw.SizedBox(width: 10),
                            ],
                          ],
                        ),
                      ),
                      if (rowIndex == 0) pw.SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Uint8List.fromList(await document.save());
  }

  pw.Widget _reportHeaderBand(String title, {double topSpacing = 0}) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: topSpacing, bottom: 0),
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey300,
          border: pw.Border.all(width: 0.8, color: PdfColors.grey700),
        ),
        child: pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
      ),
    );
  }

  pw.Widget _reportGridRow(List<_ReportCell> cells) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.8, color: PdfColors.grey700),
      columnWidths: <int, pw.TableColumnWidth>{
        for (var index = 0; index < cells.length; index++)
          index: pw.FlexColumnWidth(cells[index].flex.toDouble()),
      },
      children: [
        pw.TableRow(
          children: [
            for (final cell in cells)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 4,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      cell.label,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 7.2,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      _valueOrDash(cell.value),
                      style: const pw.TextStyle(fontSize: 8.2),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatExportDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$month/$day/${local.year}';
  }

  pw.Widget _signatureBlock(
    String title,
    pw.MemoryImage? image, {
    required String printedName,
    required String dateText,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        if (printedName.trim().isNotEmpty) ...[
          pw.Text('Printed Name: $printedName', style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 2),
        ],
        pw.Text('Date: $dateText', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 44,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          alignment: pw.Alignment.center,
          child: image == null
              ? pw.Text('No signature attached', style: const pw.TextStyle(fontSize: 8))
              : pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
        ),
      ],
    );
  }

  pw.Widget _mediaTile(_ExportMediaItem? item) {
    if (item == null) {
      return pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      );
    }
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey700)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.label,
            style: const pw.TextStyle(fontSize: 8),
            maxLines: 1,
          ),
          pw.SizedBox(height: 4),
          pw.Expanded(
            child: pw.Center(
              child: pw.Image(item.image, fit: pw.BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  List<List<T>> _chunked<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (var index = 0; index < items.length; index += size) {
      final end = (index + size < items.length) ? index + size : items.length;
      chunks.add(items.sublist(index, end));
    }
    return chunks;
  }

  T? _chunkItemAt<T>(List<T> items, int index) {
    if (index < 0 || index >= items.length) {
      return null;
    }
    return items[index];
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
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return pw.MemoryImage(bytes);
    }
    final baked = img.bakeOrientation(decoded);
    final encoded = normalized.toLowerCase().endsWith('.png')
        ? img.encodePng(baked)
        : img.encodeJpg(baked, quality: 92);
    return pw.MemoryImage(Uint8List.fromList(encoded));
  }

  Future<String?> _copyIfPresent({
    required String sourcePath,
    required Directory targetDirectory,
    String? targetBaseName,
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
    final extension = p.extension(sourceFile.path);
    final targetFileName = targetBaseName == null || targetBaseName.trim().isEmpty
        ? sourceFile.uri.pathSegments.last
        : '${targetBaseName.trim()}$extension';
    final targetPath =
        '${targetDirectory.path}${Platform.pathSeparator}$targetFileName';
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  List<String> _photoAttachmentPaths(MaterialRecord material) {
    return material.photoPaths.where(isImagePath).toList(growable: false);
  }

  List<String> _documentScanImagePaths(MaterialRecord material) {
    final paths = <String>[];
    for (final scanPath in material.scanPaths) {
      if (isImagePath(scanPath)) {
        paths.add(scanPath);
        continue;
      }
      if (!isPdfPath(scanPath)) {
        continue;
      }
      paths.addAll(_pdfPreviewPaths(scanPath));
    }
    return paths;
  }

  List<String> _pdfPreviewPaths(String pdfPath) {
    final paths = <String>[];
    for (var pageNumber = 1; pageNumber <= 99; pageNumber++) {
      final previewPath = pdfPreviewSiblingPath(
        pdfPath,
        pageNumber: pageNumber,
      );
      if (!File(previewPath).existsSync()) {
        if (pageNumber == 1) {
          continue;
        }
        break;
      }
      paths.add(previewPath);
    }
    return paths;
  }

  Future<String> _buildZip(Directory exportDirectory) async {
    final zipPath = zipPathCandidatesForExportRoot(exportDirectory.path).first;
    final existingZip = File(zipPath);
    if (await existingZip.exists()) {
      await existingZip.delete();
    }
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    await encoder.addDirectory(exportDirectory, includeDirName: false);
    await encoder.close();
    return zipPath;
  }

  String _timestampSegment(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.year}${two(dateTime.month)}${two(dateTime.day)}_${two(dateTime.hour)}${two(dateTime.minute)}${two(dateTime.second)}';
  }

  String _fittingValue(MaterialRecord material) {
    final standard = material.fittingStandard.trim();
    final suffix = material.fittingSuffix.trim();
    if (standard.isEmpty || standard == 'N/A') {
      return suffix;
    }
    if (suffix.isEmpty) {
      return standard;
    }
    if (standard == 'B16') {
      return '$standard.$suffix';
    }
    return '$standard $suffix';
  }

  String _formatDisposition(String value) {
    switch (value.trim().toLowerCase()) {
      case 'accept':
        return 'Accept';
      case 'reject':
        return 'Reject';
      default:
        return value;
    }
  }

  String _formatMaterialDisposition(String value) {
    switch (value.trim().toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return value;
    }
  }

  String _valueOrDash(String value) {
    return value.trim().isEmpty ? '-' : value.trim();
  }
}

class _ExportMediaItem {
  const _ExportMediaItem({required this.label, required this.image});

  final String label;
  final pw.MemoryImage image;
}

class _ReportCell {
  const _ReportCell(this.label, this.value, {this.flex = 1});

  final String label;
  final String value;
  final int flex;
}
