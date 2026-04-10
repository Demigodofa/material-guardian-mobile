package com.asme.receiving

import android.app.Activity
import android.app.DownloadManager
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.content.IntentSender
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.provider.MediaStore
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private var pendingScanResult: MethodChannel.Result? = null
    private var pendingScanJobNumber: String? = null
    private var pendingScanMaterialLabel: String? = null
    private var pendingScanIndex: Int = 1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EXPORT_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncExportToDownloads" -> {
                    val sourceRootPath = call.argument<String>("sourceRootPath")
                    val downloadsSubdirectory = call.argument<String>("downloadsSubdirectory")
                    if (sourceRootPath.isNullOrBlank() || downloadsSubdirectory.isNullOrBlank()) {
                        result.error("bad_args", "Missing export sync arguments.", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        runCatching {
                            syncExportToDownloads(File(sourceRootPath), downloadsSubdirectory)
                            "Downloads/${downloadsSubdirectory.trim('/')}"
                        }.onSuccess { downloadsFolder ->
                            runOnUiThread { result.success(downloadsFolder) }
                        }.onFailure { error ->
                            runOnUiThread {
                                result.error("sync_failed", error.message, null)
                            }
                        }
                    }.start()
                }

                "openDownloadsExport" -> {
                    val sourceRootPath = call.argument<String>("sourceRootPath")
                    val downloadsSubdirectory = call.argument<String>("downloadsSubdirectory")
                    if (sourceRootPath.isNullOrBlank() || downloadsSubdirectory.isNullOrBlank()) {
                        result.error("bad_args", "Missing export open arguments.", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        runCatching {
                            val sourceRoot = File(sourceRootPath)
                            if (sourceRoot.exists()) {
                                syncExportToDownloads(sourceRoot, downloadsSubdirectory)
                            }
                        }
                        runOnUiThread {
                            result.success(
                                openDownloadsFolder("Downloads/${downloadsSubdirectory.trim('/')}")
                            )
                        }
                    }.start()
                }

                "deleteDownloadsExport" -> {
                    val downloadsSubdirectory = call.argument<String>("downloadsSubdirectory")
                    if (downloadsSubdirectory.isNullOrBlank()) {
                        result.error("bad_args", "Missing export delete arguments.", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        runCatching {
                            clearExistingDownloadsExport(downloadsSubdirectory.trim('/'))
                            true
                        }.onSuccess { deleted ->
                            runOnUiThread { result.success(deleted) }
                        }.onFailure { error ->
                            runOnUiThread {
                                result.error("delete_failed", error.message, null)
                            }
                        }
                    }.start()
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MEDIA_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanDocuments" -> {
                    val jobNumber = call.argument<String>("jobNumber")
                    val materialLabel = call.argument<String>("materialLabel")
                    val nextIndex = call.argument<Int>("nextIndex") ?: 1
                    val pageLimit = (call.argument<Int>("pageLimit") ?: 1).coerceIn(1, 8)
                    if (jobNumber.isNullOrBlank() || materialLabel.isNullOrBlank()) {
                        result.error("bad_args", "Missing document scanner arguments.", null)
                        return@setMethodCallHandler
                    }
                    launchDocumentScan(
                        jobNumber = jobNumber,
                        materialLabel = materialLabel,
                        nextIndex = nextIndex,
                        pageLimit = pageLimit,
                        result = result,
                    )
                }

                "renderPdfPreview" -> {
                    val pdfPath = call.argument<String>("pdfPath")
                    if (pdfPath.isNullOrBlank()) {
                        result.error("bad_args", "Missing pdfPath.", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        runCatching {
                            renderPdfPreview(pdfPath)
                        }.onSuccess { previewPath ->
                            runOnUiThread { result.success(previewPath) }
                        }.onFailure { error ->
                            runOnUiThread {
                                result.error("preview_failed", error.message, null)
                            }
                        }
                    }.start()
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun launchDocumentScan(
        jobNumber: String,
        materialLabel: String,
        nextIndex: Int,
        pageLimit: Int,
        result: MethodChannel.Result,
    ) {
        if (pendingScanResult != null) {
            result.error("scan_in_progress", "Another document scan is already running.", null)
            return
        }

        pendingScanResult = result
        pendingScanJobNumber = jobNumber
        pendingScanMaterialLabel = materialLabel
        pendingScanIndex = nextIndex

        val options = GmsDocumentScannerOptions.Builder()
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
            .setPageLimit(pageLimit)
            .setResultFormats(
                GmsDocumentScannerOptions.RESULT_FORMAT_PDF,
                GmsDocumentScannerOptions.RESULT_FORMAT_JPEG
            )
            .build()

        GmsDocumentScanning.getClient(options)
            .getStartScanIntent(this)
            .addOnSuccessListener { intentSender ->
                try {
                    startIntentSenderForResult(
                        intentSender,
                        DOCUMENT_SCAN_REQUEST_CODE,
                        null,
                        0,
                        0,
                        0,
                    )
                } catch (error: IntentSender.SendIntentException) {
                    clearPendingScan()
                    result.error("scanner_unavailable", error.message, null)
                }
            }
            .addOnFailureListener { error ->
                clearPendingScan()
                result.error("scanner_unavailable", error.message, null)
            }
    }

    private fun saveDocumentScan(
        scanResult: GmsDocumentScanningResult?,
        jobNumber: String,
        materialLabel: String,
        nextIndex: Int,
    ): List<Map<String, String>> {
        val savedEntries = mutableListOf<Map<String, String>>()
        val pdf = scanResult?.pdf
        val pageUris = scanResult?.pages?.mapNotNull { it.imageUri } ?: emptyList()
        if (pdf != null) {
            val targetFile = buildScanPdfFile(jobNumber, materialLabel, nextIndex)
            copyUriToFile(pdf.uri, targetFile)
            if (pageUris.isNotEmpty()) {
                pageUris.forEachIndexed { previewIndex, pageUri ->
                    val previewFile = buildScanPreviewFile(
                        jobNumber,
                        materialLabel,
                        nextIndex,
                        previewIndex + 1,
                    )
                    copyUriToFile(pageUri, previewFile)
                }
            }
            savedEntries += mapOf("path" to targetFile.absolutePath)
            return savedEntries
        }

        val firstPageUri = pageUris.firstOrNull()
        if (firstPageUri != null) {
            val fallbackPreview = buildScanImageFile(jobNumber, materialLabel, nextIndex)
            copyUriToFile(firstPageUri, fallbackPreview)
            savedEntries += mapOf("path" to fallbackPreview.absolutePath)
        }
        return savedEntries
    }

    private fun copyUriToFile(sourceUri: Uri, targetFile: File) {
        targetFile.parentFile?.mkdirs()
        contentResolver.openInputStream(sourceUri)?.use { input ->
            targetFile.outputStream().use { output ->
                input.copyTo(output)
            }
        } ?: error("Could not open document scanner output.")
    }

    private fun buildScanPdfFile(
        jobNumber: String,
        materialLabel: String,
        index: Int,
    ): File {
        val safeJob = sanitizeFileComponent(jobNumber)
        val safeLabel = sanitizeFileComponent(materialLabel).ifBlank { "material" }
        val baseName = safeLabel.take(24)
        val folder = File(filesDir, "job_media/$safeJob/scans")
        folder.mkdirs()
        return File(folder, "${baseName}_scan_$index.pdf")
    }

    private fun buildScanPreviewFile(
        jobNumber: String,
        materialLabel: String,
        index: Int,
        pageNumber: Int,
    ): File {
        val safeJob = sanitizeFileComponent(jobNumber)
        val safeLabel = sanitizeFileComponent(materialLabel).ifBlank { "material" }
        val baseName = safeLabel.take(24)
        val folder = File(filesDir, "job_media/$safeJob/scans")
        folder.mkdirs()
        val suffix = if (pageNumber <= 1) "_preview.jpg" else "_preview_${pageNumber}.jpg"
        return File(folder, "${baseName}_scan_${index}$suffix")
    }

    private fun buildScanImageFile(
        jobNumber: String,
        materialLabel: String,
        index: Int,
    ): File {
        val safeJob = sanitizeFileComponent(jobNumber)
        val safeLabel = sanitizeFileComponent(materialLabel).ifBlank { "material" }
        val baseName = safeLabel.take(24)
        val folder = File(filesDir, "job_media/$safeJob/scans")
        folder.mkdirs()
        return File(folder, "${baseName}_scan_$index.jpg")
    }

    private fun sanitizeFileComponent(value: String): String =
        value.lowercase().replace(Regex("[^a-z0-9]+"), "_").trim('_')

    private fun renderPdfPreview(pdfPath: String): String {
        val sourceFile = File(pdfPath)
        require(sourceFile.exists()) { "PDF file does not exist: $pdfPath" }

        clearPreviewSiblingFiles(sourceFile)
        var firstPreviewPath: String? = null
        ParcelFileDescriptor.open(sourceFile, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
            PdfRenderer(descriptor).use { renderer ->
                require(renderer.pageCount > 0) { "PDF has no pages: $pdfPath" }
                for (pageIndex in 0 until renderer.pageCount) {
                    val previewFile = buildPreviewSiblingFile(sourceFile, pageIndex + 1)
                    renderer.openPage(pageIndex).use { page ->
                        val width = (page.width * 0.35f).toInt().coerceAtLeast(180)
                        val height = (page.height * 0.35f).toInt().coerceAtLeast(240)
                        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                        bitmap.eraseColor(Color.WHITE)
                        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                        previewFile.parentFile?.mkdirs()
                        FileOutputStream(previewFile).use { output ->
                            bitmap.compress(Bitmap.CompressFormat.JPEG, 88, output)
                        }
                        bitmap.recycle()
                        if (firstPreviewPath == null) {
                            firstPreviewPath = previewFile.absolutePath
                        }
                    }
                }
            }
        }
        return firstPreviewPath ?: error("No PDF preview pages were generated for $pdfPath")
    }

    private fun buildPreviewSiblingFile(sourceFile: File, pageNumber: Int = 1): File {
        val fileName = sourceFile.name
        val baseName = fileName.substringBeforeLast('.', fileName)
        val suffix = if (pageNumber <= 1) "_preview.jpg" else "_preview_${pageNumber}.jpg"
        return File(sourceFile.parentFile, "$baseName$suffix")
    }

    private fun clearPreviewSiblingFiles(sourceFile: File) {
        for (pageNumber in 1..99) {
            val previewFile = buildPreviewSiblingFile(sourceFile, pageNumber)
            if (!previewFile.exists()) {
                if (pageNumber == 1) {
                    continue
                }
                break
            }
            previewFile.delete()
        }
    }

    private fun clearPendingScan() {
        pendingScanResult = null
        pendingScanJobNumber = null
        pendingScanMaterialLabel = null
        pendingScanIndex = 1
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != DOCUMENT_SCAN_REQUEST_CODE) {
            return
        }

        val result = pendingScanResult
        val jobNumber = pendingScanJobNumber
        val materialLabel = pendingScanMaterialLabel
        val nextIndex = pendingScanIndex
        clearPendingScan()

        if (result == null) {
            return
        }
        if (resultCode != Activity.RESULT_OK) {
            result.success(emptyList<Map<String, String>>())
            return
        }
        if (jobNumber.isNullOrBlank() || materialLabel.isNullOrBlank()) {
            result.error("scan_failed", "Scanner arguments were lost before completion.", null)
            return
        }

        val scanResult = GmsDocumentScanningResult.fromActivityResultIntent(data)
        runCatching {
            saveDocumentScan(
                scanResult = scanResult,
                jobNumber = jobNumber,
                materialLabel = materialLabel,
                nextIndex = nextIndex,
            )
        }.onSuccess { savedEntries ->
            result.success(savedEntries)
        }.onFailure { error ->
            result.error("scan_failed", error.message, null)
        }
    }

    private fun syncExportToDownloads(sourceRoot: File, downloadsSubdirectory: String) {
        if (!sourceRoot.exists() || !sourceRoot.isDirectory) {
            throw IllegalStateException("Export root does not exist: ${sourceRoot.absolutePath}")
        }

        val cleanedDownloadsSubdirectory = downloadsSubdirectory.trim('/')
        val rootPath = sourceRoot.absolutePath
        clearExistingDownloadsExport(cleanedDownloadsSubdirectory)

        sourceRoot.walkTopDown().forEach { file ->
            if (file.isDirectory) {
                return@forEach
            }

            val relativePath = file.absolutePath
                .removePrefix(rootPath)
                .trimStart(File.separatorChar)
            val relativeParent = File(relativePath).parent
                ?.replace(File.separatorChar, '/')
                ?.trim('/')
            val targetRelativeDir = listOfNotNull(cleanedDownloadsSubdirectory, relativeParent)
                .filter { it.isNotBlank() }
                .joinToString("/")
            val displayName = file.name

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val resolver = contentResolver
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
                    put(MediaStore.MediaColumns.MIME_TYPE, guessMimeType(displayName))
                    put(
                        MediaStore.MediaColumns.RELATIVE_PATH,
                        Environment.DIRECTORY_DOWNLOADS + "/$targetRelativeDir"
                    )
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: throw IllegalStateException("Could not create Downloads entry for $displayName")

                runCatching {
                    resolver.openOutputStream(uri)?.use { output ->
                        file.inputStream().use { input -> input.copyTo(output) }
                    } ?: error("Could not open output stream for $displayName")
                    resolver.update(
                        uri,
                        ContentValues().apply {
                            put(MediaStore.MediaColumns.IS_PENDING, 0)
                        },
                        null,
                        null
                    )
                }.getOrElse { error ->
                    resolver.delete(uri, null, null)
                    throw error
                }
            } else {
                val legacyDir = File(
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                    targetRelativeDir
                )
                legacyDir.mkdirs()
                file.copyTo(File(legacyDir, displayName), overwrite = true)
            }
        }
    }

    private fun openDownloadsFolder(exportPath: String): Boolean {
        val normalizedPath = exportPath.trim()
            .replace('\\', '/')
            .trim('/')
        if (normalizedPath.isBlank()) {
            return false
        }

        val relativeToDownloads = normalizedPath
            .removePrefix("Downloads/")
            .removePrefix("Download/")
            .trim('/')

        val folderDocumentId = buildDownloadsDocumentId(relativeToDownloads)
        val folderUri = DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            folderDocumentId
        )

        val exactFolderIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(folderUri, DocumentsContract.Document.MIME_TYPE_DIR)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, folderUri)
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        if (launchIfSupported(exactFolderIntent)) {
            return true
        }

        val pickerIntent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, folderUri)
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        if (launchIfSupported(pickerIntent)) {
            return true
        }

        val downloadsIntent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return launchIfSupported(downloadsIntent)
    }

    private fun buildDownloadsDocumentId(relativeToDownloads: String): String {
        val cleanedRelativePath = relativeToDownloads.trim('/')
        return if (cleanedRelativePath.isBlank()) {
            "primary:Download"
        } else {
            "primary:Download/$cleanedRelativePath"
        }
    }

    private fun launchIfSupported(intent: Intent): Boolean {
        return runCatching {
            startActivity(intent)
            true
        }.getOrDefault(false)
    }

    private fun clearExistingDownloadsExport(downloadDir: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val relativePrefix = Environment.DIRECTORY_DOWNLOADS + "/$downloadDir/"
            val resolver = contentResolver
            val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
            resolver.query(
                collection,
                arrayOf(MediaStore.MediaColumns._ID),
                "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?",
                arrayOf("$relativePrefix%"),
                null
            )?.use { cursor ->
                val idIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idIndex)
                    resolver.delete(ContentUris.withAppendedId(collection, id), null, null)
                }
            }
        } else {
            val legacyDir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                downloadDir
            )
            if (legacyDir.exists()) {
                legacyDir.deleteRecursively()
            }
        }
    }

    private fun guessMimeType(name: String): String {
        return when {
            name.endsWith(".pdf", true) -> "application/pdf"
            name.endsWith(".jpg", true) || name.endsWith(".jpeg", true) -> "image/jpeg"
            name.endsWith(".png", true) -> "image/png"
            name.endsWith(".txt", true) -> "text/plain"
            name.endsWith(".zip", true) -> "application/zip"
            else -> "application/octet-stream"
        }
    }

    private fun String.trim(char: Char): String = trim { it == char }

    companion object {
        private const val EXPORT_CHANNEL = "com.asme.receiving/export"
        private const val MEDIA_CHANNEL = "com.asme.receiving/media"
        private const val DOCUMENT_SCAN_REQUEST_CODE = 7104
    }
}
