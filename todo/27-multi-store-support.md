# 27 — Multi-Store Support

## Goal

Generate correct code for an app with more than one store.

## Why

`data.yaml` accepts any number of stores and `ir.Build` reads all of them. Every
consumer then takes the first one:

| File | Code | Effect with two stores |
|---|---|---|
| `modules/tests/builder.go` `buildTestCase` | `store := app.Stores[0]` | Every test imports and asserts against the wrong Cubit |
| `generators/flutter/wrapper_deterministic.go` | `store := app.Stores[0]` | Wrappers read one store regardless of the behavior |
| `generators/flutter/prompt_builder.go` | loops all stores | Correct, and inconsistent with the above |
| `generators/flutter/wrapper.go` `updateAppDart` | `if len(app.Stores) == 1` | With two stores, no `BlocProvider` at all, so the app crashes at runtime |

Because `Stores` order comes from a map walk (see milestone 22), `Stores[0]` is
not even stably the same store between runs. The two defects compound: the app
picks an arbitrary store, and picks a different arbitrary store next time.

Nothing warns. A two-store app generates, compiles, and is wrong.

## Scope

### 1. Resolve the store per scenario

The scenario already names its store. `counterStore.value should be 1` resolves
to `counterStore`. Thread that through instead of reaching for `Stores[0]`:

```go
func storeForScenario(app *ir.IR, s ir.BehaviorScenario) (ir.Store, error)
```

Look at `given.Target`, then `then.Target`, then `when`. If a scenario touches
two stores, both belong in the generated test, so the return type should
probably be a set, not a single store.

### 2. Provide every store

`updateAppDart` should emit `MultiBlocProvider` with one `BlocProvider` per
store, and drop the `len(app.Stores) == 1` guard. While there: `updateAppDart`
edits `app.dart` with `strings.Replace` and a regex against previously generated
text. Generating `app.dart` from a template with the store list as data is less
code and cannot half-apply.

### 3. Test scaffolding for N stores

`TestCase` has one `CubitClass`/`StateClass` pair. Make it a slice, and generate
the `MultiBlocProvider` in `widget_test.dart.tmpl`.

### 4. Fail loudly

If a scenario references a store that does not exist, that is an error today
(the resolver catches undefined symbols). If a generator cannot determine which
store a scenario means, that should be an error too, not a fallback.

## Acceptance criteria

1. No `Stores[0]` in the engine.
2. A two-store spec generates a `MultiBlocProvider` covering both.
3. A scenario asserting on the second store generates a test importing the second
   store's Cubit.
4. `examples/task_app` (three stores) gets past generation.
5. A test with two stores in the fixture, asserting the correct Cubit is used for
   each scenario.

## Files to modify

```
engine/internal/modules/tests/{builder.go,model.go}
engine/internal/modules/tests/codegen/flutter/templates/widget_test.dart.tmpl
engine/internal/generators/flutter/{wrapper.go,wrapper_deterministic.go}
engine/internal/modules/project/codegen/flutter/templates/    # app.dart as a template
```

## Layering notes

Do this after milestone 22. Ordering and store selection are the same bug wearing
two hats: output that depends on something other than the specs.
