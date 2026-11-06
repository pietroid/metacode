# metacode

Metacode is the engine behind my-own.app: describe an app in YAML plus a few
small Dart functions, and the engine runs it. See [PROPOSAL.md](PROPOSAL.md).

## Project layout

```
metacode/
  project.yaml      name, description
  models.yaml       data shapes; the reserved `state` model types state.yaml
  state.yaml        the app state (validated against `state`)
  ui.yaml           widgets (see lib/engine/catalog.dart)
  actions/*.dart    State -> State transfer functions
  bindings/*.dart   State -> value for the UI
  generated/        produced by the tool, do not edit
lib/engine/         the Flutter engine
tool/metacode.dart  validator + code generator
```

## Workflow

```sh
dart run tool/metacode.dart         # validate everything and generate
dart run tool/metacode.dart check   # validate only
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
