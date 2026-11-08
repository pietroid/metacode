#!/usr/bin/env bash
# Full check after changing the engine, the tool or app_ui. Never launches the app.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== generate"
dart run tool/metacode.dart 2>&1 | sed 's/Running build hooks\.\.\.//g'
dart run tool/metacode.dart test/fixture_app 2>&1 | sed 's/Running build hooks\.\.\.//g'

echo "== reference"
dart run tool/reference.dart 2>&1 | sed 's/Running build hooks\.\.\.//g'

echo "== analyze"
flutter analyze

echo "== test"
flutter test --reporter failures-only \
  test \
  examples/my_own_app/.generated/all_test.dart \
  tool/layout_test.dart
(cd packages/app_ui && flutter test --reporter failures-only)

echo "== web (Chrome)"
dart run tool/web_fixture.dart 2>&1 | sed 's/Running build hooks\.\.\.//g'
flutter test --platform chrome --reporter failures-only test/web
echo "OK"
