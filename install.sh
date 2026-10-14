#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Carrot LLM"

say() { printf '\n🥕 %s\n' "$*"; }
fail() { printf '\nCarrot setup: %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || fail "This setup script currently supports macOS only."
command -v curl >/dev/null 2>&1 || fail "curl was not found. Install Command Line Tools for macOS and retry."
command -v unzip >/dev/null 2>&1 || fail "unzip was not found. Install Command Line Tools for macOS and retry."

OLLAMA_APP=""
for candidate in "$HOME/Applications/Ollama.app" "/Applications/Ollama.app"; do
  if [[ -d "$candidate" ]]; then OLLAMA_APP="$candidate"; break; fi
done

OLLAMA_BIN="$(command -v ollama || true)"
if [[ -z "$OLLAMA_BIN" && -n "$OLLAMA_APP" && -x "$OLLAMA_APP/Contents/Resources/ollama" ]]; then
  OLLAMA_BIN="$OLLAMA_APP/Contents/Resources/ollama"
fi

if [[ -z "$OLLAMA_BIN" ]]; then
  say "Downloading Ollama from the official macOS distribution..."
  OLLAMA_TEMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$OLLAMA_TEMP_DIR"' EXIT
  curl --fail --location --progress-bar "https://ollama.com/download/Ollama-darwin.zip" -o "$OLLAMA_TEMP_DIR/Ollama-darwin.zip"
  unzip -q "$OLLAMA_TEMP_DIR/Ollama-darwin.zip" -d "$OLLAMA_TEMP_DIR"
  [[ -d "$OLLAMA_TEMP_DIR/Ollama.app" ]] || fail "The Ollama download did not contain Ollama.app."
  mkdir -p "$HOME/Applications"
  OLLAMA_APP="$HOME/Applications/Ollama.app"
  if [[ -e "$OLLAMA_APP" ]]; then
    fail "An incomplete Ollama app already exists at $OLLAMA_APP. Remove or repair it, then rerun setup."
  fi
  ditto "$OLLAMA_TEMP_DIR/Ollama.app" "$OLLAMA_APP"
  OLLAMA_BIN="$OLLAMA_APP/Contents/Resources/ollama"
  rm -rf "$OLLAMA_TEMP_DIR"
  trap - EXIT
fi
[[ -x "$OLLAMA_BIN" ]] || fail "Ollama was installed but its command was not found. See https://ollama.com/download/mac."
if [[ -z "$OLLAMA_APP" ]]; then
  for candidate in "$HOME/Applications/Ollama.app" "/Applications/Ollama.app"; do
    if [[ -d "$candidate" ]]; then OLLAMA_APP="$candidate"; break; fi
  done
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
if command -v swiftc >/dev/null 2>&1; then
  ICON_HELPER="$APP_SUPPORT_DIR/set-desktop-icon"
  if ! swiftc -framework AppKit "$ROOT_DIR/scripts/set-desktop-icon.swift" -o "$ICON_HELPER"; then
    say "Could not build the Finder icon helper. The launcher still works; see README for manual setup."
  elif ! "$ICON_HELPER" "$ROOT_DIR/assets/carrot-cat.png" "$DESKTOP_LAUNCHER"; then
    say "Could not set the Finder icon automatically. The launcher still works; see README for manual setup."
  else
    /usr/bin/SetFile -a CE "$DESKTOP_LAUNCHER" 2>/dev/null || true
    touch "$DESKTOP_LAUNCHER"
  fi
else
  say "Swift compiler was not found, so the desktop shortcut keeps the default icon."
fi

say "Setup complete."
printf 'Project: %s\nData:    %s\nLauncher: %s\n' "$ROOT_DIR" "$APP_SUPPORT_DIR/data" "$DESKTOP_LAUNCHER"

if curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  ollama_ready=true
else
  ollama_ready=false
  if [[ -n "$OLLAMA_APP" ]]; then
    open -a "$OLLAMA_APP" >/dev/null 2>&1 || true
  else
    open -a Ollama >/dev/null 2>&1 || true
  fi
  for _ in $(seq 1 30); do
    if curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then ollama_ready=true; break; fi
    sleep 2
  done
fi

if [[ "$ollama_ready" == true ]]; then
  REQUIRED_MODELS=("qwen3:1.7b" "lakomoor/vikhr-llama-3.2-1b-instruct:1b")
  for model in "${REQUIRED_MODELS[@]}"; do
    if "$OLLAMA_BIN" list 2>/dev/null | awk 'NR>1 {print $1}' | grep -Fxq "$model"; then
      say "Required model $model is already installed."
    else
      say "Downloading required model $model..."
      "$OLLAMA_BIN" pull "$model"
    fi
  done
else
  fail "Ollama did not start, so required models were not downloaded. Open Ollama and rerun ./install.sh."
fi

say "Double-click 'Carrot LLM.command' on the Desktop to launch the chat."
