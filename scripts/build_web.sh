#!/usr/bin/env bash
set -e
cd mobile
flutter pub get
flutter build web --release
echo "OK: mobile/build/web/"
