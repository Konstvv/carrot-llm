#!/bin/bash
set -euo pipefail

OLLAMA_BIN="${1:?Usage: ensure-ollama.sh OLLAMA_BIN APP_SUPPORT_DIR}"
APP_SUPPORT_DIR="${2:?Usage: ensure-ollama.sh OLLAMA_BIN APP_SUPPORT_DIR}"
OLLAMA_URL="http://127.0.0.1:11434"
OLLAMA_LOG="$APP_SUPPORT_DIR/ollama-serve.log"
OLLAMA_PID_FILE="$APP_SUPPORT_DIR/ollama-serve.pid"
START_TIMEOUT=180

say() { printf '\n[%s] 🥕 %s\n' "$(date '+%H:%M:%S')" "$*"; }
fail() { printf '\nCarrot LLM: %s\n' "$*" >&2; exit 1; }

mkdir -p "$APP_SUPPORT_DIR"
if curl -fsS --max-time 2 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
  say "Ollama API is already responding."
  if [[ -s "$OLLAMA_LOG" ]]; then
    say "Recent output from the managed ollama serve process:"
    tail -n 12 "$OLLAMA_LOG"
  elif [[ -s "$HOME/.ollama/logs/server.log" ]]; then
    say "Recent output from the Ollama server:"
    tail -n 12 "$HOME/.ollama/logs/server.log"
  fi
  exit 0
fi

if [[ -f "$OLLAMA_PID_FILE" ]]; then
  old_pid="$(cat "$OLLAMA_PID_FILE" 2>/dev/null || true)"
  if [[ "$old_pid" =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
    old_command="$(ps -p "$old_pid" -o command= 2>/dev/null || true)"
    if [[ "$old_command" == *"$OLLAMA_BIN"* && "$old_command" == *"serve"* ]]; then
      say "Ollama serve is already running (process $old_pid); waiting for its API."
    else
      rm -f "$OLLAMA_PID_FILE"
    fi
  else
    rm -f "$OLLAMA_PID_FILE"
  fi
fi

if [[ ! -f "$OLLAMA_PID_FILE" ]]; then
  say "Starting Ollama with: $OLLAMA_BIN serve"
  say "Live server output will appear below and is saved to: $OLLAMA_LOG"
  nohup "$OLLAMA_BIN" serve >> "$OLLAMA_LOG" 2>&1 < /dev/null &
  ollama_pid=$!
  printf '%s\n' "$ollama_pid" > "$OLLAMA_PID_FILE"
fi

started_at=$SECONDS
attempt=0
while (( SECONDS - started_at < START_TIMEOUT )); do
  attempt=$((attempt + 1))
  elapsed=$((SECONDS - started_at))
  say "Waiting for Ollama API (${elapsed}s/${START_TIMEOUT}s; check $attempt)..."
  if curl -fsS --max-time 1 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
    say "Ollama is ready."
    if [[ -s "$OLLAMA_LOG" ]]; then
      say "Recent output from ollama serve:"
      tail -n 12 "$OLLAMA_LOG"
    fi
    exit 0
  fi
  if (( attempt % 5 == 0 )) && [[ -s "$OLLAMA_LOG" ]]; then
    say "Recent output from ollama serve:"
    tail -n 8 "$OLLAMA_LOG"
  fi
  sleep 1
done

if [[ -s "$OLLAMA_LOG" ]]; then
  say "Final output from ollama serve:"
  tail -n 30 "$OLLAMA_LOG"
fi
fail "Ollama did not respond within $START_TIMEOUT seconds. Review $OLLAMA_LOG for the server output."
