# 02 — Logger and Progress Reporter

## Goal

Build a centralized logger and a stage-based progress reporter so every later milestone can emit structured, verbose output about what Metacode is doing.

## Scope

- Logger with levels: `Debug`, `Info`, `Warn`, `Error`.
- Progress reporter that prints the current stage (e.g. `Parsing specs...`, `Generating stores...`).
- Support for a `--verbose` / `-v` flag on the `run` command.
- No persistence, no file logging yet.

## Acceptance criteria

1. Running `metacode run -v` enables debug-level output.
2. Logger can be injected into any package and prints messages in a consistent format.
3. Progress reporter prints stage start/end markers.
4. `go test ./...` passes.

## Files to create/modify

```
engine/internal/log/
├── logger.go       # Logger interface and implementation
├── reporter.go     # Stage reporter
└── log_test.go     # Unit tests
```

Also modify `engine/internal/cli/run.go` to wire `-v` into the logger.

### Suggested design

```go
package log

type Logger interface {
    Debugf(format string, args ...any)
    Infof(format string, args ...any)
    Warnf(format string, args ...any)
    Errorf(format string, args ...any)
}

type Stage string

type Reporter interface {
    Start(stage Stage)
    End(stage Stage, err error)
}
```

- The CLI creates one logger and one reporter and passes them down.
- Use `io.Writer` (default `os.Stdout`/`os.Stderr`) so tests can capture output.

## Layering notes

- This milestone is intentionally early so every subsequent generator, parser, and runner can depend on it.
- Later stages should never call `fmt.Println` directly; always use the injected logger/reporter.
- The reporter will eventually report per-spec progress and AI generation steps.
