#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Carrot LLM"
DESKTOP_LAUNCHER="$HOME/Desktop/Carrot LLM.command"

say() { printf '\n🥕 %s\n' "$*"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This uninstaller currently supports macOS only.\n' >&2
  exit 1
fi

cat <<'MENU'
Remove Carrot LLM?

  1) Remove Carrot, Open WebUI, and local chats/documents; keep Ollama and its models
  2) Remove everything, including Ollama and its default model storage
  q) Cancel
MENU
printf 'Choose 1, 2, or q [q]: '
read -r choice || choice="q"
case "$choice" in
  1|2) ;;
  *) say "Cancelled. Nothing was removed."; exit 0 ;;
esac

printf '\nThis will delete Carrot chat history, uploaded documents, and local settings.\n'
if [[ "$choice" == "2" ]]; then
  printf 'It will also delete the default Ollama model store and remove Ollama.app if present.\n'
fi
printf 'Type REMOVE to continue: '
read -r confirmation || confirmation=""
if [[ "$confirmation" != "REMOVE" ]]; then
  say "Cancelled. Nothing was removed."
  exit 0
fi

if [[ -x "$ROOT_DIR/stop.command" ]]; then
  say "Stopping Carrot..."
  "$ROOT_DIR/stop.command" || say "Carrot could not be stopped automatically; continuing cleanup."
fi

if [[ -f "$DESKTOP_LAUNCHER" ]] && grep -Eq '^exec .*start\.command$' "$DESKTOP_LAUNCHER"; then
  rm -f "$DESKTOP_LAUNCHER"
  say "Removed the Carrot desktop shortcut."
fi

UV_BIN="$(command -v uv || true)"
if [[ -z "$UV_BIN" ]]; then
  for candidate in "$HOME/.local/bin/uv" "$HOME/.cargo/bin/uv"; do
    if [[ -x "$candidate" ]]; then UV_BIN="$candidate"; break; fi
  done
fi
if [[ -n "$UV_BIN" ]]; then
  if "$UV_BIN" tool list 2>/dev/null | grep -q '^open-webui '; then
    say "Removing the Open WebUI tool installed for this account..."
    "$UV_BIN" tool uninstall open-webui || say "Open WebUI could not be removed automatically; use 'uv tool uninstall open-webui' if desired."
  fi
else
  say "uv was not found; no Open WebUI tool installation was removed."
fi

if [[ -f "$APP_SUPPORT_DIR/ollama-serve.pid" ]]; then
  ollama_pid="$(cat "$APP_SUPPORT_DIR/ollama-serve.pid" 2>/dev/null || true)"
  if [[ "$ollama_pid" =~ ^[0-9]+$ ]] && kill -0 "$ollama_pid" 2>/dev/null; then
    ollama_command="$(ps -p "$ollama_pid" -o command= 2>/dev/null || true)"
    if [[ "$ollama_command" == *"ollama"* && "$ollama_command" == *"serve"* ]]; then
      kill -TERM "$ollama_pid" 2>/dev/null || true
      for _ in $(seq 1 10); do
        if ! kill -0 "$ollama_pid" 2>/dev/null; then break; fi
        sleep 1
      done
      if kill -0 "$ollama_pid" 2>/dev/null; then kill -KILL "$ollama_pid" 2>/dev/null || true; fi
      say "Stopped the Ollama server started by Carrot."
    fi
  fi
fi

if [[ -d "$APP_SUPPORT_DIR" ]]; then
  rm -rf "$APP_SUPPORT_DIR"
  say "Removed Carrot's local data and settings."
fi

if [[ "$choice" == "2" ]]; then
  /usr/bin/osascript -e 'tell application "Ollama" to quit' >/dev/null 2>&1 || true
  sleep 2

  if [[ -d "$HOME/Applications/Ollama.app" ]]; then
    rm -rf "$HOME/Applications/Ollama.app"
    say "Removed ~/Applications/Ollama.app."
  fi
  if [[ -d "/Applications/Ollama.app" ]]; then
    if rm -rf "/Applications/Ollama.app" 2>/dev/null; then
      say "Removed /Applications/Ollama.app."
    else
      say "Could not remove /Applications/Ollama.app without administrator access; remove it from Applications if you want it gone."
    fi
  fi
  if [[ -d "$HOME/.ollama" ]]; then
    rm -rf "$HOME/.ollama"
    say "Removed Ollama's default local data and model storage (~/.ollama)."
  fi
  if [[ -n "${OLLAMA_MODELS:-}" ]]; then
    say "OLLAMA_MODELS is set to a custom location; that directory was left untouched: $OLLAMA_MODELS"
  fi
fi

say "Uninstall complete. The project folder was kept; delete it separately if you no longer need the files."
