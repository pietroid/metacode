# 22 — Reproducible Output

> **Status: done and verified.** Every map walk listed below is ordered via
> `engine/internal/core/order`, and the group-path aliasing bug is fixed.
> `make check` is green, `metacode run` on `examples/counter_app` produces
> byte-identical output across four consecutive runs, and disabling the sort in
> `order.Keys` makes `TestGenerationIsReproducible` fail on run 2, so the test
> has teeth.

## Goal

Running `metacode run` twice on unchanged specs produces byte-identical files.

## Why

Go randomizes map iteration order on every execution. The engine walks
`map[string]any` from YAML, and `map[string]bool` internally, at several points
where the walk order reaches the generated Dart. The generated
`examples/counter_app/lib/pages/home_page.dart` already shows the symptom: its
`Scaffold` arguments are emitted `body:` before `appBar:`, which is not the order
in `ui.yaml` and not a canonical order either. It is whatever the map handed
back that run.

This is not cosmetic. Milestone 23 (lock and diff) regenerates only what changed,
detected by comparing files. If unchanged specs produce different bytes, the diff
is noise and the optimization cannot work. It also makes every generated file
churn in git for no reason, and makes bug reports irreproducible.

## Known sources

| Location | Map walked | Reaches output as |
|---|---|---|
| `core/ir/builder.go` `buildData` | `stores`, `models`, `enums` | slice order in `IR`, and file emission order |
| `core/ir/builder.go` `buildUI` | `widgets` | `IR.UI` order, and `shared.FirstPageName` fallback |
| `core/ir/builder.go` `buildBehaviors` | scenario groups | `IR.Behaviors` order, test emission order |
| `core/ir/builder.go` `extractSingleKind` | the widget's own mapping | which key wins when there is more than one |
| `data/codegen/flutter/store.go` `buildMethods` | `map[string]bool` of actions | order of methods inside the generated Cubit |
| `generators/flutter/wrapper_deterministic.go` `renderWrapperCatalogWidget` | `comp.Props` | order of named arguments in generated Dart |
| `generators/flutter/wrapper_deterministic.go` `GenerateDeterministicWrappers` | `byWidget` | order files are written |
| `generators/flutter/wrapper_deterministic.go` `generatePageWrapper` | `childWrappers` | order of import lines |
| `ui/codegen/flutter/widget.go` | `comp.Props` | order of named arguments |

`planner.Plan` already sorts its wrapper map. That is the pattern to copy.

## Scope

- Sort every map key before iterating, anywhere the result is observable.
- Preferred: stop losing order in the first place. `gopkg.in/yaml.v3` exposes
  `yaml.Node`, which preserves document order. Decoding into `yaml.Node` instead
  of `map[string]any` makes spec order the canonical order, which is what a spec
  author expects, and is a prerequisite for milestone 28 (source positions).
  Sorting is the tactical fix; `yaml.Node` is the right one.
- Prop emission needs a defined order regardless: derive it from the catalog
  entry (`DefaultProp` first, then `AllowedProps` order) so generated Dart reads
  the same way every time.
- `unknownKeys` in `builder.go` also builds warnings from a map walk; sort those
  so warning output is stable.

## Acceptance criteria

1. `engine/internal/planner/pipeline_determinism_test.go` passes. It generates
   the pipeline 25 times into temp directories and compares a hash manifest of
   every produced file. Done.
2. Regenerating `examples/counter_app` produces no git diff. Done.
3. Generated Dart argument order matches catalog order, not map order. Done: default content prop first, then catalog order, then any remainder sorted by name.
4. `go test ./...` passes with `-count=5`. Done, via `make check`.

## Files to modify

```
engine/internal/core/ir/builder.go
engine/internal/modules/data/codegen/flutter/store.go
engine/internal/modules/ui/codegen/flutter/widget.go
engine/internal/generators/flutter/wrapper_deterministic.go
engine/internal/core/spec/parser.go          # if moving to yaml.Node
```

## Related bug found while reading

`appendBehaviorScenarios` does `newPath := append(path, key)` and then passes
`newPath` to sibling recursive calls, each of which appends again. When `path`
has spare capacity, siblings write into the same backing array and corrupt each
other's group path. It does not bite at depth 2 (the counter app) but will at
depth 3, which the grouping example in `behaviors_spec.md` uses. Fix with an
explicit copy:

```go
newPath := append(append([]string(nil), path...), key)
```

Fold this into the same change; it is the same class of defect (output depending
on something other than the input).
