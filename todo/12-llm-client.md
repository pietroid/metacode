# 12 — LLM Client

## Goal

Implement a thin HTTP client that sends prompts to an OpenAI-compatible chat completions endpoint and returns the generated text.

## Scope

- Read configuration from environment variables:
  - `METACODE_LLM_BASE_URL` (required)
  - `METACODE_LLM_API_KEY` (required)
  - `METACODE_LLM_MODEL` (optional, default `opencode-go/kimi-k2.7-code`)
- Support chat completions endpoint `POST /chat/completions`.
- Support non-streaming JSON response for simplicity.
- Provide a `Complete(ctx, prompt) (string, error)` method.
- Add request/response logging at debug level.
- No retry, no streaming, no tool calling yet.

## Acceptance criteria

1. Unit test with a mock HTTP server verifies the client sends the correct JSON body and Authorization header.
2. Unit test verifies the client extracts the assistant message content.
3. Missing `METACODE_LLM_BASE_URL` or `METACODE_LLM_API_KEY` produces a clear error at runtime.
4. The client can be instantiated and injected into the wrapper generator.

## Files to create/modify

```
engine/internal/llm/
├── client.go       # LLM client
├── config.go       # Env config
└── client_test.go  # Mock server tests
```

### Suggested API

```go
package llm

type Client interface {
    Complete(ctx context.Context, prompt string) (string, error)
}

type Config struct {
    BaseURL string
    APIKey  string
    Model   string
}

func ConfigFromEnv() (Config, error)
func NewClient(cfg Config) Client
```

### Request shape

```json
{
  "model": "opencode-go/kimi-k2.7-code",
  "messages": [
    {"role": "user", "content": "<prompt>"}
  ]
}
```

## Layering notes

- Depends on: logger.
- Enables: AI wrapper generator and TDD fix loop.
- The client is abstracted behind an interface so later milestones can swap in streaming, caching, or retry without touching callers.
- Keep prompt construction outside this package; this package only transports prompts and returns strings.
