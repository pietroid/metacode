# Flutter Data Generation

This spec defines how data stores and models from the Metacode specs are generated into Flutter code.

## State management

- Use `flutter_bloc`.
- Default to a **Cubit** for each store; use a **Bloc** only when explicit event streams or complex transitions add value.
- Keep cubits focused on state changes, not UI details.

## Store generation

For each store declared in `data.yaml`, generate:

### 1. Immutable state class

```dart
import 'package:equatable/equatable.dart';

class CounterState extends Equatable {
  final int value;

  const CounterState({required this.value});

  CounterState copyWith({int? value}) {
    return CounterState(value: value ?? this.value);
  }

  @override
  List<Object?> get props => [value];
}
```

- Use `final` fields only.
- Provide a `const` constructor when possible.
- Provide `copyWith` so cubits can emit new immutable states.
- Extend `Equatable` and expose all value fields in `props`; do not write manual `operator==` / `hashCode` overrides.

### 2. Cubit class

```dart
class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(const CounterState(value: 0));

  void increment() => emit(state.copyWith(value: state.value + 1));
}
```

- Initialize from the spec's `initialValue`.
- Generate one public method per action referenced in behaviors or UI callbacks.
- Always emit a new state; never mutate `state` directly.
- Keep methods synchronous unless the action involves async data access.

## Model generation

From `model_spec`:

- Map primitives:
  - `string` -> `String`
  - `boolean` -> `bool`
  - `number` -> `num`; prefer `int` or `double` when the spec is more specific.
  - `datetime` -> `DateTime`
  - `list(T)` -> `List<T>`
- Model references become custom classes.
- Optional fields (`?`) become nullable (`T?`).
- Generate immutable classes with `final` fields, `copyWith`, and equality overrides.
- Use `const` constructors when all fields are available as const values.
- For JSON serialization, generate `fromJson`/`toJson` only when the repository spec requires it.

Example:

```yaml
user:
  name: string
  age: number
  partner: user?
```

```dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String name;
  final num age;
  final User? partner;

  const User({required this.name, required this.age, this.partner});

  User copyWith({String? name, num? age, User? partner}) => ...;

  @override
  List<Object?> get props => [name, age, partner];
}
```

## Store strategies

### Ephemeral

- Use a plain Cubit.
- State lives only in memory while the cubit is provided.

### Local

- Use `HydratedCubit` **or** inject a local repository backed by `shared_preferences`, `hive`, or similar.
- Load persisted state asynchronously during initialization.
- Emit a loading state followed by a loaded state.
- Persist meaningful state changes; avoid writing on every keystroke.

### Remote

- Inject a repository abstraction into the cubit.
- Emit explicit states for loading, success, and error:
  ```dart
  Future<void> load() async {
    emit(state.copyWith(status: StoreStatus.loading));
    try {
      final data = await _repository.fetch();
      emit(state.copyWith(status: StoreStatus.success, data: data));
    } catch (e) {
      emit(state.copyWith(status: StoreStatus.failure, error: e));
    }
  }
  ```
- Do not expose raw JSON or HTTP details outside the repository.
- Handle errors gracefully and expose them through state, not logs only.

## Repositories

- Abstract every data source behind a repository interface/class.
- Repository methods return domain models, not raw response objects.
- Keep repositories free of UI or state-management concerns.
- Inject repositories into cubits through constructors.

## Wiring with UI

- Provide cubits with `BlocProvider` (or `MultiBlocProvider`).
- UI dispatches actions with `context.read<StoreCubit>().action()`.
- UI reads state with `BlocBuilder`, `BlocSelector`, or `BlocListener` for side effects.

## Testing

- Generate unit tests for cubits using `blocTest` when available.
- Generate widget tests for pages by pumping the dumb widget with a provided `BlocProvider.value`.
- Test each strategy layer independently: models, repositories, cubits, then widgets.

## Avoid

- Mutable state inside cubits.
- Calling repositories directly from widgets.
- Emitting states after the cubit has been closed.
- Passing `BuildContext` into cubit methods.
