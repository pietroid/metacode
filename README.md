# metacode

Metacode is the engine behind my-own.app: describe an app in YAML plus a few
small Dart functions, and the engine runs it. See [PROPOSAL.md](PROPOSAL.md).

## Project layout

```
examples/my_own_app/      the root app (an app is a folder; apps nest)
  app.yaml                  name, description, version, state: initial values
  app/
    actions/*.dart          async functions that emit StateDeltas (and use Core),
                            each with its tests in a main() below it
    actions/shared/*.dart   helpers any action or value calls, one function per file
    models/*.yaml           data shapes, one parent per file (models and enums)
    models/sample.dart      sample states for tests
    views/
      navigation.yaml       routes: pages, bottom sheets, dialogs (optional)
      pages/*.yaml          what routes open (MainPage, sheets, dialogs)
      components/*.yaml     one widget per file
      style/*.yaml          design tokens, one group per file
      style/images/         image assets
      values/*.dart         State -> value for the UI, tests in main() below it
      values/shared/*.dart  helpers any action or value calls, one function per file
      labels/en.yaml        the app's text, pure strings, one file per language (pt_br.yaml)
  tests/*.yaml              selected states the layout check renders at every size
  modules/<name>/           modules, same layout (food, music, work, plants)
  .generated/             produced by the tool, do not edit
  .state/                 runtime state, do not commit
```

Every `.yaml` file contains exactly one top-level key, named after the file;
files are not merged. Files are `this_case.dart` / `this_case.yaml`, keys and
functions `thisCase`, pages and components `ThisCase`
(`app/views/components/example_slide.yaml` holds `ExampleSlide:`). A module is shown
with the `module: <name>` widget and runs with its own state, actions and values: a change inside it rebuilds only it. Each app (modules included)
persists its own state under `.state/`.

Agents: see [AGENTS.md](AGENTS.md) and the skills in `.claude/skills/`.

## Workflow

```sh
tool/check.sh                       # app loop: generate, analyze, test every app
tool/check_engine.sh                # everything: also engine and app_ui tests
dart run tool/metacode.dart         # just validate + generate
```

In VS Code, F5 runs the generator first (`preLaunchTask`).

The tool validates each app, modules included, in order: app/models/
(including the reserved `state.yaml`) → `app.yaml`'s `state:` against the `state`
model → action/value signatures and file names → app/views/labels/ → app/views/pages/ and
app/views/components/ (widget types, properties, and that every action, value, label
and module it names exists) → app/views/navigation.yaml (routes point at pages) →
app/views/style/ (token names and values). Then it generates,
per app:

- `.generated/state.dart`: typed classes (`State`, `Task`, enums) with
  `copyWith`, plus `StateDelta` (every State field, optional) for `emit`.
  This is what your actions and values import.
- `.generated/core.dart`: `Core` (`api`, `navigator`), `ApiResponse` and
  `Routes` (one constant per app/views/navigation.yaml route).
- `.generated/labels.dart`: `Labels`, the app/views/labels/ text as getters.
- `.generated/main.dart`: the JSON bridge the engine calls. You never touch JSON.
- `.generated/program.evc` and `manifest.json`: the compiled bytecode the
  engine loads.
- `.generated/test_app.dart`: typed wrappers that run your actions and
  values through the compiled program, for the tests in each file's `main()`.
- `.generated/bundle.json` (root only): the whole app tree (ui, state, routes,
  labels, style and bytecode of every app). The engine's only project asset, so adding
  a module needs no pubspec change.

## Models

```yaml
# app/models/task.yaml
# A task in the tracker.
task:
  title: string        # string, boolean, number, datetime
  note: string?        # optional
  tags: list(string)   # lists

# app/models/filter.yaml
# Which tasks are currently visible.
filter: [all, open, done]   # enum

# app/models/state.yaml
# The reserved state model types the app's dynamic state.
state:
  tasks: list(task)
  filter: filter
```

## Actions and values

```dart
// app/actions/add_task.dart
Future<void> addTask(State state, void Function(StateDelta) emit) async {
  state.tasks.add(Task(title: state.draft, done: false, createdAt: DateTime.now()));
  emit(StateDelta(tasks: state.tasks, draft: ''));    // only what changes
}

// app/actions/toggle_task.dart
Future<void> toggleTask(State state, void Function(StateDelta) emit, int index) async { ... }

// app/actions/update_draft.dart
Future<void> updateDraft(State state, void Function(StateDelta) emit, String value) async { ... }

// app/actions/load_rate.dart
Future<void> loadRate(State state, void Function(StateDelta) emit, Core core) async {
  emit(StateDelta(rateStatus: FetchStatus.loading));
  final r = await core.api.get('https://open.er-api.com/v6/latest/USD');
  ...
  emit(StateDelta(rate: rate, rateStatus: FetchStatus.loaded));
}

// app/actions/open_settings.dart
Future<void> openSettings(State state, Core core) async {
  await core.navigator.push(Routes.settings);   // app/views/navigation.yaml route
}

// app/views/values/task_title.dart
String taskTitle(State state, int index) => visibleTasks(state)[index].title;

// app/views/values/tasks_left_text.dart: text from state joins labels
String tasksLeftText(State state, Labels labels) =>
    '${openTasks(state).length} ${labels.tasksLeft}';
```

- The first parameter is always `State`. Extra parameters are matched by
  name: `index` (inside a `listView` item), `value` (from inputs) and, for
  actions, `emit` and `core`; any function can take `labels`.
- Actions are `Future<void>` and change the state only with
  `emit(StateDelta(...))`, like a bloc: as many emits as needed, each merged
  over the current state (top-level fields replaced whole). `state` is a
  fresh copy taken at the start, so changing it in place and emitting the
  changed field is fine.
- `core.api.get/post` make HTTP requests (`ApiResponse`: `status`, `body`,
  `ok`, `json`; status 0 is a network error). `core.navigator.push/pop` open
  and close app/views/navigation.yaml routes. `core.locale.set` picks the
  language.
- Values return a primitive, a model, an enum, or a `List` of those.

### Interpreter limits (dart_eval)

Code runs in the dart_eval interpreter, which supports most of Dart, but not
`continue`, nested `?:`, switch expressions, extensions, typedefs or
`Enum.values`, and reading a property of a list that isn't in a variable
(`f().length`) fails at runtime. Closure parameters need types, and only
`dart:` imports and the project's own files are available. The full list, with
what to write instead, is "dart_eval limitations" in
`.claude/skills/metacode-app/REFERENCE.md`.

The tool compiles the code, so these show up in `tool/check.sh` (at generation,
or in the failing test), not in the running app.

## Navigation

`app/views/navigation.yaml` lists what can open on top of the app. Each route shows
one page from app/views/pages/:

```yaml
# app/views/navigation.yaml
initial: home                          # the first page
routes:
  home: MainPage                       # page (shorthand for {page: MainPage})
  dollarRate: {bottomSheet: DollarRateSheet}
  confirmReset: {dialog: ConfirmResetDialog}
```

Actions open routes with `core.navigator.push(Routes.dollarRate)` (completes
when the route closes) and close the top one with `core.navigator.pop()`.
Without navigation.yaml the app is the single page `MainPage`. A module's routes
open on top of the whole app.

## Labels

All the app's text lives in `app/views/labels/<language>.yaml`, one file per
language named after it (`en.yaml`, `pt.yaml`, `pt_br.yaml`), as pure strings:

```yaml
# app/views/labels/en.yaml
en:
  joinWaitlistText: Join waitlist
  peopleOnTheList: people are already on the list
```

Widgets use a label exactly like a value, by key: `text: joinWaitlistText`.
Text that depends on the state is a value that joins labels
(`'$count ${labels.peopleOnTheList}'`). The tool warns about literal text left
in pages and components.

The engine uses Flutter's localization: the root app's languages are the
`supportedLocales`, the device's locale picks one (`en` by default), and each
app (modules too) shows its labels file that fits it; a key a language lacks
shows the default language's text. `core.locale.set('pt_br')` picks the
language for the whole app (saved in `.state/locale.yaml`; `null` follows the
device again), and `labels.locale` / `labels.locales` read it, e.g. for a
`dropdown` language menu (the root's `LanguagePicker`).

## Style

`examples/my_own_app/app/views/style/*.yaml` sets the design tokens every catalog widget is themed
from: light and dark colors, the two font roles (`display` for headlines,
`text` for everything else), the type scale (one entry per text variant),
Phosphor icon weight, radius, spacing and sizes. Each file contains one token
group, so the app's style spells out every value of the Metacode style
(`packages/app_ui/lib/style.dart`); keys left out fall back to it. Bundled
fonts (OFL): Newsreader, Albert Sans, Hanken Grotesk, Schibsted Grotesk,
Figtree, Plus Jakarta Sans, Cormorant Garamond.
Icons: Phosphor (MIT), bundled as fonts in `packages/app_ui/fonts/phosphor`.

```yaml
# style/theme.yaml
theme: system

# style/fonts.yaml
fonts: {display: Newsreader, text: Hanken Grotesk}

# style/icons.yaml
icons: {weight: regular}

# style/colors.yaml
colors:
  light: {accent: "#3049C6"}

# style/radius.yaml
radius: {sm: 10, md: 14}

# style/typography.yaml
typography:
  headlineMedium: {font: display, size: 26, weight: 500, height: 1.2, tracking: -0.009}
```

Pages and components can use the token names (`ink2`, `accent`, `success`, `danger`...).
