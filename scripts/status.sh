#!/bin/bash
set -u
APP_SUPPORT_DIR="$HOME/Library/Application Support/Carrot LLM"
printf 'Carrot LLM status\n'
if curl -fsS --max-time 2 http://127.0.0.1:8080/health >/dev/null 2>&1; then
  printf 'Open WebUI: ready at http://127.0.0.1:8080\n'
else
  printf 'Open WebUI: not responding on port 8080\n'
fi
if curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  printf 'Ollama: responding at http://127.0.0.1:11434\n'
else
  printf 'Ollama: not responding\n'
fi
if [[ -f "$APP_SUPPORT_DIR/open-webui.log" ]]; then
  printf 'Log: %s/open-webui.log\n' "$APP_SUPPORT_DIR"
fi
