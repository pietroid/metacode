---
name: metacode-engine
description: Change the Metacode engine itself - the Flutter runtime (lib/engine), the validator/code generator (tool/), or app_ui internals. Use for new YAML features, new model types, codegen changes, persistence, or renderer behavior. Not for app features (metacode-app) or new widgets (metacode-add-widget).
---

# Change the engine

Read `AGENTS.md` first (map and flow). Verify with:

```sh
tool/check_engine.sh
```

Never launch the app. `test/renderer_test.dart` renders `metacode/generated/bundle.json` (all apps) and taps it. Extend it for UI and runtime behavior.

## Where things are

| Change | Where |
|---|---|
| New model primitive or type syntax | `tool/src/models.dart` (`primitives`, `TypeRef`, `validateState`), then the `_fromJson`/`_toJson`/`dartType` functions in `tool/src/codegen.dart` |
| Action/relation signature rules, context params | `tool/src/functions.dart` (`contextParamTypes`, `actionParamTypes` for `emit`/`core`, `isEncodable`). The UI param names list is `contextParams` in `packages/app_ui/lib/spec.dart` |
| What actions reach (`emit`, `core.api`, `core.navigator`) | Interpreted side: `generateCore` + `_writeDelta` in `tool/src/codegen.dart`, calling `hostCall`/`hostEmit` (`lib/engine/host.dart`, stubs for the analyzer). Bridge: `lib/engine/host_plugin.dart` (`HostPlugin`, `MetacodeHost`). App side: `lib/engine/core_host.dart`. Test side: `_testAppHead` in codegen. New op = a `Core` method + a case in `CoreHost.call` + the fake in `TestApp.call`. |
| Routes | `lib/engine/navigation.dart` (navigation.yaml parse, pure Dart, shared by tool and engine), pushed in `CoreHost.push`. |
| App folders, merging `.yaml` files, sub-app recursion | `tool/src/project.dart` (`loadApp`, `AppProject`) |
| ui/ validation | `tool/src/ui.dart` (uses `widgetCatalog` and `normalizeProps` from `spec.dart`; `PropKind.app` checks sub-app names) |
| Generated code | `tool/src/codegen.dart`: `generateState` (+ `StateDelta`), `generateCore`, `generateMain` (engine bridge, async `$action_x`/`$binding_x`), `generateTestApp`, `_encodeDart`/`_decodeDart` |
| Compile/bundle, manifest, `bundle.json` | `tool/metacode.dart` (`_generate` per app, children first; `_bundle`) |
| Calling user code at runtime | `lib/engine/program.dart` (one dart_eval `Runtime`, JSON in/out) |
| Node resolution, actions to state, relation cache | `lib/engine/ui_renderer.dart` (`_EngineUi implements Ui`; `UiRenderer.relation` caches per state identity, so never mutate a state map in place) |
| Sub-apps at runtime | `lib/engine/app_runtime.dart` (`AppRuntime.embed`: own `StateBloc` via `StateBloc.child`, own program and `CoreHost`, shared navigator; theme from its style/ if any) |
| State persistence | `lib/engine/state_bloc.dart` (root: `METACODE_STATE_PATH` dart-define, else `<docs>/<name>/state.yaml`; sub-apps: `<docs>/<name>/apps/<app>/state.yaml`. Saved values merge over the initial state) |
| Asset loading | `lib/engine/project_config.dart` (`ProjectConfig.fromBundle`); pubspec lists only `bundle.json` and `metacode/assets/` |
| Styling: tokens, default style, theme | `packages/app_ui/lib/style.dart` (tokens, `metacodeStyle`, `resolveStyle`, `validateStyle`), `packages/app_ui/lib/src/theme.dart` (`MetacodeTheme.build`, `MetacodeTokens`). The tool puts each app's merged `style/` in the bundle; `main.dart` sets theme/darkTheme/themeMode. Fonts (7 OFL families) and Phosphor icon fonts in `packages/app_ui/fonts` + its pubspec; icon maps in `src/icons.dart`. `metacode/style/style.yaml` may change values but must name every key of `metacodeStyle` (style_test). |
| App-author reference | `tool/reference.dart` generates `.claude/skills/metacode-app/REFERENCE.md`. Update its static text when types or signatures change. |

## Contracts to keep

- The engine talks JSON to `generated/main.dart`. User code only sees typed objects.
- If a codegen change touches what user code sees, update the `metacode-app` skill and the README.
- dart_eval quirks: cross-library calls can break, so each app's code is bundled into one library (the bundle keeps only `dart:` imports and the host bridge import). Closure params need types. Int interpolation from bridged getters fails. No typedefs and no callable classes (hence `void Function(StateDelta) emit`). Host functions that return a Future must return `$Future.wrap(...)` of a `$Value`. After codegen changes, run the check: `generated/*` must still compile, and every app's `test/` exercises it through the interpreter.
