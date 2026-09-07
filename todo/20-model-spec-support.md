# 20 — Model Spec Support

## Goal

Implement parsing and generation for `models.yaml`, including primitive fields, model references, optional fields, lists, and enums.

## Scope

- Discover and parse `models.yaml` if present.
- Extend the IR with `Model` and `Enum` types.
- Map Metacode primitives to Dart:
  - `string` -> `String`
  - `boolean` -> `bool`
  - `number` -> `num` (prefer `int` or `double` when detectable)
  - `datetime` -> `DateTime`
  - `list(T)` -> `List<T>`
- Handle optional fields (`?`) as nullable Dart types.
- Generate immutable `Equatable` classes with `final` fields, constructor, `copyWith`, and `props`.
- Generate enum declarations.
- Update data spec generation to use model types for store values.

## Acceptance criteria

1. The `user`/`gender` example from `model_spec.md` generates `User` and `Gender` classes.
2. Optional fields generate nullable types.
3. List fields generate `List<T>`.
4. Enums generate Dart enums.
5. Generated code compiles.
6. Unit tests assert type mappings and class structure.

## Files to create/modify

```
engine/internal/spec/discovery.go  # add models.yaml path
engine/internal/spec/parser.go     # parse models.yaml
engine/internal/ir/
├── model.go            # Model and Enum types
├── builder.go          # build models from raw specs
└── model_test.go

engine/internal/generators/flutter/
├── model.go            # Model/Enum generator
└── model_test.go
```

## Layering notes

- Depends on: IR builder, naming helpers.
- Enables: richer data specs and store state classes.
- JSON serialization (`fromJson`/`toJson`) is deferred until repository/remote strategy support is added.
- The model spec was not required for the counter app MVP; this milestone extends the engine's capabilities.
