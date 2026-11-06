# Metacode

A Flutter engine that runs an app described in YAML plus small Dart functions.

## Map

| Path | What |
|---|---|
| `metacode/` | **The app.** `models.yaml`, `state.yaml`, `ui.yaml`, `actions/`, `bindings/`, `test/` |
| `metacode/generated/` | Output of the tool. Never edit. |
| `tool/metacode.dart` | CLI: validate + generate. `tool/src/`: `models.dart` (models/state), `functions.dart` (action/binding signatures, via analyzer), `ui.dart` (ui.yaml), `codegen.dart` (generated files) |
| `packages/app_ui/` | **UI catalog.** `lib/spec.dart` (pure-Dart contract the tool validates against), `lib/src/widgets/*.dart` (one builder each), `lib/src/registry.dart`, `lib/src/parsers.dart` |
| `lib/engine/` | Runtime: `program.dart` (loads bytecode, calls actions/bindings), `ui_renderer.dart` (resolves nodes, implements `Ui`), `state_bloc.dart` (state + persistence), `project_config.dart` (asset loading) |
| `test/` | Engine tests (renders ui.yaml and taps) |

## Flow

```
models.yaml ─┐
state.yaml ──┼─ tool/metacode.dart ─> generated/state.dart     (typed State, models, enums)
actions/ ────┤   (validate all)       generated/main.dart      (JSON bridge, engine-facing)
bindings/ ───┤                        generated/program.evc    (dart_eval bytecode, bundled)
ui.yaml ─────┘                        generated/test_app.dart  (typed test harness)

Engine: state (Map) ─> binding ─> app_ui widget ─> tap ─> action(state) ─> next state ─> state.yaml
```

- Actions: `State name(State state, [int index], [T value])`, return the next State.
- Bindings: `T name(State state, [int index])`, return a primitive, model, enum or List of those.
- User code runs in dart_eval. The tool bundles all user files into one library before compiling.

## Commands (never launch the app to verify)

- `tool/check.sh`: app loop (generate, analyze `metacode/`, `metacode/test`). About 15s.
- `tool/check_engine.sh`: everything (generate, analyze all, all tests).

## Skills

`.claude/skills/`: `metacode-app` (change the app), `metacode-add-widget`, `metacode-engine`.
