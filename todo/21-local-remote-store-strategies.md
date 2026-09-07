# 21 — Local and Remote Store Strategies

## Goal

Extend the data store generator to support `local` and `remote` persistence strategies, not just `ephemeral`.

## Scope

### Local strategy

- Generate a `HydratedCubit` or a plain Cubit with an injected local repository.
- Add required dependencies to `pubspec.yaml` (e.g. `shared_preferences`, `hive`).
- Load persisted state asynchronously and emit loading/loaded states.

### Remote strategy

- Generate a repository abstraction and implementation.
- Inject the repository into the Cubit.
- Emit explicit `loading`, `success`, and `failure` states.
- Generate repository method stubs that return domain models.

### General

- Extend `Store` IR with strategy-specific options.
- Update `pubspec.yaml` generator to include strategy dependencies.
- Update behavior planner to understand async loading states.

## Acceptance criteria

1. A store with `strategy: local` generates a Cubit that persists and reloads state.
2. A store with `strategy: remote` generates a repository interface, implementation, and Cubit with status states.
3. Generated code compiles after running `flutter pub get`.
4. Unit tests verify the correct strategy code is emitted.

## Files to create/modify

```
engine/internal/ir/store.go              # add strategy options
engine/internal/generators/flutter/
├── store.go                             # extend for strategies
├── repository.go                        # repository generation
└── pubspec.go                           # dependency selection
```

## Layering notes

- Depends on: data store generator, project generator.
- Enables: real-world data persistence.
- Keep repository implementations minimal (stubs) for the first pass. The LLM can fill them in via the wrapper/fix loop if behaviors require specific logic.
- Model serialization (`fromJson`/`toJson`) should be added here or just before, since remote repositories typically need it.
