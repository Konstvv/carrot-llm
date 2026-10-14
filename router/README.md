# Carrot Router (planned)

This folder reserves a place for a small OpenAI-compatible API that selects a local Ollama model per request. It is deliberately **not enabled yet**: the current UI connects directly to Ollama.

First implementation checklist:

1. Expose `/v1/models` and `/v1/chat/completions` on `127.0.0.1` only.
2. Use Ollama's local API, not an external provider.
3. Support both streaming and non-streaming chat completions.
4. Read rules from `config/router.yaml` and verify selected model exists before routing.
5. Start with explicit/simple rules; add an LLM classifier only if a benchmark shows it improves routing enough to justify its latency and memory use.
6. Add tests for model selection, unknown model fallback, request errors, and streaming.

The future router should not be described as implemented until the API is present, wired into Open WebUI, and covered by tests.
