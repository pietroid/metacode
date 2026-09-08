# 28 — Diagnostics with Source Positions

## Goal

Every message the engine prints about a spec points at the line that caused it,
and the engine distinguishes what it ignored from what it rejected.

## Why

The README promises that "any errors in any stage will be reported". What a user
gets today:

```
ui.yaml > homePage: prop "foo" is not allowed for scaffold
```

No line, no column, no source excerpt. To find it you search the file by hand.
`spec.Parse` decodes into `map[string]any`, which discards position information
at the first step, so no downstream stage can do better.

Worse is the warning/error split. `cli/run.go` runs three validators and logs
every result with `logger.Warnf`:

```go
for _, err := range project.Validate(app.Project) {
    logger.Warnf("project rule: %s", err)
}
```

`project.Validate` returns "missing name" as its only rule. A project with no
name is not a warning; it produces a Dart package called `unnamed_app` and the
run continues. Everything the validators find is demoted to a warning, so the
validators cannot fail a build even when they should. They also return `[]error`
for things that are not errors, which is why they end up logged as warnings.

Two smaller symptoms of the same root cause:

- `builder.go` `unknownKeys` warns on unknown top-level keys, which is the one
  case where a typo is likely and a hard failure would be kinder.
- `cli/run.go` does `defer func() { reporter.End("Metacode run", nil) }()`, so
  the final line always claims success, including on the paths that return an
  error.

## Scope

### 1. Keep positions

Decode into `yaml.Node`. Every node carries `Line` and `Column`. Attach a
position to each IR object as it is built:

```go
type Pos struct {
    File   string
    Line   int
    Column int
}
```

This is the same change milestone 22 wants for ordering, so do them together.

### 2. A diagnostic type

```go
type Severity int

const (
    SeverityError Severity = iota   // stop before generating
    SeverityWarning                 // generate, but say so
)

type Diagnostic struct {
    Severity Severity
    Pos      Pos
    Rule     string   // "ui/unknown-prop"
    Message  string
    Hint     string   // "did you mean \"body\"?"
}
```

Validators return `[]Diagnostic`, not `[]error`. The CLI collects them, prints
them grouped by file with a source excerpt, and exits non-zero if any is an
error.

### 3. Classify the existing rules

| Rule | Today | Should be |
|---|---|---|
| missing project name | warning | error |
| store missing value type | warning | error |
| unknown top-level key | warning | error (typo) |
| unknown prop on catalog widget | warning | warning (may be forwarded) |
| undefined symbol in assertion | error (returned) | error, with position |

### 4. Fix the reporter

`reporter.End("Metacode run", nil)` must report the actual outcome. Capture the
error in a named return and pass it.

## Acceptance criteria

1. A prop typo in `ui.yaml` prints file, line, column, and the offending line.
2. A missing project name fails the run with exit code 1.
3. A failing run does not print a success line.
4. Warnings and errors are visually distinct and counted in a summary.
5. Tests assert positions for at least one diagnostic of each severity.

## Files to modify

```
engine/internal/core/spec/parser.go
engine/internal/core/diag/diagnostic.go      # new
engine/internal/core/ir/*                    # carry Pos
engine/internal/modules/{project,data,ui}/rules.go
engine/internal/core/log/reporter.go
engine/internal/cli/run.go
```
