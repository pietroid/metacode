---
name: metacode-engine
description: Change the Metacode engine itself - the Flutter runtime (lib/engine), the validator/code generator (tool/), or app_ui internals. Use for new YAML features, new model types, codegen changes, persistence, or renderer behavior. Not for app features (metacode-app) or new widgets (metacode-add-widget).
---

# Change the engine

Read `AGENTS.md` first (map and flow). Verify with:

```sh
tool/check_engine.sh
```

Never launch the app. `test/renderer_test.dart` renders `examples/my_own_app/.generated/bundle.json` (all apps) and taps it. Extend it for UI and runtime behavior.

## Where things are

| Change | Where |
|---|---|
| New model primitive or type syntax | `lib/compiler/models.dart` (`primitives`, `TypeRef`, `validateState`), then the `_fromJson`/`_toJson`/`dartType` functions in `lib/compiler/codegen.dart` |
| Action/value signature rules, context params | `lib/compiler/functions.dart` (`contextParamTypes`, `actionParamTypes` for `emit`/`core`, `sharedParamTypes` for `labels`, `isEncodable`). The UI param names list is `contextParams` in `packages/app_ui/lib/spec.dart` |
| What actions reach (`emit`, `core.api`, `core.navigator`) | Interpreted side: `generateCore` + `_writeDelta` in `lib/compiler/codegen.dart`, calling `hostCall`/`hostEmit` (`lib/engine/host.dart`, stubs for the analyzer). Bridge: `lib/engine/host_plugin.dart` (`HostPlugin`, `MetacodeHost`). App side: `lib/engine/core_host.dart`. Test side: `_testAppHead` in codegen. New op = a `Core` method + a case in `CoreHost.call` + the fake in `TestApp.call`. |
| Routes | `lib/engine/navigation.dart` (navigation.yaml parse, pure Dart, shared by tool and engine), pushed in `CoreHost.push`. |
| App folders, one-parent-per-file `.yaml` files, module recursion | `lib/compiler/project.dart` (`loadApp`, `AppProject`) |
| ui/ validation | `lib/compiler/ui.dart` (uses `widgetCatalog` and `normalizeProps` from `spec.dart`; `PropKind.app` checks module names) |
| Generated code | `lib/compiler/codegen.dart`: `generateState` (+ `StateDelta`), `generateCore`, `generateMain` (engine bridge, async `$action_x`/`$binding_x`), `generateTestApp`, `_encodeDart`/`_decodeDart` |
| Compile/bundle, manifest, `bundle.json`, `files.json` | `lib/compiler/build.dart` (`build(ProjectFiles)` -> `BuildResult` with outputs in memory; `_generate` per app, children first; `_bundle`). No dart:io: the CLI (`tool/metacode.dart`) and the app both call it |
| Project files (read/write/watch, same folder structure everywhere) | `lib/files/project_files.dart` (`ProjectFiles`: in memory, sync reads, `changes` stream), `io_project_files.dart` (a folder, watched), `local_storage_project_files.dart` (web; sources only). Platform pick: `lib/engine/files/open_project_files.dart` (`METACODE_PROJECT_DIR` on desktop; web seeds from `.generated/files.json`, reset with `METACODE_RESET_FILES`) |
| Calling user code at runtime | `lib/engine/program.dart` (one dart_eval `Runtime`, JSON in/out) |
| Node resolution (values, then labels), actions to state, value cache, rebuilds | `lib/engine/ui_renderer.dart` (`_EngineUi implements Ui`; `UiRenderer.value` caches per state identity, so never mutate a state map in place; `_Scope` = one page/component/lazy node: records the values it reads while building, then `context.select`s them, so it rebuilds only when those results change) |
| Modules at runtime | `lib/engine/app_runtime.dart` (`AppRuntime.embed`: own `StateBloc` via `StateBloc.child`, own program and `CoreHost`, shared navigator; theme from its style/ if any) |
| State persistence | `lib/engine/state_bloc.dart` on a `StateStore` (`lib/engine/state_store.dart`): from the project's files, `FilesStateStore` saves `.state/state.yaml` next to each app's sources (disk or localStorage); from the bundle, `DocumentsStateStore` (`METACODE_STATE_PATH` for the root, else `<docs>/<name>/[modules/<module>/].state/state.yaml`; none on web). Saved values merge over the initial state |
| New app version at runtime (hot reload, downloaded bundle) | `MetacodeApp` given a new config -> `AppRuntime.reload` (in place, recursive into created modules; every `render`ed route listens) -> `StateBloc.reconfigure` (values kept, new fields get their initial value). Dev trigger: `LiveProject.watch` (`lib/engine/live_project.dart`: recompiles on every source change) -> `_LiveApp` in `lib/main.dart`; without live files, `_LiveApp.reassemble` reloads `bundle.json` |
| App files at runtime (images) | `Ui.file(path)` (app_ui) -> `UiRenderer.readFile` -> `ProjectConfig.readFile` (set by `LiveProject`, reads `ProjectFiles`); null means a bundled asset. The image widget prefers it |
| Asset loading | `lib/engine/project_config.dart` (`ProjectConfig.fromBundle`, `loadBundle` uncached); pubspec lists only `bundle.json` and `examples/my_own_app/app/views/style/images/` |
| Styling: tokens, default style, theme | `packages/app_ui/lib/style.dart` (tokens, `metacodeStyle`, `resolveStyle`, `validateStyle`), `packages/app_ui/lib/src/theme.dart` (`MetacodeTheme.build`, `MetacodeTokens`). The tool puts each app's merged `style/` in the bundle; `main.dart` sets theme/darkTheme/themeMode. Fonts (7 OFL families) and Phosphor icon fonts in `packages/app_ui/fonts` + its pubspec; icon maps in `src/icons.dart`. `examples/my_own_app/style/*.yaml` may change values but must name every key of `metacodeStyle` (style_test). |
| App index (`.generated/INDEX.md`) | `lib/compiler/index.dart`, fed by `WidgetRefs` (`lib/compiler/ui.dart`), `UserFunction` touches + `headerComment` (`lib/compiler/functions.dart`), `AppProject.docs` (`lib/compiler/project.dart`) |
| App-author reference | `tool/reference.dart` generates `.claude/skills/metacode-app/REFERENCE.md`, `reference/widgets/*.md` and `reference/style.md`. Update its static text when types or signatures change. |

## Contracts to keep

- The engine talks JSON to `.generated/main.dart`. User code only sees typed objects.
- If a codegen change touches what user code sees, update the `metacode-app` skill and the README.
- dart_eval quirks: cross-library calls can break, so each app's code is bundled into one library (the bundle keeps only `dart:` imports and the host bridge import). Closure params need types. Int interpolation from bridged getters fails. No typedefs and no callable classes (hence `void Function(StateDelta) emit`). Host functions that return a Future must return `$Future.wrap(...)` of a `$Value`. After codegen changes, run the check: `generated/*` must still compile, and every app's tests (the `main()` in each action/value file, dropped from the bundle by `stripTests` in `lib/compiler/functions.dart`) exercise it through the interpreter.
