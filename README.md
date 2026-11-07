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
  navigation.yaml   routes: pages, bottom sheets, dialogs (optional)
  style.yaml        design tokens: colors, fonts, type, radius, spacing
  actions/*.dart    async functions that emit StateDeltas (and use Core)
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
action/binding it names exists) → navigation.yaml (routes point at ui.yaml
widgets) → style.yaml (token names and values). Then it generates:

- `generated/state.dart`: typed classes (`State`, `Task`, enums) with
  `copyWith`, plus `StateDelta` (every State field, optional) for `emit`.
  This is what your actions and bindings import.
- `generated/core.dart`: `Core` (`api`, `navigator`), `ApiResponse` and
  `Routes` (one constant per navigation.yaml route).
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
Future<void> addTask(State state, void Function(StateDelta) emit) async {
  state.tasks.add(Task(title: state.draft, done: false, createdAt: DateTime.now()));
  emit(StateDelta(tasks: state.tasks, draft: ''));    // only what changes
}

Future<void> toggleTask(State state, void Function(StateDelta) emit, int index) async { ... }
Future<void> updateDraft(State state, void Function(StateDelta) emit, String value) async { ... }

Future<void> loadRate(State state, void Function(StateDelta) emit, Core core) async {
  emit(StateDelta(rateStatus: FetchStatus.loading));
  final r = await core.api.get('https://open.er-api.com/v6/latest/USD');
  ...
  emit(StateDelta(rate: rate, rateStatus: FetchStatus.loaded));
}

Future<void> openSettings(State state, Core core) async {
  await core.navigator.push(Routes.settings);   // navigation.yaml route
}

// bindings/bindings.dart
String taskTitle(State state, int index) => visibleTasks(state)[index].title;
```

- The first parameter is always `State`. Extra parameters are matched by
  name: `index` (inside a `listView` item), `value` (from inputs) and, for
  actions, `emit` and `core`.
- Actions are `Future<void>` and change the state only with
  `emit(StateDelta(...))`, like a bloc: as many emits as needed, each merged
  over the current state (top-level fields replaced whole). `state` is a
  fresh copy taken at the start, so changing it in place and emitting the
  changed field is fine.
- `core.api.get/post` make HTTP requests (`ApiResponse`: `status`, `body`,
  `ok`, `json`; status 0 is a network error). `core.navigator.push/pop` open
  and close navigation.yaml routes.
- Bindings return a primitive, a model, an enum, or a `List` of those.

### Interpreter limits (dart_eval)

Code runs in the dart_eval interpreter, which supports most of Dart, but:

- Write closure parameter types: `where((Task t) => t.done)`, not `(t) => ...`.
- Avoid interpolating ints that come from `DateTime` getters (`'${d.month}'`);
  use `toIso8601String()` or `.toString()`.
- Only `dart:` imports and the project's own files are available.

The tool compiles the code, so these problems show up at generation time, not
at runtime.

## Navigation

`metacode/navigation.yaml` lists what can open on top of the app. Each route
shows one ui.yaml widget:

```yaml
initial: home                          # the first page
routes:
  home: homePage                       # page (shorthand for {page: homePage})
  dollarRate: {bottomSheet: dollarRateSheet}
  confirmReset: {dialog: confirmResetDialog}
```

Actions open routes with `core.navigator.push(Routes.dollarRate)` (completes
when the route closes) and close the top one with `core.navigator.pop()`.
Without navigation.yaml the app is the single page `homePage`.

## Style

`metacode/style.yaml` sets the design tokens every catalog widget is themed
from: light and dark colors, the two font roles (`display` for headlines,
`text` for everything else), the type scale (one entry per text variant),
Phosphor icon weight, radius, spacing and sizes. The app's file spells out every
value of the Metacode style (`packages/app_ui/lib/style.dart`), so it shows
exactly how the template looks; keys left out fall back to it. Bundled fonts
(OFL): Newsreader, Albert Sans, Hanken Grotesk, Schibsted Grotesk, Figtree.
Icons: Phosphor (MIT), bundled as fonts in `packages/app_ui/fonts/phosphor`.

```yaml
theme: system
fonts: {display: Newsreader, text: Hanken Grotesk}
icons: {weight: regular}
colors:
  light: {accent: "#3049C6"}
radius: {sm: 10, md: 14}
typography:
  headlineMedium: {font: display, size: 26, weight: 500, height: 1.2, tracking: -0.009}
```

ui.yaml colors can use the token names (`ink2`, `accent`, `success`, `danger`...).
