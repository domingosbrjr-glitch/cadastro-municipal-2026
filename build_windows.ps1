Set-StrictMode -Version Latest
cd mobile
flutter config --enable-windows-desktop
flutter pub get
flutter build windows --release
Write-Host "OK: mobile/build/windows/x64/runner/Release/"
