# Carrot LLM 🥕

A local-first AI assistant for macOS. The first milestone combines **Ollama** (local models) and **Open WebUI** (chat interface) with a one-click launcher. The structure is designed to leave room for an automatic model router and a move to a home server later.

> **Current scope:** the starter runs Open WebUI directly against local Ollama. Automatic model routing is documented/configured as a future step; it is not implemented yet.

## What you get

- Local model inference through Ollama.
- A browser-based chat UI through Open WebUI.
- A double-click `Carrot LLM.command` desktop shortcut with a custom cat icon, plus a matching stop script.
- Persistent Open WebUI data outside the repository.
- Local-only web binding (`127.0.0.1`) by default.
- Model and future routing configuration kept in small YAML files.

## First-time setup (Mac)

### 1. Install Carrot and Ollama

In Terminal, from the cloned project directory, run:

```bash
chmod +x install.sh start.command stop.command scripts/*.sh
./install.sh
```

The setup installs Ollama from its official macOS download into `~/Applications/Ollama.app` if it is not already installed. It also installs `uv` if needed, sets up Open WebUI in an isolated Python 3.11 tool environment, creates a persistent secret/data directory under `~/Library/Application Support/Carrot LLM/`, and creates `~/Desktop/Carrot LLM.command` with the cat icon. The installer offers to download the small starter model `qwen3:1.7b`.

### 2. Download a small starter model later (optional)

If you skip the installer's prompt, download `qwen3:1.7b` from the Ollama app. If you installed Ollama through Carrot and want to use Terminal, run:

```bash
"$HOME/Applications/Ollama.app/Contents/Resources/ollama" pull qwen3:1.7b
```

If Ollama was already installed in `/Applications`, run `ollama pull qwen3:1.7b` instead.

The model is only a starting point. Measure performance on the target Mac before adding larger models; memory use depends on quantization, context length, and what else is running.

### 3. Start chatting

Double-click **Carrot LLM.command** on the desktop, or run `./start.command` in Terminal. The first launch may take a little while as Open WebUI initializes. The UI opens at <http://127.0.0.1:8080>.

The first page may ask you to create a local admin account. Use a password you do not reuse elsewhere. The account and chat history are stored locally.

To stop Carrot, double-click `stop.command` or run `./stop.command`. Ollama may continue running in the background because it is managed by its own app.

If setup could not set the icon automatically, open `assets/carrot-cat.png` and `Carrot LLM.command` in Finder's **Get Info** windows. Copy the PNG's small icon in the top-left corner, select the shortcut's small icon, and paste.

## Where data lives

- Open WebUI data and its database: `~/Library/Application Support/Carrot LLM/data/`
- Carrot logs and PID file: `~/Library/Application Support/Carrot LLM/`
- Ollama model weights: managed by Ollama, outside this repository.
- Models/routing preferences: `config/` in this repository.

Do not commit local conversations, documents, embeddings, model weights, API keys, secrets, or database files. See `.gitignore`.

## Architecture

```text
Desktop launcher
      |
      v
Open WebUI (127.0.0.1:8080)  -- local chat, history, document/RAG UI
      |
      v
Ollama (127.0.0.1:11434)     -- local inference and model downloads

Future: optional Carrot router (OpenAI-compatible API) between WebUI and Ollama
Future: Ollama endpoint may move from this Mac to a home server
```

See [docs/architecture.md](docs/architecture.md) and [router/README.md](router/README.md).
For backup and a future move to another Mac or home server, see [docs/backup-and-migration.md](docs/backup-and-migration.md).

## Troubleshooting

- **The app says Ollama is unavailable:** open Ollama and wait for it to finish starting. Try `ollama list` in Terminal.
- **The page does not open:** look at `~/Library/Application Support/Carrot LLM/open-webui.log`.
- **Port 8080 is already in use:** stop the other service or change `PORT` in `start.command` and `stop.command` consistently.
- **The Mac becomes slow:** use a smaller model, lower its context length, and avoid keeping multiple large models loaded at once.
- **The desktop shortcut stops working after moving the repository:** run `./install.sh` again to recreate it with the current path.

## Development roadmap

- [x] Initial macOS launcher and local Open WebUI/Ollama setup
- [ ] Validate startup and model performance on the target MacBook Neo
- [ ] Configure multilingual local RAG and verify source citations
- [ ] Implement explicit `carrot-auto` model routing with a small, transparent rule set
- [ ] Add routing fallbacks and memory-aware model selection
- [x] Document data backup and migration to a home server
- [ ] Consider packaging the launcher as a native macOS app

## Security notes

This is a personal local setup, not a hardened public deployment. The UI binds to loopback by default. Do not expose it to the internet or a shared network without deliberately configuring authentication, firewall rules, and access controls.

## License

No license selected yet. Add one before accepting external contributions or redistributing the project.
