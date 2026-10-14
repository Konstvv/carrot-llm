# Architecture and design decisions

## Phase 1: local first

- **Ollama** owns model downloads and inference at `127.0.0.1:11434`.
- **Open WebUI** provides chat, conversation history, and its built-in document/RAG features at `127.0.0.1:8080`.
- **Carrot scripts** start/check services and keep Open WebUI data in macOS Application Support, outside the Git working tree.
- No Docker daemon is required in this initial macOS setup. Open WebUI is installed as an isolated tool using `uv` and Python 3.11.

## Why no custom UI or router yet?

The first risk to reduce is whether the chosen model and Open WebUI run comfortably on the target MacBook Neo. Keeping the first milestone small gives us a known-good baseline. A custom routing API should be introduced only after a direct Ollama/Open WebUI setup works reliably.

## Future routing layer

The planned Carrot Router will expose an OpenAI-compatible API on loopback, likely `127.0.0.1:8000/v1`. Open WebUI can then connect to it as a provider. Initial routing should be transparent and deterministic (for example: default model, explicit document/RAG context, then a larger model for detected complex requests). It must:

- report which model was selected;
- fall back to the default model if a configured model is missing;
- cap concurrent model requests on the 8 GB device;
- never silently forward prompts or documents to a cloud provider;
- keep router health and logs visible to the user.

## Later home server

Keep the Ollama base URL as configuration rather than hard-coding the local device throughout the code. Later, the router/UI can point at the home server's Ollama endpoint. Before moving, back up Open WebUI's data directory and verify restore on the new host. Do not expose the Ollama API directly to the public internet.
