#!/usr/bin/env bash
# The Claude bridge (tool/claude_server.dart) on http://localhost:8787: the
# editor's remote askClaude posts a prompt and the draft, it runs
# `claude -p` with the metacode MCP (.mcp.json: `claude` starts `tool/mc
# serve` itself). Runs detached, so a launch config can use it as a
# preLaunchTask: `start` returns as soon as the bridge answers.
#
#   tool/claude_bridge.sh          # start (if not running) and wait until it's up
#   tool/claude_bridge.sh stop     # stop it
#   tool/claude_bridge.sh logs     # follow its output (build/claude_bridge.log)
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
port="${PORT:-8787}"
log="$root/build/claude_bridge.log"
up() { curl -s -m 1 -o /dev/null "http://localhost:$port/starter"; }

case "${1:-start}" in
  start)
    if up; then echo "claude bridge: already running on :$port"; exit 0; fi
    command -v claude >/dev/null || { echo "claude bridge: the claude CLI is not on PATH" >&2; exit 1; }
    mkdir -p "$root/build"
    cd "$root"
    PORT="$port" nohup dart run tool/claude_server.dart </dev/null >"$log" 2>&1 &
    for _ in $(seq 1 120); do
      if up; then echo "claude bridge: running on :$port (logs: tool/claude_bridge.sh logs)"; exit 0; fi
      sleep 0.5
    done
    echo "claude bridge: did not start; see $log" >&2
    tail -20 "$log" >&2
    exit 1
    ;;
  stop)
    pkill -f "tool/claude_server.dart" || true
    lsof -tiTCP:"$port" -sTCP:LISTEN | xargs kill 2>/dev/null || true
    echo "claude bridge: stopped"
    ;;
  logs)
    tail -f "$log"
    ;;
esac
