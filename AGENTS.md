# Metacode

A Flutter engine that runs an app described in YAML plus small Dart functions.

## Map

| Path | What |
|---|---|
| `examples/my_own_app/` | **The root app** (the my-own.app website). An app is a folder: `app.yaml`, `app/actions/` (+ `shared/`), `app/models/` (+ `sample.dart` for tests), `app/views/` (`navigation.yaml`, `pages/`, `components/`, `style/` + `style/images/`, `values/` (+ `shared/`), `labels/en.yaml`), `tests/` (selected states for the layout check), and **modules** in `modules/<name>/` with the same layout (recursive). Every `.yaml` file contains exactly one top-level key, named after the file; files are not merged. Tests live in the file they test: a `main()` below the action or value. `shared/` holds helpers, one public function per file named after it. Naming: files `this_case.dart`/`this_case.yaml`, keys and functions `thisCase`, pages and components `ThisCase`. |
| `examples/my_own_app/modules/` | Modules: `food`, `work`, `travel`, `astral` (the carousel examples, shown as `miniApp: <name>`), and `editor` (opened by the root's `openEditor`: pick food, travel or work, whose source the Claude bridge serves (`GET /project?name=`), into `draft` in its `remote` state, running live as a dynamic module; each project's edits and Claude spending kept in `saved`). Each has its own state, actions and values; the parent uses their parts as `<module>.<name>`. |
| `*/.generated/` | Output of the tool, per app. Never edit. `INDEX.md` is the app's map (every page, component, action, value, state field: purpose, uses, used by); **read it before opening app files**. The root's `.generated/bundle.json` is the whole tree; the engine loads only that. |
| `lib/files/` | **Project files**: `ProjectFiles` (the project in memory, by path; `changes` stream), backed by a watched folder (`io_project_files.dart`) or localStorage (`local_storage_project_files.dart`, web). Same folder structure everywhere. |
| `tool/metacode.dart` | CLI: validate + generate (calls `lib/compiler/build.dart` on the folder's files). `tool/reference.dart`: writes REFERENCE.md. `lib/compiler/` (pure Dart, also runs in the app): `build.dart` (validate + generate + compile, outputs in memory), `project.dart` (app folders, merging, recursion), `models.dart` (app/models/state), `functions.dart` (action/value signatures, via analyzer), `ui.dart` (app/views/ widgets), `codegen.dart` (generated files), `index.dart` (INDEX.md) |
| `tool/mcp.dart`, `tool/mcp/`, `tool/mc` | **Agent tools** (MCP server `metacode` in `.mcp.json`, and the same tools as a CLI: `tool/mc <tool> <app>`): `init`, `scaffold` (plan.yaml -> compiling stubs), `briefs` (one work order per agent), `validate` (~1s, per file), `test` (per file), `add_labels`, `check` (tests + layout, grouped by file), `status`. Used by the `metacode-new-app` skill and the `metacode-coder`/`metacode-designer` agents (`.claude/agents/`). |
| `examples/split/`, `examples/cafe/` | Standalone apps built by the `metacode-new-app` pipeline (benchmarks: logic-heavy and screen-heavy); their `plan.yaml` is the plan format by example. `tool/check.sh examples/split`. |
| `packages/app_ui/` | **UI catalog.** `lib/spec.dart` (pure-Dart contract the tool validates against), `lib/style.dart` (style tokens + the default Metacode style, pure Dart), `lib/src/theme.dart` (tokens -> ThemeData + `MetacodeTokens`), `lib/src/widgets/*.dart` (one builder each), `lib/src/registry.dart`, `lib/src/parsers.dart`, `fonts/` (bundled type) |
| `lib/engine/` | Runtime: `app.dart` (MetacodeApp), `app_runtime.dart` (one running app: state, program, renderer, host; creates modules), `program.dart` (loads bytecode, calls actions/values), `host.dart` + `host_plugin.dart` (bridge from interpreted code to the engine), `core_host.dart` (emit, http, Navigator), `navigation.dart` (navigation/, pure Dart), `ui_renderer.dart` (resolves nodes, resolves labels, caches values per state and reruns one only when a field it reads changes, giving it only those fields (manifest `reads`, found through shared helpers by `stateReads` in `lib/compiler/functions.dart`; none when it uses the whole state), implements `Ui`; each page/component is a scope that `context.select`s only the values it read; `@Animated` values ease on that scope's own ticker, never through the state), `state_bloc.dart` (state, per app) + `state_store.dart` (where it is saved), `live_project.dart` (compiles from `ProjectFiles` on a background isolate, again on every change), `project_config.dart` (loads `bundle.json`) |
| `lib/engine/sync/` | Scoped state sync (docs/STATE_ARCHITECTURE.md): `RemoteBackend` + `LocalBackend` (no backend: remote actions run on the device, `system` in `.state/system.yaml`), `HttpBackend` (SSE down by per-field version, the outbox up, remote calls; offline first), `sse.dart`, `user_id.dart` (anonymous id, `.state/user.yaml`) |
| `lib/backend/` | The backend, pure Dart: `backend.dart` (`MetacodeBackend`: compiles the project, global state per app in a data folder: `system`, `shared`, `users/<id>`; one call at a time per app; pushes deltas), `api.dart` (the HTTP API, framework-free), `handler.dart` (shelf, for tests), `io_backend.dart` (folders watched) |
| `server/` | The deployed backend: a Dart Frog project (`routes/`, `main.dart`) on `lib/backend/`. `cd server && flutter pub get && dart_frog dev`; env `METACODE_CODE`, `METACODE_DATA` |
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
        core.navigator ─> hostCall ─> CoreHost (Navigator: pages, sheets, dialogs)
        remote.<name>() ─> backend (or device) runs the remote action; its api ─> CollectHost (http)
        ProjectFiles (folder / localStorage) ─ change ─> LiveProject: build() in the app ─> new bundle ─> AppRuntime.reload (state kept)
        `food.MenuCard` / `food.addItem` / `food.total` (yaml), `core.modules.food.*` (code)
          ─> AppRuntime for modules/food (own StateBloc, program, renderer), created on first use; its changes rebuild only it
        `miniApp: food` ─> that app whole, with its own Navigator: its pages, sheets, dialogs open inside its box
        `miniApp: {project: v}` ─> DynamicModule: v (a metacodeProject in the state) compiled in the app, its own sandboxed AppRuntime, reloaded on every change
```

- State scopes: app.yaml `state:` (and `app/models/state.yaml`, same shape) split into `ephemeral`, `local`, `remote`, `system`, `shared` (`stateScopes` in `lib/compiler/models.dart`); flat = all `local`. Flattened at load (`AppProject.scopes`); the client `State` has no `system`, its `StateDelta` no `shared`/`system` (`clientModels`); `.generated/remote_state.dart` is the backend's (`remoteModels`). `StateBloc` saves `local` in `state.yaml`, `remote`/`shared` in `remote.yaml`/`shared.yaml`, never `ephemeral`.
- Actions: `Future<void> name(State state, [void Function(StateDelta) emit], [Core core], [Remote remote], [Labels labels], [int index], [T value])`; params after State match by name. State changes only via `emit`. Remote actions (`app/actions/remote/`, `Future<void> name(State state, [emit], [Api api], [T value])`; the only code with HTTP: `api`, `.generated/api.dart`, run by `CollectHost`; local actions have no `core.api`) compile into a second program (`.generated/remote_program.evc`, bundle `remote:`); `remote.<name>()` (`.generated/remote.dart`) is the `remote.call` host op and returns `RemoteError?` (dart_eval breaks try/catch around an await).
- Values (formerly relations/bindings): `T name(State state, [Labels labels], [int index])`, return a primitive, model, enum or List of those. `@Animated(ms:, curve:)` on one returning a color or number: the props it feeds ease to each new result (`_Track` in `ui_renderer.dart`). Numbers feed `number` props (`container.opacity`, `text.reveal`). app.yaml `start: <action>` runs when an app starts (`AppRuntime._runStartAction`; not on reload, off in the layout check). Internally (spec `PropKind.binding`, `Ui.binding`, manifest `bindings`) the old name stays.
- Labels: `app/views/labels/<language>.yaml` (`en:` then `key: text`; `en.yaml`, `pt_br.yaml`), pure strings. Widgets reference labels and values the same way, by key (`text: joinTitle`); values join labels with state. Locale: Flutter localization (`MaterialApp.supportedLocales` = the root's languages, device locale by default); `core.locale.set` picks one app-wide (`lib/engine/locale.dart`, saved in `.state/locale.yaml`); each app shows its best-matching labels file, passed to user code as `_locale` (`labels.locale`).
- Modules: `core.modules.reset('food')` starts one of the app's modules over (state back to initial, saved; contained routes closed; `AppRuntime._reset`). A parent reaches a module's parts as `<module>.<name>`: in app/views/ (`ModuleNames`/`qualifiedName` in `lib/compiler/ui.dart`; `_EngineUi._qualified` in `ui_renderer.dart`, whose scopes listen to the module's bloc for its values) and navigation.yaml (`menu: food.MenuPage`); in code `core.modules.food.<action>(value)`, `.<value>()`, `.navigator.push(FoodRoutes.x)` (`_writeModules` in codegen, `module.*` host ops -> `AppRuntime._moduleCall`). Module models aren't in the parent: those types cross as JSON (`Object?`). A module never sees its parent.
- Dynamic modules: the built-in `metacodeProject` model (`projectModels` in `lib/compiler/models.dart`, added to an app that names it: `files: [{name, content}]`, `folders: [{name, files, folders}]`) is a whole project as data; `lib/files/metacode_project.dart` converts it to files. `miniApp: {project: <value>}` runs it via `lib/engine/dynamic_module.dart` (`compileSources` in `live_project.dart`, then `AppRuntime(sandboxed: true)`: no backend, no parent names, `core.locale.set`/`core.theme.set` do nothing (it shows the parent's)). Changing the project in the state recompiles and `reload`s it, state kept; a version that fails keeps the last one running under the error.
- User code runs in dart_eval (limits: "dart_eval limitations" in REFERENCE.md). The tool bundles each app's files (shared/ included) into one library before compiling; apps don't share code.

## Commands (never launch the app to verify)

- `tool/check.sh [app]`: app loop (default `examples/my_own_app`) (generate, then one `flutter test` of `.generated/all_test.dart`, which imports every user file, so it type-checks them all, and runs the tests in each action and value file's `main()`, plus `tool/layout_test.dart`: every app (modules as a parent shows them) and every route, from the initial state, plus each app's `tests/*.yaml` states (via `.generated/layout_states.json`), at phone, tablet and desktop sizes, failing on overflow or render errors; it knows nothing about the app). No separate analyze step. About 10s.
- `tool/reset_state.sh [modules/<name>]`: deletes an app's saved `.state/state.yaml` (no argument: every app), so the next launch starts from `app.yaml`. Run it whenever a change alters the state's shape (a field of the state or its models added, renamed, retyped or removed); a stale saved state fails to load (`type 'Null' is not a subtype of type 'bool'`).
- `tool/check_engine.sh`: everything (generate the app and `test/fixture_app/`, analyze all, all tests, and `test/web/` in Chrome: the compiler and runtime compiled to JavaScript).
- The running app compiles the project itself: with `--dart-define=METACODE_PROJECT_DIR=<folder>` (desktop) it watches the folder; on web it runs from localStorage, seeded from `.generated/files.json` (reset each launch with `METACODE_RESET_FILES=true`). Every source change (images included) recompiles on a background isolate (~100ms warm, `LiveProject`) and replaces the running version, state kept; no hot reload. The state is saved in the files too (`.state/state.yaml` per app). Without live files it runs the bundled `bundle.json`. VS Code: `metacode (macOS)` and `metacode (web)` in `.vscode/launch.json`.
- `tool/backend.sh [start|dev|stop|logs]`: runs the Dart Frog backend detached on :8080, without hot reload (`server/bin/serve.dart`; `dev` = `dart_frog dev`, which restarts on any .dart change in the repo and drops calls in flight) (logs in `server/.backend.log`); `start` returns once it answers, so the "+ backend" launch configs use it as their preLaunchTask.
- `tool/claude_bridge.sh [start|stop|logs]`: the Claude bridge (`tool/claude_server.dart`) on :8787, detached: `POST /claude {prompt, project}` runs `claude -p` with the metacode MCP on the project in `build/claude_drafts/<id>/` and returns it with the cost and time; `GET /starter` is the editor's starter draft. Called by the editor's remote `askClaude`/`resetDraft`. VS Code: `metacode + backend + claude`.
- `dart run tool/metacode.dart watch`: regenerates `.generated/` on every save, for the IDE and tests.

## Reference

`.claude/skills/metacode-app/REFERENCE.md`: files, types, signatures, a one-line table of all widgets; per-widget props in `reference/widgets/<name>.md`, style/icons/colors in `reference/style.md`. Generated by `dart run tool/reference.dart`.

## Skills

`.claude/skills/`: `metacode-new-app` (build a whole app from an idea: plan, scaffold, parallel agents, check), `metacode-app` (change the app), `metacode-add-widget`, `metacode-engine`.
