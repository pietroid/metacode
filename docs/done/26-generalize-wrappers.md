# 26 — Generalize Wrapper Generation

## Goal

Make the deterministic wrapper generator a function of the IR rather than a
function of the counter app.

## Why

`modules/wrappers/codegen/flutter/deterministic.go` (moved there by 24) passes
the counter app for reasons that will not generalize:

```go
bodyRaw, ok := comp.Props["body"].(map[string]any)
centerRaw, ok := bodyRaw["center"].(map[string]any)
columnList, ok := centerRaw["column"].([]any)
```

The page layout is read by walking the literal path `body → center → column`. Any
other page renders with no children at all, silently: the type assertions fail,
`bodyChildren` stays empty, and `childrenArg` becomes `""`, which produces
`Column(,)`. There is no error and no warning.

`inferButtonAction` is the same shape. It decides which Cubit method a button
calls by parsing the `given` and `then` values as integers and comparing them:
greater means `increment`, smaller means `decrement`, and the default when
nothing matches is `increment`. A button on a string store gets wired to
`increment()`.

Meanwhile `buildMethods` in the store generator emits real bodies for exactly
`increment` and `decrement` and `throw UnimplementedError` for everything else,
and adds an `increment` method to every numeric store whether or not any behavior
asks for one.

There is a third problem, visible in the generated output. The UI module
generates `lib/pages/home_page.dart`, a clean `HomePage` widget with a
`counterValue` parameter. The wrapper does not use it: `home_page_wrapper.dart`
rebuilds the entire `Scaffold` from scratch, and `updateAppDart` then deletes the
`pages/` import from `app.dart`. The deterministic UI generation is thrown away
and re-derived by a second renderer. Two renderers for the same tree is why
`wrapper_deterministic.go` is the largest file in the engine at 477 lines.

## Scope

### 1. Wrap, do not re-render

**Still open.** Dumb widgets now expose their values and callbacks as
constructor parameters, and the LLM page wrapper composes `HomePage` rather than
rebuilding it. The deterministic page wrapper still rebuilds the tree, so the
two strategies produce structurally different pages and the per-widget wrappers
are dead code on the LLM path. The `renderWrapper*` block is what remains.

The wrapper should compose the generated dumb widget and inject bound values,
not rebuild its tree:

```dart
class HomePageWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<CounterCubit, CounterState, String>(
      selector: (state) => state.value.toString(),
      builder: (context, counterValue) => HomePage(counterValue: counterValue),
    );
  }
}
```

This deletes `renderWrapper*` entirely (roughly 200 lines), makes `pages/` live
code, and means there is one renderer for the widget tree.

**Done, in 24.** Generated widgets now expose callback parameters: any event a
behavior references becomes a constructor parameter on the dumb widget
(`CounterButton({super.key, this.onPressed})`), and a widget that embeds another
forwards its events (`HomePage` takes `counterButtonOnPressed`). It is optional
rather than required so a dumb widget still renders standalone. The button
wrapper already wraps instead of re-rendering. What remains here is the page
wrapper, which is where the ~200 lines of `renderWrapper*` live.

### 2. Derive actions from behaviors, not from arithmetic

**Done, in [31](31-store-logic-and-vacuous-tests.md).** `ir.Binding` resolves the
widget event to its store action during `Resolve`, and the store, wrapper and
test generators all read it. The name comes from the widget rather than from
comparing the scenario's values. An event that drives two stores is an error.
What follows was the plan; it is kept for the record.

The action name is already in the spec. `when: counterStore.increment` names it.
When the `when` is a widget event (`counterButton.onPressed`), the action is
whatever store action the same scenario's `then` implies, and that link should be
made explicit in the IR during planning rather than guessed at render time.

Add to `planner.Task` (or to a dedicated binding type) the resolved pair:

```go
type Binding struct {
    Widget string   // counterButton
    Event  string   // onPressed
    Store  string   // counterStore
    Action string   // increment
}
```

If the pair cannot be resolved, that is an error to report, not a default to
guess.

### 3. Store actions need a body source

**Done, in [31](31-store-logic-and-vacuous-tests.md), by the third option.** The
generator scaffolds signatures with `UnimplementedError` and the fix loop fills
the bodies, which required teaching `fixFailure` that store files are editable.
Without an LLM the actions stay unimplemented and the run says so. What follows
was the plan; it is kept for the record.

`increment`/`decrement` hard-coded in `buildMethods` is a placeholder. Options,
in increasing order of ambition:

- Declare actions in `data.yaml` with an expression (`increment: value + 1`).
- Derive the body from the scenario's `given`/`then` pair, which is exactly what
  a behavior spec is: a worked example of the transformation.
- Leave the body as `UnimplementedError` and let the LLM fix loop fill it, which
  is the README's stated philosophy for business rules.

The third is the cheapest and most consistent with the design, but it requires
the fix loop to be allowed to edit store files, which today it is not: `fixFailure`
only regenerates wrapper tasks. Pick one deliberately and write it down; the
current situation is all three at once by accident.

## Acceptance criteria

1. No literal prop path (`body`, `center`, `column`) appears in the wrapper
   generator.
2. A page whose body is not `center → column` generates correct children.
3. `lib/pages/*.dart` is imported by the generated app.
4. Button wiring comes from a resolved binding; an unresolvable binding is a
   reported error, not `increment`.
5. `deterministic.go` is under 200 lines.
6. The counter app output is equivalent (the wrapper may differ, tests must pass).

## Files to modify

```
engine/internal/modules/wrappers/codegen/flutter/deterministic.go
engine/internal/modules/ui/codegen/flutter/widget.go
engine/internal/modules/data/codegen/flutter/store.go
engine/internal/planner/{planner.go,task.go}
```
