# 24 — Collapse the Duplicate Generator Layer

## Goal

One place that knows how to generate Flutter code. Right now there are two, and
which one runs depends on whether an API key is set.

## Why

The tree has both:

```
engine/internal/generators/flutter/        # wrapper.go, wrapper_deterministic.go, tests.go, prompt_builder.go
engine/internal/modules/codegen/flutter/   # generate.go, module.go
engine/internal/modules/{data,ui,project,tests}/codegen/flutter/
```

`done/11a-modules-and-templates-refactor.md` moved generation under `modules/`.
The move did not finish: `internal/generators/` still exists and holds the
wrapper and AI logic. `cli/run.go` imports both, under two different aliases
(`generatorsflutter` and `flutter`), which is a fair signal that the split has no
meaning left.

The cost is not aesthetic. `wrapper.go` (LLM path) and `wrapper_deterministic.go`
(no-LLM path) produce different code for the same specs, and only one of them
runs on any given invocation. Whichever one you did not run is untested by the
example. `generators/flutter/tests.go` is a 24-line function that forwards to
`modules/tests`, which is the shape of a layer that no longer earns its place.

## Scope

- Move `wrapper.go`, `wrapper_deterministic.go`, `prompt_builder.go` under a
  wrapper concern in `modules/`, alongside data/ui/project/tests.
- Delete `generators/flutter/tests.go` and call `modules/tests` directly.
- Delete `internal/generators/` when empty.
- Collapse the two wrapper strategies behind one interface:

  ```go
  type WrapperGenerator interface {
      Generate(ctx context.Context, app *ir.IR, tasks []planner.Task, outDir string) error
  }
  ```

  with a deterministic implementation and an LLM implementation, selected once in
  `cli/run.go` rather than branching twice (once for wrappers, once for the test
  loop) as it does today.
- Both implementations must produce the same file set and the same class names
  for the counter app, so the example is valid either way.

## Acceptance criteria

1. `internal/generators/` no longer exists.
2. `cli/run.go` imports one Flutter generation package.
3. The strategy branch appears once, not twice.
4. Generating `examples/counter_app` with and without `METACODE_LLM_API_KEY` set
   produces the same file names and the same class names.
5. Existing tests pass unchanged, or move with their code.

## Files to modify

```
engine/internal/generators/flutter/*        # move out, then delete the directory
engine/internal/modules/codegen/flutter/generate.go
engine/internal/cli/run.go
```

## While in there

Some small dead weight to remove, since it is all in the same blast radius:

- `shared.DartPackageName` and `project.PackageName` are the same function,
  character for character. Keep one.
- `ir.ValidateUIProps` and `ui.Validate` implement the same check. `ValidateUIProps`
  is never called. Keep `ui.Validate`.
- `runner/test_runner.go` ends with `nopReporter` (unused) and
  `var _ io.Writer = (*bytes.Buffer)(nil)`, an assertion about the standard
  library that only exists to keep an import alive.

## Result

Done. The layout now is:

```
engine/internal/modules/wrappers/codegen/flutter/   # wrapper.go, deterministic.go, llm.go, prompt.go, appdart.go
engine/internal/modules/codegen/flutter/            # the Flutter facade: GenerateAll, NewWrapperGenerator, GenerateTests
```

`internal/generators/` is gone. `cli/run.go` imports one Flutter package.

The two strategies now share a driver. `wrapper.go` plans the wrapper set
(which widgets get a wrapper, what each class is called, which file it goes in),
writes whatever body a `bodyFunc` renders, and rewrites `lib/app.dart`. Only the
body differs: `deterministic.go` renders from the IR, `llm.go` asks a model.
That is what makes acceptance criterion 4 hold rather than merely be hoped for,
and it is pinned by `parity_test.go`. The LLM path additionally renames the
returned class to the planned name instead of trusting the model to have
followed the prompt.

The strategy branch appears twice in the codebase and zero times in `run.go`:
`flutter.NewWrapperGenerator(client)` and `runner.NewVerifier(...)` each decide
from one value, a nil `llm.Client`. Adding `runner.Verifier` (the fix loop, or a
single test run) is what removed the second `if llmErr == nil` from `run.go`;
without it the branch would still be there, just moved.

Wrapper target files come from `planner.Task.TargetFile` rather than being
recomputed. The fix loop reads wrapper files by task target, so recomputing the
path was a silent way for the two to drift.

### On the "while in there" list

Two of the three were already gone by the time this ran: there is no
`shared.DartPackageName` (only `project.PackageName`), and no
`ir.ValidateUIProps`. `runner/test_runner.go` had no `nopReporter` either; the
`var _ io.Writer` assertion was in `test_runner_test.go` and is now removed.

### The LLM path was broken, and why

With one shared driver the AI path became the only path that actually tries to
*wrap*, and it immediately failed: every tap test asserted N+1 and got N.

The cause was not in the wrapper layer at all. `ui/codegen/flutter/widget.go`
emitted every button as `onPressed: null`, so `CounterButton` rendered
permanently disabled with no parameter through which anything could be wired.
The model saw this, said so in a code comment, and tried to route around it with
an ancestor `GestureDetector`, which a disabled `ElevatedButton` swallows. The
deterministic path had been hiding the defect by never instantiating the dumb
widget: it re-emitted its own `ElevatedButton` from the IR, so the dead one in
`pages/` never mattered.

The fix is the contract 26 already calls for: an event a behavior declares
becomes a constructor parameter on the dumb widget.

- `counterButton.onPressed` is in `behaviors.yaml`, so `CounterButton` now takes
  `this.onPressed` and renders `onPressed: onPressed`. A button no behavior
  refers to still renders `onPressed: null`, since there is nothing to wire.
- A widget that embeds another forwards its events:
  `HomePage` takes `this.counterButtonOnPressed` and renders
  `CounterButton(onPressed: counterButtonOnPressed)`. Without this a page could
  only ever be rendered with a dead child, which is what made the model's page
  wrapper useless even when it compiled.
- The deterministic button wrapper now wraps `CounterButton(onPressed: ...)`
  instead of re-rendering a button, so the two strategies compose the same tree.
- The prompt tells the model to pass the dumb widget's parameters and not to
  reimplement it or reach for a `GestureDetector`.

`metacode run` on `examples/counter_app` now passes on both paths, and the AI
path passes on the first fix-loop iteration in three consecutive runs.
`TestDeclaredEventBecomesConstructorParameter` and
`TestParentForwardsChildEvents` pin it; both fail if the `null` comes back.

The page wrapper still re-renders rather than wrapping `HomePage`. That is the
larger half of 26 and is left to it.
