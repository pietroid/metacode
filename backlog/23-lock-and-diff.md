# 23 — Lock and Diff Optimization

## Goal

Implement the lock/diff mechanism so Metacode only regenerates code for specs that have changed between runs.

## Scope

- Before each run, store a snapshot of the current specs in `metacode/.lock/`.
- On the next run, compare the new specs with the locked versions.
- Detect additions, removals, and modifications at the scenario/widget/store level.
- Only invalidate and regenerate files affected by changed specs.
- If a deterministic file is unchanged, keep it.
- If an AI-generated file depends on a changed spec, re-run the LLM for that file.
- Preserve lock files after successful generation and test passes.

## Acceptance criteria

1. First run creates `metacode/.lock/` with copies of all specs.
2. Second run with no spec changes skips all generation and only runs tests.
3. Changing one behavior scenario regenerates only the affected wrapper and tests.
4. Removing a widget removes its generated file.
5. Lock format is stable and human-readable (YAML copies).
6. Unit tests verify diff detection and selective invalidation.

## Files to create/modify

```
engine/internal/lock/
├── lock.go          # Lock reading/writing
├── diff.go          # Diff detection
└── lock_test.go

engine/internal/cli/run.go  # integrate lock check before generation
```

### Suggested API

```go
package lock

type Lock struct {
    Dir string
}

func (l *Lock) Load() (map[string]string, error) // file path -> content hash
func (l *Lock) Save(specs spec.Paths) error

type Diff struct {
    Added    []string
    Removed  []string
    Modified []string
}

func Compare(old, new map[string]string) Diff
```

## Layering notes

- Depends on: spec discovery, all generators.
- Enables: fast incremental regeneration on large projects.
- The user explicitly deferred this feature for the MVP, so it is the last milestone.
- Lock granularity can start at the file level and later move to individual symbols/scenarios.
- Consider adding a `--force` flag to ignore the lock and regenerate everything.
