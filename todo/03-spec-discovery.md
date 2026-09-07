# 03 — Spec Discovery

## Goal

Teach the `run` command to locate the `metacode/` folder inside the current Flutter project and identify the spec files it needs to read.

## Scope

- Start from the current working directory and walk upward until a directory containing a `metacode/` folder is found.
- Validate that the discovered `metacode/` folder contains at least:
  - `project.yaml`
  - `data.yaml`
  - `ui.yaml`
  - `behaviors.yaml`
- Return a structured `SpecPaths` value with absolute paths.
- No parsing of YAML content yet.

## Acceptance criteria

1. Running `metacode run` from `examples/counter_app/` discovers `examples/counter_app/metacode/` and its four spec files.
2. Running from a directory with no `metacode/` folder returns a clear error.
3. Running from a directory with a `metacode/` folder but missing `ui.yaml` returns a clear error naming the missing file.
4. Unit tests cover discovery success and failure cases.

## Files to create/modify

```
engine/internal/spec/
├── discovery.go       # Discovery logic
└── discovery_test.go  # Tests
```

Modify `engine/internal/cli/run.go` to call discovery and log the discovered paths.

### Suggested API

```go
package spec

type Paths struct {
    Root       string // absolute path to project root
    Metacode   string // absolute path to metacode folder
    Project    string
    Data       string
    UI         string
    Behaviors  string
}

func Discover(startDir string) (Paths, error)
```

## Layering notes

- Depends on: bootstrap, logger.
- Enables: YAML parsing milestone.
- Keep discovery decoupled from parsing so tests can use temporary directories without invoking YAML logic.
