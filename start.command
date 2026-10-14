#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Carrot LLM"
DATA_DIR="$APP_SUPPORT_DIR/data"
LOG_FILE="$APP_SUPPORT_DIR/open-webui.log"
PID_FILE="$APP_SUPPORT_DIR/open-webui.pid"
SECRET_FILE="$APP_SUPPORT_DIR/webui_secret_key"
PORT="8080"
URL="http://127.0.0.1:${PORT}"
OLLAMA_URL="http://127.0.0.1:11434"
OLLAMA_BIN="$(command -v ollama || true)"
OLLAMA_APP=""
for candidate in "$HOME/Applications/Ollama.app" "/Applications/Ollama.app"; do
  if [[ -d "$candidate" ]]; then OLLAMA_APP="$candidate"; break; fi
done
if [[ -z "$OLLAMA_BIN" && -n "$OLLAMA_APP" && -x "$OLLAMA_APP/Contents/Resources/ollama" ]]; then
  OLLAMA_BIN="$OLLAMA_APP/Contents/Resources/ollama"
fi

say() { printf '\n🥕 %s\n' "$*"; }
fail() { printf '\nCarrot LLM: %s\n' "$*" >&2; printf 'See log: %s\n' "$LOG_FILE" >&2; exit 1; }

mkdir -p "$APP_SUPPORT_DIR" "$DATA_DIR"

OPEN_WEBUI_BIN="$(command -v open-webui || true)"
if [[ -z "$OPEN_WEBUI_BIN" ]]; then
  UV_BIN="$(command -v uv || true)"
  if [[ -z "$UV_BIN" && -x "$HOME/.local/bin/uv" ]]; then UV_BIN="$HOME/.local/bin/uv"; fi
  if [[ -z "$UV_BIN" && -x "$HOME/.cargo/bin/uv" ]]; then UV_BIN="$HOME/.cargo/bin/uv"; fi
  if [[ -n "$UV_BIN" ]]; then
    UV_TOOL_BIN="$("$UV_BIN" tool dir --bin 2>/dev/null || true)"
    if [[ -n "$UV_TOOL_BIN" && -x "$UV_TOOL_BIN/open-webui" ]]; then
      OPEN_WEBUI_BIN="$UV_TOOL_BIN/open-webui"
    fi
  fi
  if [[ -z "$OPEN_WEBUI_BIN" && -x "$HOME/.local/bin/open-webui" ]]; then
    OPEN_WEBUI_BIN="$HOME/.local/bin/open-webui"
  fi
fi
[[ -n "$OPEN_WEBUI_BIN" && -x "$OPEN_WEBUI_BIN" ]] || fail "Open WebUI is not installed. Run ./install.sh from the project folder first."
[[ -s "$SECRET_FILE" ]] || fail "Local setup is incomplete. Run ./install.sh from the project folder first."
[[ -n "$OLLAMA_BIN" && -x "$OLLAMA_BIN" ]] || fail "Ollama is not installed. Run ./install.sh from the project folder first."

"$PROJECT_DIR/scripts/ensure-ollama.sh" "$OLLAMA_BIN" "$APP_SUPPORT_DIR"

# Always confirm Ollama is available before reusing an already-running WebUI.
if curl -fsS --max-time 1 "$URL/health" >/dev/null 2>&1; then
  say "Carrot is already running. Opening the chat..."
  open "$URL"
  exit 0
fi

# If the saved process is alive, wait for that process instead of starting a second copy.
already_starting=false
if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ "$old_pid" =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
    if ps -p "$old_pid" -o command= 2>/dev/null | grep -q 'open-webui'; then
      already_starting=true
      say "Open WebUI is starting already; waiting for it to respond..."
    else
      rm -f "$PID_FILE"
    fi
  else
    rm -f "$PID_FILE"
  fi
fi

if ! curl -fsS --max-time 1 "$URL/health" >/dev/null 2>&1 && [[ "$already_starting" != true ]]; then
  if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    fail "Port $PORT is already used by another app. Stop that app or change PORT in start.command and stop.command."
  fi
  secret="$(cat "$SECRET_FILE")"
  say "Starting Open WebUI (first startup can take a minute)..."
  nohup env \
    DATA_DIR="$DATA_DIR" \
    WEBUI_SECRET_KEY="$secret" \
    OLLAMA_BASE_URL="$OLLAMA_URL" \
    DEFAULT_MODEL_METADATA='{"capabilities":{"file_context":false,"builtin_tools":false,"memory":false,"web_search":false,"code_interpreter":false,"vision":false}}' \
    ENABLE_CONTEXT_COMPACTION=true \
    CONTEXT_COMPACTION_TOKEN_THRESHOLD=2800 \
    CONTEXT_COMPACTION_TOKEN_CAP=2800 \
    CONTEXT_COMPACTION_RETENTION_PERCENTAGE=25 \
    "$OPEN_WEBUI_BIN" serve --host 127.0.0.1 --port "$PORT" \
    >> "$LOG_FILE" 2>&1 < /dev/null &
  echo "$!" > "$PID_FILE"
fi

ready=false
for _ in $(seq 1 60); do
  if curl -fsS --max-time 1 "$URL/health" >/dev/null 2>&1; then ready=true; break; fi
  sleep 2
done

if [[ "$ready" != true ]]; then
  fail "Open WebUI did not become ready. Check its log file."
fi

say "Ready. Opening Carrot in your browser."
open "$URL"
