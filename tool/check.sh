#!/usr/bin/env bash
# Fast loop for changing the app in metacode/ (and its sub-apps in apps/).
# Never launches the app.
#   1. validate every app (models, state, ui, actions, relations...) and generate code
#   2. type-check metacode/
#   3. run every app's test/ (actions and relations, through the compiled program)
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== generate"
dart run tool/metacode.dart 2>&1 | sed 's/Running build hooks\.\.\.//g'

echo "== analyze"
dart analyze --fatal-infos metacode

echo "== test"
flutter test --reporter failures-only metacode/test $(find metacode/apps -type d -name test 2>/dev/null | sort)
echo "OK"
