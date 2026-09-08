# task_app — target example (does not generate yet)

`counter_app` is the example the engine was built against. `task_app` is the
example the engine should be built against next. It is a spec-only fixture: there
is no `lib/`, no `test/`, and `metacode run` will not produce a working app today.

It exists so that every capability gap is written down as YAML someone can run,
rather than as prose in a design doc.

## What the app does

A task list with three stores: the tasks themselves (persisted locally), the
active filter, and the text currently typed into the input field. You type a
title, press add, the task appears; you tick a checkbox, it moves out of the
"open" filter; you kill the app and the tasks are still there.

Nothing exotic. It is roughly the smallest app that is not a counter.

## Why this one

Each spec construct below is chosen because it breaks a specific assumption the
engine currently makes. The list doubles as the acceptance criteria for the next
engine tier.

| Spec construct | Assumption it breaks | Where |
|---|---|---|
| `models.yaml` with `task`, `priority`, `filter` | Discovery requires exactly four files and has no `models.yaml` path | `core/spec/discovery.go` |
| `value: list(task)` | `DartTypeFor` maps anything unrecognized to `dynamic`; state classes hold one scalar `value` field | `modules/data/rules.go`, `data/codegen/flutter/templates` |
| Three stores | Test builder, deterministic wrappers, and the prompt builder all take `app.Stores[0]`; `app.dart` only provides a Cubit when `len(Stores) == 1` | `modules/tests/builder.go`, `generators/flutter/*` |
| `taskStore.value.length`, `taskStore.value[0].done` | The resolver rejects any dot chain deeper than 2 and has no index syntax | `core/ir/resolver.go` |
| `given: taskStore.value is [{title: "Buy milk", done: false}]` | Assertion values are opaque strings parsed with `strconv`; there is no structured literal | `core/ir/behavior_parser.go` |
| `strategy: local` | Only `ephemeral` generates; the strategy field is parsed and ignored | `data/codegen/flutter/store.go` |
| `filterStore: value: filter` (enum-typed store) | No enum branch in the type mapper | `modules/data/rules.go` |
| `onChanged`, `onTap` events | `renderAction` handles `onPressed` and silently returns an empty action for everything else, producing a test that asserts without acting | `modules/tests/builder.go` |
| `listView` with `itemCount` / `itemBuilder` | Widgets are rendered as a closed tree with `final String` parameters; there is no per-item widget scope | `ui/codegen/flutter/widget.go` |
| `taskCount` (number), `taskDone` (bool) | Every UI variable is generated as `final String` | `ui/codegen/flutter/widget.go` |
| `body: column: [..., expanded: taskList]` | The deterministic wrapper hard-codes the path `body → center → column` and renders an empty page for anything else | `generators/flutter/wrapper_deterministic.go` |
| `when: app.restart` | There is no namespace for app lifecycle events, only stores and widgets | `core/ir/resolver.go` |
| Nested groups under `filtering` | Groups mostly flatten already, but sibling group paths share a backing array (`append(path, key)` aliasing) | `core/ir/builder.go` |

## Suggested order

The gaps are not equally deep. A workable sequence:

1. Multi-store support and typed UI variables. Nothing else is safe while
   `Stores[0]` is load-bearing.
2. Models and enums, which unlock `list(task)` and the enum-valued store.
3. Path expressions (`.length`, `[0].field`) in the behavior grammar.
4. Structured `given` values.
5. Generic event binding, replacing the `onPressed` special case.
6. Collection UI (`itemBuilder` scope).
7. The `local` strategy.

Steps 1–5 are engine-core work. Steps 6–7 are Flutter module work and can be
done by a different person once the IR carries the information.

## Running it

```bash
cd examples/task_app
go run ../../engine/cmd/metacode run
```

Expect this to fail. When it stops failing, the milestone is done.
