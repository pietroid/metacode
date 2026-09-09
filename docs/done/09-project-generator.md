# 09 — Project Generator

## Goal

Generate the Flutter project scaffold: `pubspec.yaml`, `lib/main.dart`, and `lib/app.dart`.

## Scope

- Generate `pubspec.yaml` from the project spec name and description.
- Include required dependencies for the MVP:
  - `flutter: sdk: flutter`
  - `flutter_bloc`
  - `equatable`
- Include dev dependencies:
  - `flutter_test: sdk: flutter`
  - `flutter_lints: ^3.0.0`
  - `bloc_test`
- Generate `lib/main.dart` with `runApp(const MyApp())`.
- Generate `lib/app.dart` with a `MaterialApp` whose home is the first page from the UI spec (`homePage` for the counter app).
- Add a generated-file header comment to each file.

## Acceptance criteria

1. Running the generator on the counter app IR produces `pubspec.yaml`, `lib/main.dart`, and `lib/app.dart`.
2. The generated `pubspec.yaml` has a valid Dart package name derived from the project name.
3. `flutter pub get` succeeds in the generated project (can be verified manually).
4. The generated `main.dart` and `app.dart` are syntactically valid Dart.
5. Unit tests assert file contents contain expected strings.

## Files to create/modify

```
engine/internal/generators/flutter/
├── project.go           # pubspec + entry point generation
├── app.go               # app.dart generation
├── naming.go            # shared casing helpers
└── project_test.go
```

### Suggested API

```go
package flutter

func GenerateProject(ir *ir.IR, outDir string) error
```

- `outDir` is the Flutter project root (e.g. `examples/counter_app`).
- Writes files directly to disk.

## Layering notes

- Depends on: IR, naming helpers.
- Enables: store and UI generators have a project to write into.
- `app.dart` hard-codes `home: const HomePage()` for the MVP. A routing spec will replace this later.
- The generator should not overwrite user-owned files outside `lib/`; for now it only writes generated files.
