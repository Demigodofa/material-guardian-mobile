import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_guardian_mobile/services/storage_utils.dart';

void main() {
  test('zipPathCandidatesForExportRoot handles both separator styles', () {
    final unixRoot = '/tmp/material_guardian/exports/job-1001';
    final unixExpectedPrimary =
        '$unixRoot${Platform.pathSeparator}job-1001.zip';
    final unixExpectedAlternate =
        '$unixRoot${Platform.pathSeparator == r'\' ? '/' : r'\'}job-1001.zip';

    expect(
      zipPathCandidatesForExportRoot(unixRoot),
      containsAll(<String>[unixExpectedPrimary, unixExpectedAlternate]),
    );

    final windowsRoot = r'C:\temp\exports\job-1001';
    expect(
      zipPathCandidatesForExportRoot(windowsRoot),
      containsAll(<String>[
        r'C:\temp\exports\job-1001/job-1001.zip',
        r'C:\temp\exports\job-1001\job-1001.zip',
      ]),
    );
  });
}
