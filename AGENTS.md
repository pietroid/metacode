# Metacode

A Flutter engine that runs an app described in YAML plus small Dart functions.

## Map

| Path | What |
|---|---|
| `examples/my_own_app/` | **The root app** (the my-own.app website). An app is a folder: `app.yaml`, `app/actions/`, `app/models/` (+ `sample.dart` for tests), `app/views/` (`navigation.yaml`, `pages/`, `components/`, `style/` + `style/images/`, `values/`, `labels/en.yaml`), and **modules** in `modules/<name>/` with the same layout (recursive). Every `.yaml` file contains exactly one top-level key, named after the file; files are not merged. Tests live in the file they test: a `main()` below the action or value. Naming: files `this_case.dart`/`this_case.yaml`, keys and functions `thisCase`, pages and components `ThisCase`. |
| `examples/my_own_app/modules/` | Modules: `food`, `music`, `work`, `plants` (the carousel examples), embedded with the `module: <name>` widget. Each has its own state, actions and values. |
| `*/.generated/` | Output of the tool, per app. Never edit. `INDEX.md` is the app's map (every page, component, action, value, state field: purpose, uses, used by); **read it before opening app files**. The root's `.generated/bundle.json` is the whole tree; the engine loads only that. |
| `lib/files/` | **Project files**: `ProjectFiles` (the project in memory, by path; `changes` stream), backed by a watched folder (`io_project_files.dart`) or localStorage (`local_storage_project_files.dart`, web). Same folder structure everywhere. |
| `tool/metacode.dart` | CLI: validate + generate (calls `lib/compiler/build.dart` on the folder's files). `tool/reference.dart`: writes REFERENCE.md. `lib/compiler/` (pure Dart, also runs in the app): `build.dart` (validate + generate + compile, outputs in memory), `project.dart` (app folders, merging, recursion), `models.dart` (app/models/state), `functions.dart` (action/value signatures, via analyzer), `ui.dart` (app/views/ widgets), `codegen.dart` (generated files), `index.dart` (INDEX.md) |
| `packages/app_ui/` | **UI catalog.** `lib/spec.dart` (pure-Dart contract the tool validates against), `lib/style.dart` (style tokens + the default Metacode style, pure Dart), `lib/src/theme.dart` (tokens -> ThemeData + `MetacodeTokens`), `lib/src/widgets/*.dart` (one builder each), `lib/src/registry.dart`, `lib/src/parsers.dart`, `fonts/` (bundled type) |
| `lib/engine/` | Runtime: `app.dart` (MetacodeApp), `app_runtime.dart` (one running app: state, program, renderer, host; creates modules), `program.dart` (loads bytecode, calls actions/values), `host.dart` + `host_plugin.dart` (bridge from interpreted code to the engine), `core_host.dart` (emit, http, Navigator), `navigation.dart` (navigation/, pure Dart), `ui_renderer.dart` (resolves nodes, resolves labels, caches values per state, implements `Ui`; each page/component is a scope that `context.select`s only the values it read), `state_bloc.dart` (state, per app) + `state_store.dart` (where it is saved), `live_project.dart` (compiles from `ProjectFiles` on a background isolate, again on every change), `project_config.dart` (loads `bundle.json`) |
| `test/` | Engine tests, on the engine's own small app `test/fixture_app/` (one of each feature), never on `examples/`: a change to the real app never needs an engine test change. `engine_test.dart` compiles the fixture and taps it; `web/` runs the compiler and runtime in Chrome. |

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
        ProjectFiles (folder / localStorage) ─ change ─> LiveProject: build() in the app ─> new bundle ─> AppRuntime.reload (state kept)
        `module: food` ─> AppRuntime for modules/food (own StateBloc, program, renderer); its changes rebuild only it
        `contained: true` ─> its own Navigator: its pages, sheets, dialogs open inside its box
```

- Actions: `Future<void> name(State state, [void Function(StateDelta) emit], [Core core], [Labels labels], [int index], [T value])`; params after State match by name. State changes only via `emit`.
- Values (formerly relations/bindings): `T name(State state, [Labels labels], [int index])`, return a primitive, model, enum or List of those. Internally (spec `PropKind.binding`, `Ui.binding`, manifest `bindings`) the old name stays.
- Labels: `app/views/labels/<language>.yaml` (`en:` then `key: text`; `en.yaml`, `pt_br.yaml`), pure strings. Widgets reference labels and values the same way, by key (`text: joinTitle`); values join labels with state. Locale: Flutter localization (`MaterialApp.supportedLocales` = the root's languages, device locale by default); `core.locale.set` picks one app-wide (`lib/engine/locale.dart`, saved in `.state/locale.yaml`); each app shows its best-matching labels file, passed to user code as `_locale` (`labels.locale`).
- User code runs in dart_eval. The tool bundles each app's files into one library before compiling; apps don't share code.

## Commands (never launch the app to verify)

- `tool/check.sh`: app loop (generate, then one `flutter test` of `.generated/all_test.dart`, which imports every user file, so it type-checks them all, and runs the tests in each action and value file's `main()`, plus `tool/layout_test.dart`: every app (modules as a parent shows them) and every route, from the initial state, at phone, tablet and desktop sizes, failing on overflow or render errors; it knows nothing about the app). No separate analyze step. About 10s.
- `tool/check_engine.sh`: everything (generate the app and `test/fixture_app/`, analyze all, all tests, and `test/web/` in Chrome: the compiler and runtime compiled to JavaScript).
- The running app compiles the project itself: with `--dart-define=METACODE_PROJECT_DIR=<folder>` (desktop) it watches the folder; on web it runs from localStorage, seeded from `.generated/files.json` (reset each launch with `METACODE_RESET_FILES=true`). Every source change (images included) recompiles on a background isolate (~100ms warm, `LiveProject`) and replaces the running version, state kept; no hot reload. The state is saved in the files too (`.state/state.yaml` per app). Without live files it runs the bundled `bundle.json`. VS Code: `metacode (macOS)` and `metacode (web)` in `.vscode/launch.json`.
- `dart run tool/metacode.dart watch`: regenerates `.generated/` on every save, for the IDE and tests.

## Reference

`.claude/skills/metacode-app/REFERENCE.md`: files, types, signatures, a one-line table of all widgets; per-widget props in `reference/widgets/<name>.md`, style/icons/colors in `reference/style.md`. Generated by `dart run tool/reference.dart`.

## Skills

`.claude/skills/`: `metacode-app` (change the app), `metacode-add-widget`, `metacode-engine`.
