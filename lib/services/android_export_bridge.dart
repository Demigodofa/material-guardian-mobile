import 'dart:io';

import 'package:flutter/services.dart';

class AndroidExportBridge {
  AndroidExportBridge._();

  static const MethodChannel _channel = MethodChannel(
    'com.asme.receiving/export',
  );

  static Future<String?> syncExportToDownloads({
    required String sourceRootPath,
    required String downloadsSubdirectory,
  }) async {
    if (!Platform.isAndroid) {
      return null;
    }
    return _channel.invokeMethod<String>('syncExportToDownloads', {
      'sourceRootPath': sourceRootPath,
      'downloadsSubdirectory': downloadsSubdirectory,
    });
  }

  static Future<bool> openDownloadsExport({
    required String sourceRootPath,
    required String downloadsSubdirectory,
  }) async {
    if (!Platform.isAndroid) {
      return false;
    }
    return (await _channel.invokeMethod<bool>('openDownloadsExport', {
          'sourceRootPath': sourceRootPath,
          'downloadsSubdirectory': downloadsSubdirectory,
        })) ??
        false;
  }

  static Future<bool> deleteDownloadsExport({
    required String downloadsSubdirectory,
  }) async {
    if (!Platform.isAndroid) {
      return false;
    }
    return (await _channel.invokeMethod<bool>('deleteDownloadsExport', {
          'downloadsSubdirectory': downloadsSubdirectory,
        })) ??
        false;
  }
}
