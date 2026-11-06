#!/usr/bin/env bash
# Full check after changing the engine, the tool or app_ui. Never launches the app.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== generate"
dart run tool/metacode.dart 2>&1 | sed 's/Running build hooks\.\.\.//g'

echo "== analyze"
flutter analyze

echo "== test"
flutter test --reporter failures-only test metacode/test
(cd packages/app_ui && flutter test --reporter failures-only)
echo "OK"
