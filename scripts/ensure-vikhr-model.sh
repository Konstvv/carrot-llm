#!/bin/bash
set -euo pipefail

OLLAMA_BIN="${1:?Usage: ensure-vikhr-model.sh OLLAMA_BIN PROJECT_DIR}"
PROJECT_DIR="${2:?Usage: ensure-vikhr-model.sh OLLAMA_BIN PROJECT_DIR}"
BASE_MODEL="lakomoor/vikhr-llama-3.2-1b-instruct:1b"
CARROT_MODEL="carrot-vikhr:16k"
MODEL_FILE="$PROJECT_DIR/config/vikhr-16k.Modelfile"

say() { printf '\n🥕 %s\n' "$*"; }
fail() { printf '\nCarrot LLM: %s\n' "$*" >&2; exit 1; }

[[ -x "$OLLAMA_BIN" ]] || fail "Ollama executable was not found: $OLLAMA_BIN"
[[ -f "$MODEL_FILE" ]] || fail "Vikhr model configuration was not found: $MODEL_FILE"

if "$OLLAMA_BIN" list 2>/dev/null | awk 'NR>1 {print $1}' | grep -Fxq "$CARROT_MODEL"; then
  exit 0
fi

if ! "$OLLAMA_BIN" list 2>/dev/null | awk 'NR>1 {print $1}' | grep -Fxq "$BASE_MODEL"; then
  fail "The base Russian model is missing. Run install.sh to download it, then start Carrot again."
fi

say "Building $CARROT_MODEL with a 16,384-token context window..."
"$OLLAMA_BIN" create "$CARROT_MODEL" -f "$MODEL_FILE"
say "$CARROT_MODEL is ready. Select this model for Russian chats."
