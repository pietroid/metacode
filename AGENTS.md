# Metacode

A Flutter engine that runs an app described in YAML plus small Dart functions.

## Map

| Path | What |
|---|---|
| `examples/my_own_app/` | **The root app** (the my-own.app website). An app is a folder: `app.yaml`, `app/actions/`, `app/models/` (+ `sample.dart` for tests), `app/views/` (`navigation.yaml`, `pages/`, `components/`, `style/` + `style/images/`, `values/`, `labels/en.yaml`), and **modules** in `modules/<name>/` with the same layout (recursive). Every `.yaml` file contains exactly one top-level key, named after the file; files are not merged. Tests live in the file they test: a `main()` below the action or value. Naming: files `this_case.dart`/`this_case.yaml`, keys and functions `thisCase`, pages and components `ThisCase`. |
| `examples/my_own_app/modules/` | Modules: `food`, `music`, `work`, `plants` (the carousel examples), embedded with the `module: <name>` widget. Each has its own state, actions and values. |
| `*/.generated/` | Output of the tool, per app. Never edit. `INDEX.md` is the app's map (every page, component, action, value, state field: purpose, uses, used by); **read it before opening app files**. The root's `.generated/bundle.json` is the whole tree; the engine loads only that. |
| `tool/metacode.dart` | CLI: validate + generate. `tool/reference.dart`: writes REFERENCE.md. `tool/src/`: `project.dart` (app folders, merging, recursion), `models.dart` (app/models/state), `functions.dart` (action/value signatures, via analyzer), `ui.dart` (app/views/ widgets), `codegen.dart` (generated files), `index.dart` (INDEX.md) |
| `packages/app_ui/` | **UI catalog.** `lib/spec.dart` (pure-Dart contract the tool validates against), `lib/style.dart` (style tokens + the default Metacode style, pure Dart), `lib/src/theme.dart` (tokens -> ThemeData + `MetacodeTokens`), `lib/src/widgets/*.dart` (one builder each), `lib/src/registry.dart`, `lib/src/parsers.dart`, `fonts/` (bundled type) |
| `lib/engine/` | Runtime: `app.dart` (MetacodeApp), `app_runtime.dart` (one running app: state, program, renderer, host; creates modules), `program.dart` (loads bytecode, calls actions/values), `host.dart` + `host_plugin.dart` (bridge from interpreted code to the engine), `core_host.dart` (emit, http, Navigator), `navigation.dart` (navigation/, pure Dart), `ui_renderer.dart` (resolves nodes, resolves labels, caches values per state, implements `Ui`; each page/component is a scope that `context.select`s only the values it read), `state_bloc.dart` (state + persistence, per app), `project_config.dart` (loads `bundle.json`) |
| `test/` | Engine tests (renders the bundle and taps) |

## Flow

```
per app (root and each modules/<name>/):
app.yaml (state:) ──────────┐
app/models/ ────────────────┤
app/actions/ ───────────────┤
app/views/values/ ──────────┼─ tool/metacode.dart ─> .generated/state.dart     (typed State, StateDelta, models, enums)
app/views/labels/ ──────────┤   (validate all)       .generated/core.dart      (Core: api + navigator, Routes)
app/views/pages|components ─┤                        .generated/labels.dart    (Labels: app/views/labels/ as getters)
app/views/navigation.yaml ──┤                        .generated/main.dart      (JSON bridge, engine-facing)
app/views/style/ (+images/) ┤                        .generated/program.evc    (dart_eval bytecode)
main() in each file (tests, host)                    .generated/test_app.dart  (typed test harness, fake host)
root only:                                           .generated/bundle.json    (the whole tree: ui, state, routes, labels, style, bytecode)

Engine: state (Map) ─> value / label ─> app_ui widget ─> tap ─> action(state, emit, core)
        ─> emit(StateDelta) ─> merged into that app's state ─> .state/state.yaml
        core.api / core.navigator ─> hostCall ─> CoreHost (http, Navigator: pages, sheets, dialogs)
        `module: food` ─> AppRuntime for modules/food (own StateBloc, program, renderer); its changes rebuild only it
```

- Actions: `Future<void> name(State state, [void Function(StateDelta) emit], [Core core], [Labels labels], [int index], [T value])`; params after State match by name. State changes only via `emit`.
- Values (formerly relations/bindings): `T name(State state, [Labels labels], [int index])`, return a primitive, model, enum or List of those. Internally (spec `PropKind.binding`, `Ui.binding`, manifest `bindings`) the old name stays.
- Labels: `app/views/labels/<language>.yaml` (`en:` then `key: text`), pure strings. Widgets reference labels and values the same way, by key (`text: joinTitle`); values join labels with state.
- User code runs in dart_eval. The tool bundles each app's files into one library before compiling; apps don't share code.

## Commands (never launch the app to verify)

- `tool/check.sh`: app loop (generate, then one `flutter test` of `.generated/all_test.dart`, which imports every user file, so it type-checks them all, and runs the tests in each action and value file's `main()`). No separate analyze step. About 10s.
- `tool/check_engine.sh`: everything (generate, analyze all, all tests).
- `dart run tool/metacode.dart watch`: regenerates on every save (~200ms warm). The running app reloads `bundle.json` on **hot reload** (`_LiveApp` in `lib/main.dart` -> `MetacodeApp` with a new config -> `AppRuntime.reload`, state kept), so no hot restart is needed. It is the VS Code pre-launch task.

## Reference

`.claude/skills/metacode-app/REFERENCE.md`: files, types, signatures, a one-line table of all widgets; per-widget props in `reference/widgets/<name>.md`, style/icons/colors in `reference/style.md`. Generated by `dart run tool/reference.dart`.

## Skills

`.claude/skills/`: `metacode-app` (change the app), `metacode-add-widget`, `metacode-engine`.
