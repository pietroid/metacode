# Flutter UI Generation

This spec defines how the UI spec is transformed into Flutter widget code.

## General rules

- Generate widgets using **Material 3** components from `ui_catalog.md`.
- Each UI spec symbol becomes a `StatelessWidget` class named after the symbol in `PascalCase`.
- The widget generated directly from the UI spec is a **dumb UI**: it receives values and callbacks through its constructor and contains no business logic.
- The deterministic generator only outputs the dumb UI. Binding it to stores (state reactions, callback wiring, etc.) is handled by the AI-generated wrapper layer, guided by the behaviors spec.

## Mapping spec shapes to Flutter

- **Direct child sugar** maps to the widget's canonical content prop (`child`, `title`, `icon`, etc.).
- **List sugar** maps to the `children:` parameter.
- **Nested mapping** maps directly to widget constructor arguments.

Example:

```yaml
counterButton:
  floatingActionButton:
    child:
      text: "Add"
```

becomes a dumb widget:

```dart
class CounterButton extends StatelessWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const FloatingActionButton(
      onPressed: null,
      child: Text('Add'),
    );
  }
}
```

The `onPressed` action (and any other behavior-driven callback) is wired by the AI-generated wrapper, not by the deterministic UI generator.

## Variables

- Unknown bare values (e.g., `counterValue`) are treated as variables.
- Expose them as constructor parameters on the dumb widget.
- The AI-generated wrapper reads them from the corresponding cubit/bloc state and passes them in.

Example:

```yaml
homePage:
  center:
    text: counterValue
```

```dart
class HomePage extends StatelessWidget {
  final String counterValue;

  const HomePage({super.key, required this.counterValue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(counterValue)),
    );
  }
}
```

## State reactions

- Wrap reactive parts of the tree in `BlocBuilder<StoreCubit, StoreState>` or `BlocSelector<StoreCubit, StoreState, T>` to minimize rebuilds.
- Prefer `BlocSelector` when only a small slice of state is needed.
- Keep the builder body small; delegate to the dumb widget.

Example:

```dart
BlocSelector<CounterCubit, CounterState, int>(
  selector: (state) => state.value,
  builder: (context, value) => HomePage(counterValue: '$value'),
)
```

## Callbacks and events

- The deterministic UI generator does **not** need placeholder values such as `onPressed`, `onTap`, or `onChanged` in the UI spec.
- Behavior-driven actions are attached by the AI-generated wrapper layer, e.g., by wrapping the rendered widget with a `GestureDetector` or by injecting the callback into the generated code.
- If an input widget needs to expose a value back to the wrapper, expose it as a constructor parameter and let the wrapper provide the controller/callback.
- Avoid creating closures inside `build` that capture mutable state; pass stable callbacks from outside the dumb widget.

## Widget keys and testability

- Assign a `Key(symbolName)` to the top-level widget of each generated symbol, e.g., `Key('counterButton')`.
- Use semantic labels for accessibility when the spec provides them.
- Generate widget tests that `pumpWidget` the dumb widget with stub values; store integration is tested through the AI-generated wrapper.

## Const and performance

- Use `const` constructors and const child widgets whenever possible.
- Avoid unnecessary `Container` wrappers; use `Padding`, `Center`, `Align`, etc. directly.
- Avoid deeply nested build methods; prefer extracting sub-widgets (which the UI spec already encourages via symbols).

## Widget types

- Default to `StatelessWidget`.
- Use `StatefulWidget` only for local ephemeral UI state (e.g., `TextEditingController`, `FocusNode`, `AnimationController`, `PageController`).
- Dispose controllers and nodes in `dispose()`.

## Layout helpers

- Pages must be wrapped in a `Scaffold`.
- Inside flex parents (`Column`, `Row`), generate `Expanded`/`Flexible` only when the spec explicitly requests expansion or the layout requires it.
- For dynamic lists, generate `ListView.builder` with `itemCount` and `itemBuilder`.
- For static short lists, `ListView(children: [...])` is acceptable.

## Navigation and overlays

- For dialogs defined in the spec, generate `showDialog<T>` calls returning an `AlertDialog`.
- For navigation, prefer named routes when a routing spec exists; otherwise generate `Navigator.push`/`Navigator.pop` with `MaterialPageRoute`.
- Do not pass `BuildContext` across async gaps.

## Avoid in generated UI code

- Business logic or conditional rules derived from behaviors.
- Direct repository or service calls.
- Global state access.
- Hard-coded styles, colors, or text styles (these come from the style spec/theme).
