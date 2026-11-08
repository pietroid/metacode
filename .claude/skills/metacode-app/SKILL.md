---
name: metacode-app
description: Change the Metacode app (models, state, view, actions, values, labels, tests, modules) inside examples/my_own_app/. Use for any feature, fix or tweak to the app itself, not the engine. Fastest loop - edit examples/my_own_app/ then run tool/check.sh. Never run the app.
---

# Change the app

**First**, record the starting point for the cost report (see the end of this file): run `date +%s`, and call the `session_cost` tool if it's available (`mcp__usage-bars__session_cost`).

**Only edit `examples/my_own_app/`** (never `examples/my_own_app/.generated/`). Then run:

```sh
tool/check.sh
```

It validates every app, regenerates, type-checks and runs every app's tests (the `main()` in each action and value file). Repeat until it prints `OK`. Do not launch the app, and do not touch `lib/`, `tool/` or `packages/`. Build new UI as components out of the catalog's widgets (see Components first, below); reach for the `metacode-add-widget` skill only when no composition can do it. If it needs engine work, use `metacode-engine`.

## Find what to change: read the index first

Before opening any app file, read the index of the app the change is about: `examples/my_own_app/.generated/INDEX.md` (root) or `examples/my_own_app/modules/<name>/.generated/INDEX.md`. If it is missing, run `dart run tool/metacode.dart` first. It lists the state (with who writes and reads each field), models, routes, and every page, component, action and value with its one-line purpose, what it uses and what uses it. From it:

- Pick the exact files to edit. Names map to files (`Hero` -> `app/views/components/hero.yaml`, `joinWaitlist` -> `app/actions/join_waitlist.dart`). Open only those. Don't `ls`, `grep` or browse the app.
- Find what a change ripples into: a state field's `w:`/`r:` lists, and each item's `used by`.
- Widgets: the table in REFERENCE.md (Widgets) gives each widget's purpose and props in one line. Open `reference/widgets/<name>.md` only when you need prop kinds or notes; `reference/style.md` only for style tokens, icon, color or text variant names.

Every app file starts with a header comment: the first line is `name: what it is` (`# Hero: the top section...`, `// joinWaitlist: Validates...`). The index is built from these. Keep them true when you change a file, and write one for each new file.

## Files

An app is a folder; `examples/my_own_app/` is the root app. **Modules** live in `modules/<name>/` with the same layout (recursive) and are shown with the `module: <name>` widget. Each app has its own state, actions and values, and can't see its parent's (or vice versa). Work inside the one app the change is about: a change to the food example only touches `modules/food/`.

| Path (inside an app) | Holds |
|---|---|
| `app.yaml` | `name`, `description`, `state:` initial values. |
| `app/actions/*.dart` | `Future<void> name(State state, [void Function(StateDelta) emit], [Core core], [Labels labels], [int index], [String/bool value]) async`. Change state only with `emit(StateDelta(field: ...))`. One public action per file; private helpers must have unique names across files. |
| `app/models/*.yaml` | Types, one parent per file. `string`, `boolean`, `number`, `datetime`, `list(x)`, `x?`, enums as a list. The reserved `state` model lives in `app/models/state.yaml`. |
| `app/views/navigation.yaml` | `initial: name` and `routes: {name: PageId}` (page), `{bottomSheet: PageId}`, `{dialog: PageId}`. Opened with `core.navigator.push(Routes.name)`. Optional; without it the app is `MainPage`. |
| `app/views/pages/*.yaml` | What routes open: `MainPage:`, sheets, dialogs. |
| `app/views/components/*.yaml` | One widget per file (`Hero:`, `TaskList:`, ...). |
| `app/views/style/*.yaml` | Design tokens, one group per file: `theme`, `fonts`, `icons`, `colors`, `radius`, `spacing`, `sizes`, `typography`. The root spells out the full template; restyle here, not in pages/components. Modules omit it and inherit the theme. |
| `app/views/style/images/` | Image assets for the app. |
| `app/views/values/*.dart` | `T name(State state, [Labels labels], [int index])` computes a value for the UI. One public value per file; private helpers must have unique names across files. |
| `app/views/labels/en.yaml` | All the app's text: `en:` then `key: text`. Pure strings, no placeholders: text that depends on state is a value joining labels (`'$n ${labels.peopleOnTheList}'`). |
| Tests | In the same file as the action or value, below it: `void main() { test('...', () async { ... }); }` with `import 'package:flutter_test/flutter_test.dart';` and the sample (`import '../models/sample.dart';` from `app/actions/`, `import '../../models/sample.dart';` from `app/views/values/`). The tool ignores `main()` and leaves it out of the compiled program; keep test helpers inside it. |
| `app/models/sample.dart` | Sample states: `final app = TestApp();` (runs actions and values through the compiled program) and `State sample(...)`. |
| `modules/<name>/` | Modules. |
| `.state/` | Runtime state, persisted by the engine. Never commit. |

Every `.yaml` file contains exactly one top-level key, named after the file. **Naming:** files are `this_case.dart` / `this_case.yaml`; keys, functions, models and labels are `thisCase`; pages and components are `ThisCase` (`app/views/components/task_list.yaml` holds `TaskList:`, `app/actions/bump_priority.dart` holds `bumpPriority`). Names must not repeat across files. Read only the file you need.

Import the generated files relative to your file (`../../.generated/` from `app/actions/` and `app/models/`, `../../../.generated/` from `app/views/values/`): `state.dart` for `State`, `StateDelta`, model classes, enums and `copyWith`, `core.dart` for `Core` (`core.api.get/post`, `core.navigator.push/pop`), `ApiResponse` and `Routes`, and `labels.dart` for `Labels`. Images go in `examples/my_own_app/app/views/style/images/` for every app.

### New module

1. `modules/<name>/` with `app.yaml` (include `state:`), `app/models/state.yaml` and other models, `app/actions/*.dart`, `app/views/pages/main_page.yaml`, `app/views/components/*.yaml`, `app/views/values/*.dart`, `app/views/labels/en.yaml`, `app/models/sample.dart` (`final app = TestApp();` from `../../.generated/test_app.dart`), and tests in a `main()` in each action and value file. Copy `modules/plants/` as a template.
2. Show it from a parent component: `module: <name>`.
3. `tool/check.sh` (no pubspec change needed).

## Reference

**[REFERENCE.md](REFERENCE.md)** is the spec: files, types, signatures, views and a one-line table of every widget. Details are split out so you read only what you need: [reference/widgets/](reference/widgets/)`<name>.md` (one widget's props) and [reference/style.md](reference/style.md) (style tokens, icons, colors, text variants). All generated from the catalog, so always current. Never read `lib/`, `tool/` or `packages/`: the app needs only these files and the index.

Most common patterns:

`app/views/pages/main_page.yaml`:
```yaml
MainPage:
  scaffold:
    appBar: {title: notes}
    body: {match: {value: currentPage, cases: {list: NoteList, edit: NoteEditor}}}
    bottomBar: {navigationBar: {destinations: [{icon: list, label: notes}, {icon: settings, label: settings}], selected: pageIndex, onSelected: goToPage}}
```

`app/views/components/note_list.yaml`:
```yaml
NoteList:
  listView: {data: noteList, itemBuilder: NoteTile, empty: noNotes}
```

`app/views/components/note_tile.yaml`:
```yaml
NoteTile:
  card: {onTap: openNote, child: {text: {value: noteTitle, style: {variant: titleMedium}}}}
```

`app/views/labels/en.yaml`:
```yaml
en:
  notes: Notes
  settings: Settings
  noNotes: No notes yet
```

- Tabs inside one screen: keep the current page in state (an enum), show it with `match`, change it with actions.
- Things that open on top (detail page, bottom sheet, dialog): a route in app/views/navigation.yaml (its page in app/views/pages/), opened by an action with `core.navigator.push(Routes.x)`, closed with `core.navigator.pop()`.
- Network: `final r = await core.api.get(url); if (r.ok) ... r.json`. Emit a loading status first, then the result or a failure. Status 0 means a network error.
- `index` reaches values and actions inside `listView`/`gridView` items. Inputs pass `value`.
- Look: widgets are already styled. Use token color names (`ink2`, `success`, `danger`, `accent`) instead of hex, `bodySmall` for metadata, and type size (not boldness or color) for hierarchy. Don't nest cards; list rows separated by `divider` read better than a card per row. See Style in REFERENCE.md.

## dart_eval rules (the tool reports violations)

- Type closure params: `where((Task t) => t.done)`.
- Don't interpolate ints from `DateTime` getters. Use `toIso8601String()`.
- `dart:` imports only. Private helpers need unique names across files.

## Components first

Anything that can be drawn by composing catalog widgets is a **component** in `app/views/components/`, not a new widget: a phone frame (sized `container` + `column` + `scroll`), a status bar, a badge, a stat tile, a step indicator. Before deciding something is missing, check REFERENCE.md's widget table: `container` (size, color, radius, clip, maxWidth), `stack`, `row`/`column`/`expanded`, `scroll`, `sizedBox`, `text`, `icon`, `image` cover most visuals. A hex color is fine for a physical object (a phone's bezel).

Use `metacode-add-widget` only for a missing **capability**, something no arrangement of existing widgets can do: a new Material input, a gesture, an animation, a shadow, scaling, a new icon or prop. Even then, add the smallest primitive (e.g. a `shadow` prop on `container`) and keep the composition in the app.

## Example: add a "priority" to tasks

1. `app/models/task.yaml`: `task: {..., priority: number}`.
2. `app/models/state.yaml`: add `priority: number` to the `state:` model.
3. `app.yaml`: add `priority: 0` to each task in `state:`.
4. `app/actions/bump_priority.dart`: `Future<void> bumpPriority(State state, void Function(StateDelta) emit, int index) async { state.tasks[index].priority += 1; emit(StateDelta(tasks: state.tasks)); }`.
5. `app/views/components/task_list.yaml`: `trailing: {iconButton: {icon: add, tooltip: raisePriority, onPressed: bumpPriority}}`, and `raisePriority: Raise priority` in `app/views/labels/en.yaml`.
6. Below it, in `app/actions/bump_priority.dart`: `void main() { test('bumpPriority', () async { expect((await app.bumpPriority(sample(), 0)).tasks[0].priority, 1); }); }`.
7. `tool/check.sh`.

## Report cost (always, at the end)

After `tool/check.sh` prints `OK`, run `date +%s` and call `session_cost` again. End your reply with one line:

```
⏱ 2m 14s · $0.42 · 85.3k tokens · 3 check runs
```

- Time: the difference between the two `date +%s` readings.
- Cost and tokens: the difference between the two `session_cost` readings (total tokens). If the tool isn't available, write `cost n/a`.
- Check runs: how many times you ran `tool/check.sh`.
