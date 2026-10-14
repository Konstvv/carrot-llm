# Backup and move to another computer

Open WebUI stores its database, uploaded files, and knowledge collections in `~/Library/Application Support/Carrot LLM/data/`. The matching `webui_secret_key` preserves session signing across a restore. Backups therefore contain private data and must be stored securely.

## Create a backup

Stop Carrot first, then run this from the project folder:

```bash
./stop.command
./scripts/backup.sh
```

The archive is written to `~/Library/Application Support/Carrot LLM/backups/` with owner-only permissions. Copy it to a secure location before replacing or repairing this Mac. The backup script refuses to run while the local web interface is responding.

## Restore on a new Mac

1. Install Ollama and Carrot on the new Mac with `./install.sh`, then stop Carrot if it started.
2. Copy the backup archive to the new Mac.
3. In Finder, double-click the archive to extract it, or extract it in Terminal. Copy its `data/` directory and `webui_secret_key` into `~/Library/Application Support/Carrot LLM/`, replacing the empty data directory and key created by setup.
4. Ensure the Application Support directory is private (`chmod 700 "$HOME/Library/Application Support/Carrot LLM"`) and the key is private (`chmod 600 "$HOME/Library/Application Support/Carrot LLM/webui_secret_key"`).
5. Start Carrot and confirm that conversations and documents are present.
6. Download the Ollama models again on the new machine. Model weights are managed separately by Ollama and are not in the backup.

Do not run two Open WebUI instances against the same copied database. Keep the original backup until the restored instance has been checked.

## Later: use a home server for inference

Keep Open WebUI and its data on the Mac initially, and point its Ollama provider at the server's Ollama API only after secure private-network access is configured. The Ollama API does not provide user authentication by itself. Do not expose it directly to the public internet; use a VPN or an authenticated, encrypted reverse proxy. The router configuration is a planning stub and does not yet change where requests go.
