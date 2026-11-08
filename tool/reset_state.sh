#!/usr/bin/env bash
# Resets an app's saved runtime state (.state/state.yaml) so the next launch
# starts from app.yaml's `state:`. Run it after changing the state's shape
# (a field added, renamed or retyped in app/models/), or the saved state no
# longer matches (e.g. "type 'Null' is not a subtype of type 'bool'").
#
#   tool/reset_state.sh                 # every app (root and all modules)
#   tool/reset_state.sh modules/food    # one app, relative to examples/my_own_app/
#
# Keeps .state/locale.yaml (the picked language). On web the state lives in
# localStorage: launch once with --dart-define=METACODE_RESET_FILES=true.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)/examples/my_own_app"
if [ $# -eq 0 ]; then
  find "$root" -path '*/.state/state.yaml' -not -path '*/.generated/*' -print -delete
else
  for app in "$@"; do
    f="$root/$app/.state/state.yaml"
    if [ -f "$f" ]; then rm "$f" && echo "$f"; else echo "no saved state: $app"; fi
  done
fi
