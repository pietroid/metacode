# 01 — Go Project Bootstrap

## Goal

Create the Go module and CLI skeleton for Metacode. The only command implemented is `metacode run`, which for now simply prints a confirmation that it discovered the command.

## Scope

- Initialize `engine/go.mod`.
- Create `cmd/metacode/main.go` as the entry point.
- Create `internal/cli/run.go` that registers the `run` command.
- Add a minimal `Makefile` or task helper for `go run ./cmd/metacode run`.
- No spec parsing, no generation yet.

## Acceptance criteria

1. `go run ./cmd/metacode run` prints a message like `metacode run invoked` and exits with code 0.
2. `go run ./cmd/metacode --help` shows usage including the `run` subcommand.
3. `go test ./...` passes (only trivial tests expected).

## Files to create/modify

```
engine/
├── go.mod
├── Makefile
├── cmd/
│   └── metacode/
│       └── main.go
└── internal/
    └── cli/
        └── run.go
```

### Suggested content

- `engine/go.mod`
  - Module name: `github.com/pietroid/metacode/engine` (adjust if needed).
  - Go version: `1.22`.

- `engine/cmd/metacode/main.go`
  - Calls `cli.Execute()` and exits with the returned error code.

- `engine/internal/cli/run.go`
  - Uses the standard `flag` package or `cobra` (recommend `flag` for minimal scope).
  - Registers `run` subcommand.
  - Prints confirmation message.

## Layering notes

- This milestone establishes the build boundary. Everything later lives inside `engine/`.
- The `run` command will later discover the spec folder and invoke the full pipeline.
- Keep dependencies minimal; avoid pulling in large CLI frameworks until needed.
