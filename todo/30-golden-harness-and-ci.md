# 30 — Golden-File Harness and CI

## Goal

Prove the engine still generates correct code without needing a Flutter SDK, and
run that proof on every commit.

## Why

The only end-to-end verification that exists is a human running
`go run ../../engine/cmd/metacode run` in `examples/counter_app` and then
`flutter test`. That requires a Flutter SDK, network access for `pub get`, and
several minutes. In practice it means the pipeline is verified rarely.

Unit tests exist for most packages, but the seams between them are untested:
`cli/run.go` has no test, and it is the only thing that knows the stage order.
Nothing catches a change that makes two stages disagree.

There is no `.github/`, so nothing runs on push. The `Makefile` has `run`,
`test`, `build`, and no `fmt`, `vet`, or `lint` target.

## Scope

### 1. Golden files

Store the expected generated tree per example:

```
engine/testdata/golden/counter_app/
├── lib/
│   ├── app.dart
│   ├── main.dart
│   ├── pages/home_page.dart
│   ├── stores/counter_cubit.dart
│   ├── stores/counter_state.dart
│   ├── widgets/counter_button.dart
│   └── wrappers/*.dart
├── test/*.dart
└── pubspec.yaml
```

The test generates into `t.TempDir()` and compares the whole tree. `-update`
regenerates the goldens:

```go
var update = flag.Bool("update", false, "rewrite golden files")
```

This is only meaningful once milestone 22 lands. It is also the cheapest possible
enforcement of milestone 22: a golden test is a determinism test that runs on
every change.

### 2. Dart analysis without Flutter

Generated Dart can be syntax-checked with `dart analyze`, which is smaller than a
full Flutter SDK, and skipped with `testing.Short()` or a build tag when absent.
That catches the class of bug the current `validateDartSyntax` cannot:

```go
func balancedBraces(code string) bool {
    // ...
    } else if r == '\\' && i+1 < len(code) {
        _ = code[i+1]    // does not skip the escaped character
    }
```

The escape branch evaluates an index expression and discards it, so `'\''`
terminates the string early and the brace count goes wrong. The same function
counts `{`, `(`, and `[` into a single depth counter, so `(]` is "balanced".
Delete it in favour of a real parser rather than fixing it.

### 3. Flutter tests as an opt-in tier

Keep the `flutter test` run behind a build tag so it can run nightly rather than
per-commit.

### 4. CI

`.github/workflows/ci.yml`:

- `gofmt -l .` must be empty
- `go vet ./...`
- `go test ./... -count=2` (`-count=2` catches map-order flakes)
- `go build ./...`
- optional job with the Flutter SDK running the counter app end to end

Add `make fmt`, `make vet`, `make lint`, `make golden` so the same commands work
locally.

## Acceptance criteria

1. `go test ./...` verifies the counter app tree with no Flutter SDK installed.
2. `go test ./... -update` regenerates goldens and produces a reviewable diff.
3. CI runs on push and pull request and is green.
4. `-count=2` passes, proving the determinism fix held.
5. A deliberate regression in any generator fails the golden test.

## Files to create

```
engine/internal/e2e/golden_test.go
engine/testdata/golden/counter_app/...
.github/workflows/ci.yml
engine/Makefile                          # fmt, vet, lint, golden targets
```

## Layering notes

Land alongside milestone 22. Determinism without a golden test decays; a golden
test without determinism cannot pass.
