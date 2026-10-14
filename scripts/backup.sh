#!/bin/bash
set -euo pipefail

APP_SUPPORT_DIR="$HOME/Library/Application Support/Carrot LLM"
DATA_DIR="$APP_SUPPORT_DIR/data"
SECRET_FILE="$APP_SUPPORT_DIR/webui_secret_key"
BACKUP_DIR="$APP_SUPPORT_DIR/backups"
STAMP="$(date '+%Y%m%d-%H%M%S')"
BACKUP_FILE="$BACKUP_DIR/carrot-$STAMP.tar.gz"

if curl -fsS --max-time 2 http://127.0.0.1:8080/health >/dev/null 2>&1; then
  printf 'Stop Carrot LLM before backing up so its database is not changing. Run ./stop.command and retry.\n' >&2
  exit 1
fi
if [[ ! -d "$DATA_DIR" || ! -s "$SECRET_FILE" ]]; then
  printf 'Carrot data was not found. Run ./install.sh and start Carrot at least once.\n' >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
chmod 700 "$APP_SUPPORT_DIR" "$BACKUP_DIR"
tar -czf "$BACKUP_FILE" -C "$APP_SUPPORT_DIR" data webui_secret_key
chmod 600 "$BACKUP_FILE"
printf 'Backup created: %s\n' "$BACKUP_FILE"
printf 'This archive contains private conversations, documents, and the local session secret. Store it securely.\n'
