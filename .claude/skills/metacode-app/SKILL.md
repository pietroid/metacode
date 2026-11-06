---
name: metacode-app
description: Change the Metacode app (models, state, UI, actions, bindings, tests) inside metacode/. Use for any feature, fix or tweak to the app itself, not the engine. Fastest loop - edit metacode/ then run tool/check.sh. Never run the app.
---

# Change the app

**Only edit `metacode/`** (never `metacode/generated/`). Then run:

```sh
tool/check.sh
```

It validates everything, regenerates, type-checks and runs `metacode/test`. Repeat until it prints `OK`. Do not launch the app, and do not touch `lib/`, `tool/` or `packages/`. If the change needs a new widget, use the `metacode-add-widget` skill. If it needs engine work, use `metacode-engine`.

## Files

| File | Holds |
|---|---|
| `models.yaml` | Types. `string`, `boolean`, `number`, `datetime`, `list(x)`, `x?`, enums as a list. The reserved `state:` model types state.yaml. |
| `state.yaml` | `state:` values. They must match the `state` model. Add a value here for every new state field. |
| `ui.yaml` | `widgets:` map of id to widget. `homePage` is the entry point. |
| `actions/*.dart` | `State name(State state, [int index], [String/bool value])` returns the next state. |
| `bindings/*.dart` | `T name(State state, [int index])` returns a value for the UI. |
| `test/actions_test.dart`, `test/bindings_test.dart` | Tests via `app.<fn>(...)`, from `test/fixtures.dart`. Add one per new action or binding. |

Import `../generated/state.dart` for `State`, the model classes (`Task`...), enums and `copyWith`.

## ui.yaml

The widget catalog is `packages/app_ui/lib/spec.dart`: every widget, its props and their kinds. Read it before writing UI.

- A string node is a widget id, else a binding, else literal text.
- `action` props (`onPressed`, `onChanged`...) must name an action. `binding` props (`data`, `selected`, `condition`, checkbox `value`) must name a binding.
- Inside `listView.itemBuilder`, bindings and actions get `index`. Inputs pass `value`.
- Widget ids must not collide with binding or action names.

```yaml
widgets:
  homePage:
    scaffold:
      appBar: {title: "Notes"}
      body:
        listView: {data: noteList, itemBuilder: noteTile, empty: "Nothing yet"}
  noteTile:
    listTile: {title: noteTitle, onTap: openNote}
```

## dart_eval rules (the tool reports violations)

- Type closure params: `where((Task t) => t.done)`.
- Don't interpolate ints from `DateTime` getters. Use `toIso8601String()`.
- `dart:` imports only. Private helpers need unique names across files.

## Example: add a "priority" to tasks

1. `models.yaml`: `task: {..., priority: number}`.
2. `state.yaml`: add `priority: 0` to each task.
3. `actions/actions.dart`: `State bumpPriority(State state, int index) {...}`.
4. `ui.yaml`: `trailing: {iconButton: {icon: add, onPressed: bumpPriority}}`.
5. `test/actions_test.dart`: `expect(app.bumpPriority(sample(), 0).tasks[0].priority, 1);`.
6. `tool/check.sh`.
