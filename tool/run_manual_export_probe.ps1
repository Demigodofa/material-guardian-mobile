$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$env:MG_RUN_MANUAL_EXPORT_PROBE = '1'
$env:FLUTTER_ROOT = 'C:\Users\KevinPenfield\develop\flutter'

& "$env:FLUTTER_ROOT\bin\cache\dart-sdk\bin\dart.exe" `
  "$env:FLUTTER_ROOT\bin\cache\flutter_tools.snapshot" `
  test `
  test\manual_export_probe_test.dart `
  -r compact
