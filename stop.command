#!/bin/bash
set -euo pipefail

APP_SUPPORT_DIR="$HOME/Library/Application Support/Carrot LLM"
PID_FILE="$APP_SUPPORT_DIR/open-webui.pid"
PORT="8080"

if [[ ! -f "$PID_FILE" ]]; then
  printf 'Carrot LLM does not have a recorded Open WebUI process.\n'
  exit 0
fi

pid="$(cat "$PID_FILE" 2>/dev/null || true)"
if [[ ! "$pid" =~ ^[0-9]+$ ]] || ! kill -0 "$pid" 2>/dev/null; then
  rm -f "$PID_FILE"
  printf 'Removed stale process record.\n'
  exit 0
fi

command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
if ! printf '%s' "$command_line" | grep -q 'open-webui'; then
  rm -f "$PID_FILE"
  printf 'The recorded process is no longer Open WebUI; left it untouched.\n'
  exit 0
fi

kill -TERM "$pid" 2>/dev/null || true
for _ in $(seq 1 10); do
  if ! kill -0 "$pid" 2>/dev/null; then break; fi
  sleep 1
done
if kill -0 "$pid" 2>/dev/null; then
  kill -KILL "$pid" 2>/dev/null || true
fi
rm -f "$PID_FILE"
printf 'Carrot LLM stopped. Ollama may still be running in the background.\n'
