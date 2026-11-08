#!/usr/bin/env bash
# Fast loop for changing the app in examples/my_own_app/ (and its modules in modules/).
# Never launches the app.
#   1. validate every app (models, state, view, actions, values...) and generate code
#   2. type-check examples/my_own_app/
#   3. run every app's tests (the main() in each action and value file, through the compiled program)
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== generate"
dart run tool/metacode.dart 2>&1 | sed 's/Running build hooks\.\.\.//g'

echo "== analyze"
dart analyze --fatal-infos examples/my_own_app

echo "== test"
flutter test --reporter failures-only \
  $(grep -rl --include='*.dart' --exclude-dir=.generated '^void main' examples/my_own_app | sort)
echo "OK"
