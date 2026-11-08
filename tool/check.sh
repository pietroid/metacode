#!/usr/bin/env bash
# Fast loop for changing the app in examples/my_own_app/ (and its modules in modules/).
# Never launches the app.
#   1. validate every app (models, state, view, actions, values...) and generate code
#   2. compile every user file and run every app's tests (the main() in each
#      action and value file, through the compiled program), in one entrypoint
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== generate"
dart run tool/metacode.dart 2>&1 | sed 's/Running build hooks\.\.\.//g'

echo "== test"
flutter test --reporter failures-only examples/my_own_app/.generated/all_test.dart
echo "OK"
