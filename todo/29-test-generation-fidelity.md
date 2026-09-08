# 29 — Test Generation Fidelity

## Goal

A generated test that does not actually test its scenario should be impossible to
produce silently.

## Why

Tests are the centerpiece of Metacode. A generated test that passes vacuously is
worse than no test, because the fix loop will report success.

Three ways that happens today.

**Events other than `onPressed` produce no action.** `modules/tests/builder.go`:

```go
switch event {
case "onPressed":
    return fmt.Sprintf("await tester.tap(%s);", tapTarget), nil
default:
    return "", nil
}
```

`onChanged`, `onTap`, and `onSubmitted` return an empty string with a nil error.
The template renders a test that pumps the widget and asserts, with no
interaction. It passes if the initial state happens to match. The scenario is not
tested and nothing says so.

**Tap targets are found by type, not identity.** `findTapTarget` returns
`find.byType(ElevatedButton)`. The generated widgets already carry
`key: const Key('counterButton')`, which is exactly what this needs. With two
buttons of the same type on a page, `find.byType` throws, and the fix loop will
try to repair the wrapper rather than the test.

**Assertion fallback invents a target.** `renderAssertion` ends with:

```go
return fmt.Sprintf("expect(cubit.state.value, %s);", then.Value), nil
```

for any `then` whose root resolved to neither a store nor a widget. It asserts on
`state.value` of an unrelated store, with an unquoted raw value.

There is also a housekeeping issue: test filenames are built from the scenario
description, so the counter app produces
`test/counterStore_increments from 0_test.dart`. Spaces in filenames are legal
for Dart but hostile to shell commands, CI globs, and `parseFailures`, which
extracts the filename with `(\S+_test\.dart)` and will truncate at the first
space. That means a failing test with a space in its name cannot be mapped back
to its scenario by the fix loop.

## Scope

- Replace the event switch with a catalog-driven binding. The catalog already
  records which props each widget supports; `onChanged` on a `checkbox` has a
  known tester idiom. An event with no known idiom is an error, not an empty
  string.
- Emit `find.byKey(const Key('counterButton'))`. The keys are already generated.
- Remove the `renderAssertion` fallback. An unresolvable `then` is an error.
- Slugify test filenames: `test/counter_store_increments_from_0_test.dart`. Keep
  the human description in the `testWidgets` name, where it belongs.
- Widen `fileInLine` in `runner/test_runner.go` once filenames are slugs, or
  match on the path rather than a `\S+` run.

## Acceptance criteria

1. A scenario using `onChanged` generates a test that performs an interaction.
2. An event with no known idiom fails generation with a message naming the event.
3. Generated tests locate widgets by key.
4. No generated filename contains a space.
5. A test asserting the wrong initial state fails; add a fixture proving the
   suite is not vacuous.
6. `parseFailures` maps every generated test filename back to its scenario, with
   a test covering it.

## Files to modify

```
engine/internal/modules/tests/builder.go
engine/internal/modules/tests/codegen/flutter/templates/*.tmpl
engine/internal/planner/planner.go       # pathToID / filename slug
engine/internal/runner/test_runner.go
```

## Related: the fix loop

Two things to settle while here, both in `runner/fix_loop.go`:

- `Run` executes the test suite `MaxIterations` times inside the loop and then
  once more after it, so `MaxIterations: 3` runs `flutter test` four times. Either
  document that or restructure the loop.
- `fixFailure` only regenerates wrapper files. If the failure is in a store
  action body (the likely case once actions are more than `increment`), the loop
  regenerates something unrelated, burns an iteration, and reports the same
  failure. Decide which generated files the LLM is allowed to edit and enforce it
  explicitly.
