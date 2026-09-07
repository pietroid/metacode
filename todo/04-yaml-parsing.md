# 04 — YAML Parsing

## Goal

Parse the four spec YAML files discovered in the previous milestone into raw, generic Go structures that preserve the full YAML shape.

## Scope

- Parse `project.yaml`, `data.yaml`, `ui.yaml`, and `behaviors.yaml`.
- Use a YAML library such as `gopkg.in/yaml.v3`.
- Return a `RawSpecs` struct where each field is a generic `map[string]any` or `[]any` depending on the file.
- Validate basic YAML syntax and surface line/column errors in a friendly way.
- No semantic validation yet (e.g. unknown UI symbols are accepted here).

## Acceptance criteria

1. The counter app specs parse into raw structures without data loss.
2. Invalid YAML (e.g. bad indentation) produces a clear error with file path and line context.
3. Each raw structure can be pretty-printed for debugging.
4. Unit tests parse sample specs and assert on key nested keys.

## Files to create/modify

```
engine/internal/spec/
├── parser.go       # YAML parsing logic
└── parser_test.go  # Tests
```

Modify `engine/internal/cli/run.go` to parse specs after discovery and log the raw structure count.

### Suggested API

```go
package spec

type RawSpecs struct {
    Project   map[string]any
    Data      map[string]any
    UI        map[string]any
    Behaviors map[string]any
}

func Parse(paths Paths) (RawSpecs, error)
```

- `map[string]any` works for `project.yaml`, `data.yaml`, and `ui.yaml`.
- `behaviors.yaml` may contain grouped lists; still store as `map[string]any` where each scenario value can be a nested map or a list.

## Layering notes

- Depends on: spec discovery.
- Enables: internal representation construction.
- Keep this layer syntax-only. Semantic errors belong in the IR construction and validation milestones.
