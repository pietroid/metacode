#!/usr/bin/env bash
# The Dart Frog backend (server/) on http://localhost:8080, for
# examples/my_own_app; its data in server/.backend/. Runs detached, so a
# launch config can use it as a preLaunchTask: `start` returns as soon as the
# backend answers (or right away if it already does).
#
#   tool/backend.sh          # start (if not running) and wait until it's up
#   tool/backend.sh dev      # the same with dart_frog's hot reload, only to
#                            # change the backend itself: it restarts on ANY
#                            # .dart change in the repo, dropping calls in flight
#   tool/backend.sh stop     # stop it
#   tool/backend.sh logs     # follow its output (server/.backend.log)
set -euo pipefail
server="$(cd "$(dirname "$0")/.." && pwd)/server"
port=8080
log="$server/.backend.log"
up() { curl -s -m 1 -o /dev/null "http://localhost:$port/"; }

case "${1:-start}" in
  start|dev)
    if up; then echo "metacode backend: already running on :$port"; exit 0; fi
    cd "$server"
    flutter pub get >/dev/null
    export METACODE_CODE=../examples/my_own_app METACODE_DATA=.backend PORT="$port"
    if [ "${1:-start}" = dev ]; then
      # `script` gives dart_frog a terminal (it fails without one) and nohup
      # keeps it alive after this script and the VS Code task end.
      nohup script -q /dev/null dart_frog dev --port "$port" </dev/null >"$log" 2>&1 &
    else
      # No hot reload (bin/serve.dart): the backend recompiles the apps on
      # its own, and a reload on every .dart change in the repo dropped calls.
      nohup dart run bin/serve.dart </dev/null >"$log" 2>&1 &
    fi
    for _ in $(seq 1 240); do
      if up; then echo "metacode backend: running on :$port (logs: tool/backend.sh logs)"; exit 0; fi
      sleep 0.5
    done
    echo "metacode backend: did not start; see $log" >&2
    tail -20 "$log" >&2
    exit 1
    ;;
  stop)
    pkill -f "dart_frog dev --port $port" || true
    pkill -f "bin/serve.dart" || true
    lsof -tiTCP:"$port" -sTCP:LISTEN | xargs kill 2>/dev/null || true
    echo "metacode backend: stopped"
    ;;
  logs)
    tail -f "$log"
    ;;
  *)
    echo "usage: tool/backend.sh [start|dev|stop|logs]" >&2
    exit 2
    ;;
esac
