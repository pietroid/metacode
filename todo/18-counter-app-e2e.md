# 18 — Counter App End-to-End Verification

## Goal

Wire the entire engine pipeline together and verify that running `metacode run` inside `examples/counter_app/` generates a working, passing Flutter application.

## Scope

- Create the `examples/counter_app/` Flutter project skeleton.
- Add the counter app spec files:
  - `metacode/project.yaml`
  - `metacode/data.yaml`
  - `metacode/ui.yaml`
  - `metacode/behaviors.yaml`
- Update the `run` command to execute the full pipeline:
  1. Discover specs.
  2. Parse YAML.
  3. Build IR and resolve symbols.
  4. Generate deterministic code (project, stores, UI, tests).
  5. Generate AI wrappers.
  6. Run `flutter test`.
  7. Execute the TDD fix loop if needed.
- Add integration test that runs the pipeline against a temporary copy of the counter app and asserts success.

## Acceptance criteria

1. `cd examples/counter_app && go run ../../engine/cmd/metacode run` completes successfully.
2. Generated `lib/` and `test/` files compile.
3. `flutter test` passes.
4. Integration test passes in CI/local environment with Flutter SDK available.
5. README is updated with run instructions.

## Files to create/modify

```
examples/
└── counter_app/
    ├── pubspec.yaml           # regular Flutter pubspec (engine will overwrite/adjust)
    ├── README.md              # example-specific instructions
    └── metacode/
        ├── project.yaml
        ├── data.yaml
        ├── ui.yaml
        └── behaviors.yaml

engine/cmd/metacode/main.go  # or internal/cli/run.go: wire full pipeline
engine/integration_test.go   # end-to-end test
```

### Counter app spec files

`metacode/project.yaml`:
```yaml
name: counter_app
description: Counter app example for Metacode.
```

`metacode/data.yaml`:
```yaml
counterStore:
  value: int
  initialValue: 0
  strategy: ephemeral
```

`metacode/ui.yaml`:
```yaml
homePage:
  scaffold:
    body:
      center:
        text: counterValue
    floatingActionButton: counterButton

counterButton:
  floatingActionButton:
    child:
      text: "Add"
```

`metacode/behaviors.yaml`:
```yaml
When button is tapped, increment counter:
  when: counterButton.onPressed
  then: counterStore.value should be 1

When counter is incremented, increment the store:
  given: counterStore.value is 2
  when: counterStore.increment
  then: counterStore.value should be 3

Show counter value on the home page:
  given: counterStore.value is 5
  when:
  then: homePage.counterValue should be "5"
```

## Layering notes

- Depends on: all previous milestones.
- Enables: user-facing MVP.
- This milestone is primarily integration. Avoid adding new engine features here; surface and fix gaps in earlier milestones instead.
- The integration test may be skipped if Flutter is not installed (`FLUTTER_SDK` check).
