#!/usr/bin/env bash
# Fast loop for changing the app in metacode/. Never launches the app.
#   1. validate models/state/ui/actions/bindings and generate code
#   2. type-check metacode/
#   3. run metacode/test (actions and bindings, through the compiled program)
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== generate"
dart run tool/metacode.dart 2>&1 | sed 's/Running build hooks\.\.\.//g'

echo "== analyze"
dart analyze --fatal-infos metacode

echo "== test"
flutter test --reporter failures-only metacode/test
echo "OK"
