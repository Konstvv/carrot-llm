#!/bin/bash
set -euo pipefail
LOG_FILE="$HOME/Library/Application Support/Carrot LLM/open-webui.log"
if [[ ! -f "$LOG_FILE" ]]; then
  printf 'No log file yet: %s\n' "$LOG_FILE"
  exit 0
fi
tail -n 100 -f "$LOG_FILE"
