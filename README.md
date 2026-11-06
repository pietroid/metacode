# metacode

Metacode is the engine behind my-own.app: describe an app in YAML plus a few
small Dart functions, and the engine runs it. See [PROPOSAL.md](PROPOSAL.md).

## Project layout

```
metacode/
  project.yaml      name, description
  models.yaml       data shapes; the reserved `state` model types state.yaml
  state.yaml        the app state (validated against `state`)
  ui.yaml           widgets (catalog: packages/app_ui/lib/spec.dart)
  actions/*.dart    State -> State transfer functions
  bindings/*.dart   State -> value for the UI
  test/             tests for actions and bindings
  generated/        produced by the tool, do not edit
packages/app_ui/    the UI catalog (spec + one builder per widget)
lib/engine/         the Flutter engine
tool/metacode.dart  validator + code generator
```

Agents: see [AGENTS.md](AGENTS.md) and the skills in `.claude/skills/`.

## Workflow

```sh
tool/check.sh                       # app loop: generate, analyze, test metacode/
tool/check_engine.sh                # everything: also engine and app_ui tests
dart run tool/metacode.dart         # just validate + generate
```

In VS Code, F5 runs the generator first (`preLaunchTask`).

The tool validates, in order: models → state against the `state` model →
action/binding signatures → ui.yaml (widget types, properties, and that every
action/binding it names exists). Then it generates:

- `generated/state.dart`: typed classes (`State`, `Task`, enums) with
  `copyWith`. This is what your actions and bindings import.
- `generated/main.dart`: the JSON bridge the engine calls. You never touch JSON.
- `generated/program.evc` and `manifest.json`: the compiled bytecode the
  engine loads.
- `generated/test_app.dart`: typed wrappers that run your actions and
  bindings through the compiled program, for `metacode/test/`.

## Models

```yaml
task:
  title: string        # string, boolean, number, datetime
  note: string?        # optional
  tags: list(string)   # lists
filter: [all, open, done]   # enum

state:                 # reserved: the shape of state.yaml
  tasks: list(task)
  filter: filter
```

## Actions and bindings

```dart
// actions/actions.dart
State addTask(State state) {
  state.tasks.add(Task(title: state.draft, done: false, createdAt: DateTime.now()));
  return state.copyWith(draft: '');
}

State toggleTask(State state, int index) { ... }   // index: list item position
State updateDraft(State state, String value) { ... } // value: input value

// bindings/bindings.dart
String taskTitle(State state, int index) => visibleTasks(state)[index].title;
```

- The first parameter is always `State`. Extra parameters are matched by
  name: `index` (inside a `listView` item) and `value` (from inputs).
- Actions return the next `State`. They get a fresh copy, so changing it in
  place is fine.
- Bindings return a primitive, a model, an enum, or a `List` of those.

### Interpreter limits (dart_eval)

Code runs in the dart_eval interpreter, which supports most of Dart, but:

- Write closure parameter types: `where((Task t) => t.done)`, not `(t) => ...`.
- Avoid interpolating ints that come from `DateTime` getters (`'${d.month}'`);
  use `toIso8601String()` or `.toString()`.
- Only `dart:` imports and the project's own files are available.

The tool compiles the code, so these problems show up at generation time, not
at runtime.
