Set-StrictMode -Version Latest
$rel = Join-Path $PSScriptRoot "..\mobile\build\windows\x64\runner\Release"
if (-not (Test-Path $rel)) { throw "Release folder not found. Build first with flutter build windows --release" }
$out = Join-Path $PSScriptRoot "..\dist"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$zip = Join-Path $out "cadastro_municipal_offline_windows_release.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $rel "*") -DestinationPath $zip
Write-Host "OK: $zip"
