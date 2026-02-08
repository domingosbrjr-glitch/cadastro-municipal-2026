#!/usr/bin/env bash
set -e
cd mobile
flutter pub get
flutter build apk --release
echo "OK: mobile/build/app/outputs/flutter-apk/app-release.apk"
