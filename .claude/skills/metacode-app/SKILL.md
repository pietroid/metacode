---
name: metacode-app
description: Change the Metacode app (models, state, UI, actions, bindings, tests) inside metacode/. Use for any feature, fix or tweak to the app itself, not the engine. Fastest loop - edit metacode/ then run tool/check.sh. Never run the app.
---

# Change the app

**First**, record the starting point for the cost report (see the end of this file): run `date +%s`, and call the `session_cost` tool if it's available (`mcp__usage-bars__session_cost`).

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

## Reference

**[REFERENCE.md](REFERENCE.md)** is the single spec: types, signatures, every widget with its props, icons, colors and text variants. It is generated from the catalog, so it is always current. Look things up there instead of reading `packages/`.

Most common patterns:

```yaml
homePage:
  scaffold:
    appBar: {title: "Notes"}
    body: {match: {value: currentPage, cases: {list: noteList, edit: noteEditor}}}
    bottomBar: {navigationBar: {destinations: [{icon: list, label: Notes}, {icon: settings, label: Settings}], selected: pageIndex, onSelected: goToPage}}
noteList:
  listView: {data: notes, itemBuilder: noteTile, empty: "No notes"}
noteTile:
  card: {onTap: openNote, child: {text: {value: noteTitle, style: {variant: titleMedium}}}}
```

- Multiple screens: keep the current page in state (an enum), show it with `match`, change it with actions.
- `index` reaches bindings and actions inside `listView`/`gridView` items. Inputs pass `value`.

## dart_eval rules (the tool reports violations)

- Type closure params: `where((Task t) => t.done)`.
- Don't interpolate ints from `DateTime` getters. Use `toIso8601String()`.
- `dart:` imports only. Private helpers need unique names across files.

If the catalog lacks something, use the `metacode-add-widget` skill. Don't fake it in the app.

## Example: add a "priority" to tasks

1. `models.yaml`: `task: {..., priority: number}`.
2. `state.yaml`: add `priority: 0` to each task.
3. `actions/actions.dart`: `State bumpPriority(State state, int index) {...}`.
4. `ui.yaml`: `trailing: {iconButton: {icon: add, onPressed: bumpPriority}}`.
5. `test/actions_test.dart`: `expect(app.bumpPriority(sample(), 0).tasks[0].priority, 1);`.
6. `tool/check.sh`.

## Report cost (always, at the end)

After `tool/check.sh` prints `OK`, run `date +%s` and call `session_cost` again. End your reply with one line:

```
⏱ 2m 14s · $0.42 · 85.3k tokens · 3 check runs
```

- Time: the difference between the two `date +%s` readings.
- Cost and tokens: the difference between the two `session_cost` readings (total tokens). If the tool isn't available, write `cost n/a`.
- Check runs: how many times you ran `tool/check.sh`.
