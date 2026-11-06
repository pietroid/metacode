---
name: metacode-engine
description: Change the Metacode engine itself - the Flutter runtime (lib/engine), the validator/code generator (tool/), or app_ui internals. Use for new YAML features, new model types, codegen changes, persistence, or renderer behavior. Not for app features (metacode-app) or new widgets (metacode-add-widget).
---

# Change the engine

Read `AGENTS.md` first (map and flow). Verify with:

```sh
tool/check_engine.sh
```

Never launch the app. `test/renderer_test.dart` renders ui.yaml and taps it. Extend it for UI and runtime behavior.

## Where things are

| Change | Where |
|---|---|
| New model primitive or type syntax | `tool/src/models.dart` (`primitives`, `TypeRef`, `validateState`), then the `_fromJson`/`_toJson`/`dartType` functions in `tool/src/codegen.dart` |
| Action/binding signature rules, context params | `tool/src/functions.dart` (`contextParamTypes`, `isEncodable`). The param names list is `contextParams` in `packages/app_ui/lib/spec.dart` |
| ui.yaml validation | `tool/src/ui.dart` (uses `widgetCatalog` and `normalizeProps` from `spec.dart`) |
| Generated code | `tool/src/codegen.dart`: `generateState`, `generateMain` (engine bridge, `$action_x`/`$binding_x`), `generateTestApp`, `_encodeDart`/`_decodeDart` |
| Compile/bundle and manifest | `tool/metacode.dart` (`_generate`, `_bundle`) |
| Calling user code at runtime | `lib/engine/program.dart` (one dart_eval `Runtime`, JSON in/out) |
| Node resolution, actions to state | `lib/engine/ui_renderer.dart` (`_EngineUi implements Ui`) |
| State persistence | `lib/engine/state_bloc.dart` (`METACODE_STATE_PATH` dart-define, else the app documents folder) |
| Asset loading | `lib/engine/project_config.dart` and `pubspec.yaml` assets |
| App-author reference | `tool/reference.dart` generates `.claude/skills/metacode-app/REFERENCE.md`. Update its static text when types or signatures change. |

## Contracts to keep

- The engine talks JSON to `generated/main.dart`. User code only sees typed objects.
- If a codegen change touches what user code sees, update the `metacode-app` skill and the README.
- dart_eval quirks: cross-library calls can break, so everything is bundled into one library. Closure params need types. Int interpolation from bridged getters fails. After codegen changes, run the check: `generated/*` must still compile, and `metacode/test` exercises it through the interpreter.
