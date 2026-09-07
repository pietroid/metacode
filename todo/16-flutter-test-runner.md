# 16 — Flutter Test Runner

## Goal

Run `flutter test` in the generated project and capture the pass/fail result and output.

## Scope

- Execute `flutter test` as a subprocess in the Flutter project root.
- Capture stdout, stderr, and exit code.
- Parse the output to identify failing tests and their error messages.
- Report progress through the reporter.
- On failure, return a structured `TestResult` containing:
  - Overall pass/fail status.
  - List of failing tests with file, name, and raw output.

## Acceptance criteria

1. Running `metacode run` invokes `flutter test` after code generation.
2. The runner captures and logs the test output.
3. All tests passing returns success.
4. A failing test returns a structured result with the test name and failure text.
5. Unit tests use a fake command executor to verify behavior without requiring Flutter.

## Files to create/modify

```
engine/internal/runner/
├── test_runner.go        # Subprocess execution and parsing
├── result.go             # TestResult types
└── test_runner_test.go
```

### Suggested API

```go
package runner

type TestResult struct {
    Success bool
    Output  string
    Failures []Failure
}

type Failure struct {
    File    string
    Name    string
    Message string
}

type TestRunner struct {
    ProjectDir string
    Executor   func(name string, arg ...string) *exec.Cmd
}

func (r *TestRunner) Run(ctx context.Context) (TestResult, error)
```

## Layering notes

- Depends on: logger, reporter.
- Enables: TDD fix loop.
- The runner should not try to install Flutter; it assumes the SDK is available.
- Parsing test output can be simple string scanning for the MVP. A future milestone can parse machine-readable formats if needed.
