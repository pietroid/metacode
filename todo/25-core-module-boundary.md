# 25 — Enforce the Core/Module Boundary

## Goal

Make the layering in `specification/engine/metacode_engine.md` true in the code:
core knows nothing about Flutter, the UI catalog, or any concrete target.

## Why

The specification says:

> 1. Core part: The common part that encompasses all that is listed above.
> 2. Modules: Everything related to how actually code is generated, the rules for
>    each kind of spec, the libraries of ui components, etc. should live inside
>    its specific modules so we can have a kind of "plug and play".

The dependency graph currently runs in both directions:

- `core/ir/builder.go` and `core/ir/resolver.go` import `modules/ui/catalog`.
  The core IR builder cannot classify a widget without asking a module.
- `modules/shared/naming.go` imports `core/ir`, so `shared` is not shared, it is
  a second core.
- `modules/tests/builder.go` imports `planner`, and `planner` imports
  `modules/data` and `modules/shared`. Peer modules import each other.
- Adding a second target means editing `cli/run.go` and
  `modules/codegen/flutter/generate.go`, which is the opposite of plug-and-play.

There is also a smaller tell in `core/ir/builder.go`: `catalog.New()` is called
inside `classifyKind`, `isVariableReference`, `defaultContentProp`, and
`extractSingleKind`, so a fresh catalog with ~30 map inserts is allocated for
every symbol examined. That is what a missing dependency looks like when nobody
passed it in.

## Scope

### 1. Invert the catalog dependency

Define the vocabulary interface in core and let the module satisfy it:

```go
package ir

// Vocabulary is the target-supplied set of known component symbols.
type Vocabulary interface {
    IsKnown(name string) bool
    DefaultProp(name string) (string, bool)
}

func Build(raw spec.RawSpecs, vocab Vocabulary) (IR, error)
```

`catalog.Catalog` already has `IsKnown` and `Find`; adapting it is small. Pass it
once through `Build` and `Resolve` rather than constructing it per call.

### 2. Split `shared`

`shared` currently mixes two things. Move them apart:

- Pure string helpers (`PascalCase`, `SnakeCase`, `Indent`, `UniqueStrings`,
  `IsVariableIdentifier`) have no domain dependency: `core/text` or similar.
- IR-aware helpers (`FirstPageName`, `FindComponent`) belong in core alongside
  the types they walk.
- Dart-specific helpers (`DartStringLiteral`, `DartPackageName`) belong in the
  Flutter module and nowhere else. `DartStringLiteral` is currently reachable
  from the planner.

### 3. Introduce a target registry

```go
package target

type Target interface {
    Name() string
    Vocabulary() ir.Vocabulary
    Generate(app *ir.IR, tasks []planner.Task, outDir string) error
    TestCommand() (name string, args []string)
}

func Register(t Target)
func Lookup(name string) (Target, bool)
```

`cli/run.go` then resolves the target by name from `project.yaml` (which
`project_spec.md` already anticipates: "TBD in the future about languages") and
never imports a Flutter package. `TestCommand` also removes the hard-coded
`exec.Command("flutter", "test")` in `runner/test_runner.go`.

### 4. Guard the boundary

Add a test that fails if core imports a module. `go list -deps` is enough:

```go
func TestCoreDoesNotImportModules(t *testing.T) { /* go list -deps ./internal/core/... */ }
```

A rule nobody can accidentally break is worth more than a paragraph in a doc.

## Acceptance criteria

1. `go list -deps ./internal/core/...` contains no `internal/modules/...` entry.
2. `catalog.New()` is called once per run.
3. `cli/run.go` contains no Flutter import.
4. The test command comes from the target, not from a literal in the runner.
5. The counter app still generates identically.

## Files to modify

```
engine/internal/core/ir/{builder.go,resolver.go}
engine/internal/modules/shared/*             # split
engine/internal/modules/ui/catalog/catalog.go
engine/internal/target/registry.go           # new
engine/internal/cli/run.go
engine/internal/runner/test_runner.go
```

## Layering notes

Do this before milestone 20 (models) and 21 (store strategies). Both add module
code, and both get harder if module code keeps leaking upward.
