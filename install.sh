#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Carrot LLM"

say() { printf '\n🥕 %s\n' "$*"; }
fail() { printf '\nCarrot setup: %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || fail "This setup script currently supports macOS only."
command -v curl >/dev/null 2>&1 || fail "curl was not found. Install Command Line Tools for macOS and retry."

if ! command -v ollama >/dev/null 2>&1; then
  cat >&2 <<'MSG'
Ollama CLI was not found.
1. Install Ollama for macOS from https://ollama.com/download/mac
2. Open the Ollama app once.
3. Run this setup script again.
MSG
  exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
  say "Installing uv with Astral's official installer..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

UV_BIN="$(command -v uv || true)"
if [[ -z "$UV_BIN" ]]; then
  for candidate in "$HOME/.local/bin/uv" "$HOME/.cargo/bin/uv"; do
    if [[ -x "$candidate" ]]; then UV_BIN="$candidate"; break; fi
  done
fi
[[ -n "$UV_BIN" && -x "$UV_BIN" ]] || fail "uv installation completed, but its executable was not found. Restart Terminal and retry."

say "Installing/updating Open WebUI in an isolated Python 3.11 environment..."
if "$UV_BIN" tool list 2>/dev/null | grep -q '^open-webui '; then
  "$UV_BIN" tool upgrade open-webui --python 3.11
else
  "$UV_BIN" tool install --python 3.11 open-webui
fi

OPEN_WEBUI_BIN="$(command -v open-webui || true)"
if [[ -z "$OPEN_WEBUI_BIN" ]]; then
  UV_TOOL_BIN="$("$UV_BIN" tool dir --bin 2>/dev/null || true)"
  if [[ -n "$UV_TOOL_BIN" && -x "$UV_TOOL_BIN/open-webui" ]]; then
    OPEN_WEBUI_BIN="$UV_TOOL_BIN/open-webui"
  elif [[ -x "$HOME/.local/bin/open-webui" ]]; then
    OPEN_WEBUI_BIN="$HOME/.local/bin/open-webui"
  fi
fi
[[ -n "$OPEN_WEBUI_BIN" && -x "$OPEN_WEBUI_BIN" ]] || fail "Open WebUI installed, but its executable was not found. Try restarting Terminal and rerunning ./install.sh."

mkdir -p "$APP_SUPPORT_DIR/data"
chmod 700 "$APP_SUPPORT_DIR"
if [[ ! -s "$APP_SUPPORT_DIR/webui_secret_key" ]]; then
  if ! command -v openssl >/dev/null 2>&1; then fail "openssl is required to create a local session secret."; fi
  openssl rand -hex 32 > "$APP_SUPPORT_DIR/webui_secret_key"
  chmod 600 "$APP_SUPPORT_DIR/webui_secret_key"
fi

chmod +x "$ROOT_DIR/start.command" "$ROOT_DIR/stop.command" "$ROOT_DIR/scripts"/*.sh

DESKTOP_DIR="$HOME/Desktop"
mkdir -p "$DESKTOP_DIR"
DESKTOP_LAUNCHER="$DESKTOP_DIR/Carrot LLM.command"
printf '#!/bin/bash\nexec %q/start.command\n' "$ROOT_DIR" > "$DESKTOP_LAUNCHER"
chmod +x "$DESKTOP_LAUNCHER"

say "Setup complete."
printf 'Project: %s\nData:    %s\nLauncher: %s\n' "$ROOT_DIR" "$APP_SUPPORT_DIR/data" "$DESKTOP_LAUNCHER"

if curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  ollama_ready=true
else
  ollama_ready=false
  open -a Ollama >/dev/null 2>&1 || true
  for _ in $(seq 1 30); do
    if curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then ollama_ready=true; break; fi
    sleep 2
  done
fi

if [[ "$ollama_ready" == true ]]; then
  if ! ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx 'qwen3:1.7b'; then
    printf '\nDownload starter model qwen3:1.7b now? This requires an internet connection and several GB of free disk may be prudent. [Y/n] '
    read -r answer || answer="n"
    if [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]]; then
      ollama pull qwen3:1.7b
    else
      say "Skipped model download. Run: ollama pull qwen3:1.7b"
    fi
  else
    say "Starter model qwen3:1.7b is already installed."
  fi
else
  say "Ollama is not responding yet. Open the Ollama app, then run: ollama pull qwen3:1.7b"
fi

say "Double-click 'Carrot LLM.command' on the Desktop to launch the chat."
