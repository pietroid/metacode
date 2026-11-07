---
name: metacode-app
description: Change the Metacode app (models, state, UI, actions, relations, tests, sub-apps) inside metacode/. Use for any feature, fix or tweak to the app itself, not the engine. Fastest loop - edit metacode/ then run tool/check.sh. Never run the app.
---

# Change the app

**First**, record the starting point for the cost report (see the end of this file): run `date +%s`, and call the `session_cost` tool if it's available (`mcp__usage-bars__session_cost`).

**Only edit `metacode/`** (never `metacode/generated/`). Then run:

```sh
tool/check.sh
```

It validates every app, regenerates, type-checks and runs every app's `test/`. Repeat until it prints `OK`. Do not launch the app, and do not touch `lib/`, `tool/` or `packages/`. If the change needs a new widget, use the `metacode-add-widget` skill. If it needs engine work, use `metacode-engine`.

## Files

An app is a folder; `metacode/` is the root app. **Sub-apps** live in `apps/<name>/` with the same layout (recursive) and are shown with the `app: <name>` widget. Each app has its own state, actions and relations, and can't see its parent's (or vice versa). Work inside the one app the change is about: a change to the food example only touches `apps/food/`.

| Path (inside an app) | Holds |
|---|---|
| `app.yaml` | `name`, `description`. |
| `models/models.yaml` | Types. `string`, `boolean`, `number`, `datetime`, `list(x)`, `x?`, enums as a list. The reserved `state:` model types the state. |
| `state/state.yaml` | `state:` values. They must match the `state` model. Add a value here for every new state field. |
| `ui/ui.yaml` | `widgets:` map of id to widget. The entry is navigation's `initial` route (else `homePage`). A sub-app embedded in a page uses a plain `homePage` (a column, not a scaffold). |
| `navigation/navigation.yaml` | Routes: `name: widgetId` (page), `{bottomSheet: id}`, `{dialog: id}`. Opened with `core.navigator.push(Routes.name)`. Optional. |
| `style/style.yaml` | Design tokens: colors (light/dark), fonts, icon weight, type scale, radius, spacing. The root spells out the full template; restyle here, not in ui/. Sub-apps omit it and inherit the theme. |
| `actions/*.dart` | `Future<void> name(State state, [void Function(StateDelta) emit], [Core core], [int index], [String/bool value]) async`. Change state only with `emit(StateDelta(field: ...))`. |
| `relations/*.dart` | `T name(State state, [int index])` returns a value for the UI. |
| `test/actions_test.dart`, `test/relations_test.dart` | Tests via `app.<fn>(...)`, from `test/fixtures.dart`. Actions are async: `(await app.addTask(s)).tasks`. `app.emitted`/`app.navigation`/`app.requests` record the last action; `app.api = (method, url, body) => ApiResponse(...)` fakes HTTP. Add one per new action or relation. |
| `apps/<name>/` | Sub-apps. |

Every `.yaml` in a folder is merged, so split a folder when a file grows (root: `ui/hero.yaml`, `ui/examples.yaml`, `ui/waitlist.yaml`...). Ids, model names and state fields must not repeat across files. Read only the file you need.

Import `../generated/state.dart` for `State`, `StateDelta`, the model classes (`Task`...), enums and `copyWith`, and `../generated/core.dart` for `Core` (`core.api.get/post`, `core.navigator.push/pop`), `ApiResponse` and `Routes`. Images go in the root `metacode/assets/` for every app.

### New sub-app

1. `apps/<name>/` with `app.yaml`, `models/models.yaml` (with `state:`), `state/state.yaml`, `ui/ui.yaml` (`homePage`), `actions/actions.dart`, `relations/relations.dart`, `test/fixtures.dart` (`final app = TestApp();` from `../generated/test_app.dart`) and tests. Copy `apps/plants/` as a template.
2. Show it from the parent's ui/: `app: <name>`.
3. `tool/check.sh` (no pubspec change needed).

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

- Tabs inside one screen: keep the current page in state (an enum), show it with `match`, change it with actions.
- Things that open on top (detail page, bottom sheet, dialog): a route in navigation.yaml, opened by an action with `core.navigator.push(Routes.x)`, closed with `core.navigator.pop()`.
- Network: `final r = await core.api.get(url); if (r.ok) ... r.json`. Emit a loading status first, then the result or a failure. Status 0 means a network error.
- `index` reaches relations and actions inside `listView`/`gridView` items. Inputs pass `value`.
- Look: widgets are already styled. Use token color names (`ink2`, `success`, `danger`, `accent`) instead of hex, `bodySmall` for metadata, and type size (not boldness or color) for hierarchy. Don't nest cards; list rows separated by `divider` read better than a card per row. See Style in REFERENCE.md.

## dart_eval rules (the tool reports violations)

- Type closure params: `where((Task t) => t.done)`.
- Don't interpolate ints from `DateTime` getters. Use `toIso8601String()`.
- `dart:` imports only. Private helpers need unique names across files.

If the catalog lacks something, use the `metacode-add-widget` skill. Don't fake it in the app.

## Example: add a "priority" to tasks

1. `models/models.yaml`: `task: {..., priority: number}`.
2. `state/state.yaml`: add `priority: 0` to each task.
3. `actions/actions.dart`: `Future<void> bumpPriority(State state, void Function(StateDelta) emit, int index) async { state.tasks[index].priority += 1; emit(StateDelta(tasks: state.tasks)); }`.
4. `ui/ui.yaml`: `trailing: {iconButton: {icon: add, onPressed: bumpPriority}}`.
5. `test/actions_test.dart`: `expect((await app.bumpPriority(sample(), 0)).tasks[0].priority, 1);`.
6. `tool/check.sh`.

## Report cost (always, at the end)

After `tool/check.sh` prints `OK`, run `date +%s` and call `session_cost` again. End your reply with one line:

```
⏱ 2m 14s · $0.42 · 85.3k tokens · 3 check runs
```

- Time: the difference between the two `date +%s` readings.
- Cost and tokens: the difference between the two `session_cost` readings (total tokens). If the tool isn't available, write `cost n/a`.
- Check runs: how many times you ran `tool/check.sh`.
