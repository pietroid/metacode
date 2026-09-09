# 32 — Simplification Plan

> **Executed 2026-09-08.** All eight phases are done and `make check` is green.
> Four things went differently from the plan, each deliberate and each noted at
> its phase below: the composition root needed its own package
> (`codegen/flutter`, with `codegen/dart` as the toolkit under it), the wrapper
> renderer collapse also removed the wrapper-per-button, the complexity gate
> excludes test files, and the phase 0 golden test was **removed at the end, on
> request**, once the refactor it was guarding was finished. Generated output
> changed once, on purpose, in phase 5.

## Goal

A Go project a person can read end to end in an afternoon: every package in the
place its name predicts, no representation that nothing consumes, no interface
with one implementation, and comments that say why a rule exists rather than
retelling the run that discovered it.

Nothing about what the engine produces changes. `examples/counter_app` must
generate byte-identical output before and after every phase below. That was the
only acceptance criterion that mattered, and Phase 0 made it checkable while the
work was in flight.

## The two axes

The tree has to stay open along two directions, and the structure should say so:

- **spec kind** — ui, data, project, behaviors, and later models, groups
- **target language** — Flutter today, another one later

So the shape is `<spec kind>/rules` for interpreting and validating a spec, and
`<spec kind>/codegen/<language>` for generating from it. That is preserved and
made consistent everywhere. What gets deleted is the weight that is *not* on
either axis.

## Where the weight actually is

6,105 lines of non-test Go, 4,083 of tests, over 25 packages. The problem is not
the depth of the tree — it is that a third of the packages sit off the axes,
several things exist in two copies, and a measurable amount of the code has no
reader at all.

Measured, not guessed:

| Symptom | Evidence |
|---|---|
| Layers off the axes | `modules/codegen/flutter/` (a `GenerateAll` that forwards to four packages, plus a `Module = "flutter"` const referenced nowhere) sits *alongside* `modules/ui/codegen/flutter/`, at the same depth, meaning something different |
| `wrappers` is a spec kind that is not one | `modules/wrappers/` has no `rules.go` — only `codegen/flutter/`. Wrappers are not a spec; they are what behaviors need in order to be wired |
| The core/modules boundary is already broken | `core/ir/builder.go` imports `modules/ui/catalog`, so core depends on a module |
| Spec interpretation lives in core, not in the spec | `core/ir/builder.go` holds `buildData`, `buildUI`, `buildComponent`, `applyProps`, `extractSingleKind`, `buildBehaviors` — the ui sugar rules and the data rules, 453 lines, in the one package that is supposed to be spec-agnostic |
| Two Dart renderers | `modules/ui/codegen/flutter/widget.go` (455 lines) and `modules/wrappers/codegen/flutter/deterministic.go` (395 lines), the second a `renderWrapper*`-prefixed copy of the first |
| Dead code | `go run golang.org/x/tools/cmd/deadcode ./...` reports `log.NopReporter`, `data.IsNumericType`, `wrappers.findScenario`, `wrappers.splitWidgetRef`; `dart.ExtractCode` is referenced only by its own test |
| Write-only representation | `SymbolTable.Actions` and `SymbolTable.Variables` are populated in `resolver.go` and never read anywhere; `IR.Models` and `IR.Enums` are assigned in `builder.go` and never read |
| Dead task fields | `Task.PromptContext`, `Task.ExpectedOutcome`, `Task.Description`, `Task.IsWrapper()`, `Task.IsTest()` have no reader outside `planner/`. The planner spends ~70 lines building prompt strings that nothing sends |
| Interfaces with one implementation | `wrappers.Generator` (+ `bodyFunc`, + `Name()`, + the `NewWrapperGenerator` alias) has exactly one implementation; so does `runner.Verifier` |
| The same helper three times | `findScenario` in `modules/tests`, `modules/data/codegen/flutter`, `modules/wrappers/codegen/flutter`; `isPage` in `ui/codegen/flutter/widget.go` duplicates `shared.IsPageName`; `isLowerCamelIdentifier` in `ir/builder.go` duplicates `shared.IsVariableIdentifier`; `indent` in `appdart.go` duplicates `shared.Indent` |
| A hidden assumption in three places | `app.Stores[0]` in `tests/builder.go`, `wrappers/deterministic.go` and `appdart.go`. Stores 2..n are silently ignored |
| A package named for nothing | `modules/shared/` — naming helpers, Dart literals and string utilities together, imported by everything |

## Target layout

```
engine/
├── cmd/metacode/                    # flags, then hand off to core/run
└── internal/
    ├── core/                        # read specs, build the model, plan, execute
    │   ├── model/                   # Project, Store, Widget, Scenario, Binding, Symbols. No imports
    │   ├── spec/                    # find metacode/, read the YAML, load .env → raw specs
    │   ├── build/                   # raw specs → model, by calling each spec kind's rules
    │   ├── plan/                    # model → Plan: which wrappers, which tests
    │   └── run/                     # the stage list, the test run, the repair loop
    ├── specs/
    │   ├── project/
    │   │   ├── rules/
    │   │   └── codegen/flutter/
    │   ├── data/
    │   │   ├── rules/
    │   │   └── codegen/flutter/
    │   └── ui/
    │       ├── rules/
    │       ├── catalog/             # the widget vocabulary: a ui-spec concern
    │       └── codegen/flutter/
    ├── behavior/                    # the centerpiece spec, promoted to its own top level
    │   ├── rules/                   # scenarios, assertions, and the widget-event → store-action bindings
    │   └── codegen/flutter/         # the tests, the wrappers, and the implement/repair prompts
    ├── codegen/
    │   ├── dart/                    # AS BUILT: the Dart writing toolkit, below every generator
    │   └── flutter/                 # AS BUILT: the Flutter target, the step order above it
    ├── llm/
    ├── log/
    └── order/
```

Four decisions in there worth stating out loud, because each one answers a
question the current tree answers twice:

**`core/model` is a leaf.** Every spec kind's `rules` package fills its slice of
the model, so `rules` imports `core/model`. If the model package also held the
build orchestration it would import `rules` back, and that is an import cycle.
Types with no imports in `core/model`; the orchestration that calls each spec's
rules in `core/build`.

**Interpretation moves out of core, into the spec it belongs to.** `buildData`
→ `specs/data/rules`, `buildUI`/`buildComponent`/`applyProps`/`extractSingleKind`
→ `specs/ui/rules`, `buildProject` → `specs/project/rules`,
`buildBehaviors`/`ParseAssertion`/`resolveBindings` → `behavior/rules`.
`core/build` becomes a short, readable list: call each rules package, collect
warnings, resolve symbols. This is what makes "add a spec kind" a folder plus
one line in `core/build`, and it is also what fixes the `core → modules/ui/catalog`
import that broke the current boundary.

**`codegen/flutter` is the layer below the per-spec generators, not a sibling of
them.** It holds what every Flutter generator needs and no spec kind owns:
identifier casing, Dart literals and string escaping, the generated-file marker
and the pruning that reads it, the shape checks applied to model output
(`dart.Validate`, `Balanced`, `RenameClass`), the template execution helper, and
the one Dart renderer. Adding SwiftUI is `codegen/swiftui` plus a
`codegen/swiftui` folder under each spec kind. This is the same content as
today's `modules/codegen` + `modules/codegen/dart` + the useful half of
`modules/shared`, but positioned so its role is unambiguous.

**`behavior` absorbs wrappers and implement.** `modules/wrappers` and
`internal/implementer` both exist to serve behaviors: a wrapper is how a
scenario's widget event reaches a store action, and the implement stage fills in
the behavior the scenarios describe. They are not a spec kind and they are not
generic execution. `behavior/codegen/flutter` holds the tests, the wrappers, and
the prompts, and `behavior/rules` holds the bindings that all three read.

### On package names

Six packages will be named `flutter`. That is what forces the five import
aliases in `cli/run.go` today (`dataflutter`, `projectflutter`, `uiflutter`,
`testsflutter`, `wrappersflutter`). Keep the directory names — they carry the
axis — and give each package a unique name: directory `specs/ui/codegen/flutter`,
`package uiflutter`. A package name that differs from its directory is legal Go
and common in trees like this one; it is the cheaper of the two costs, and it
means an import never needs an alias to be readable. If that reads badly in
review, the fallback is to keep `package flutter` everywhere and write the alias
convention down in `ARCHITECTURE.md` once, instead of inventing it per file.

### What this does and does not shrink

The package count lands near 19, not near 8. Under this structure that is the
right answer: every package is one spec kind × one concern, and the count grows
with the specs and languages you actually support. The consolidation comes from
Phases 1, 3 and 5 — dead code, one-implementation interfaces, and the duplicate
renderer — which is roughly 1,200 non-test lines, not from collapsing folders.

## Phases

Each phase is independently shippable and ends green. Deletions come first so
the structural move in Phase 4 has less to carry.

### Phase 0 — Guard rails — DONE, then reverted

> **As built, then removed.** The golden test did its job: it caught every
> unintended output change through phases 1 to 4 and made the phase 5 change
> reviewable. It was deleted at the end of the work, on request, along with its
> fixtures and the `make golden` target. `make check` still gates vet, the test
> suite, `deadcode` and `gocyclo`.

Nothing else in this plan is safe without this.

- Add a golden test: generate `examples/counter_app` from its specs into a temp
  dir with no LLM configured, and compare every file against a checked-in tree
  under `engine/testdata/counter_app/`. Extend the existing
  `modules/codegen/flutter/fixtures_test.go` rather than starting fresh.
- Add a `Makefile` with `make check` = `go vet ./... && go test ./... && deadcode ./...`.
- Acceptance: `make check` is green, and changing one line of any generator
  fails the golden test.

### Phase 1 — Delete what nothing reads — DONE

Pure deletion, no behavior change, no moves.

- `log.NopReporter`, `data.IsNumericType`, `wrappers.findScenario`,
  `wrappers.splitWidgetRef`, `dart.ExtractCode` (and its test).
- `SymbolTable.Actions`, `SymbolTable.Variables`, `ActionRef`, `VariableRef`,
  and the `resolver.go` lines that fill them. Keep the `Register(when, "action")`
  call — the *kind* is read; the parallel map is not.
- `IR.Models`, `IR.Enums`, `ir.Model`, `ir.Enum` and `buildData`'s model/enum
  arms. `data.yaml` may still declare them: keep the parse and emit one warning,
  `"data.yaml: models are declared but not generated yet (see todo/20)"`, so a
  spec author is told instead of shown a half-built representation.
  `examples/task_app/metacode/models.yaml` is the case to check.
- `Task.PromptContext`, `Task.ExpectedOutcome`, `Task.Description`,
  `Task.IsWrapper`, `Task.IsTest`, and the ~70 lines of `strings.Builder` in
  `planner.go` that fill them.
- The duplicate helpers: one `findScenario` (it lands in `core/model` as a
  method on the model), `isPage` → `IsPageName`, `isLowerCamelIdentifier` →
  `IsVariableIdentifier`, `indent` → `Indent`.
- Acceptance: `deadcode ./...` reports nothing; golden tree unchanged; non-test
  line count down by roughly 450.

### Phase 2 — One plan type per output kind — DONE

`planner.Task` is a union: a `Type` field, a `Widget` field meaningful for one
type, a `ScenarioID` meaningful for the other. Five places filter it back apart
(`PlanWrappers`, `BuildTestCases`, `ExpectedFiles`, `prompt.go`,
`implementer.editableFiles`).

- Replace with:

  ```go
  // Plan is everything a run will generate, decided before anything is written.
  type Plan struct {
      Wrappers []Wrapper // one per widget that needs wiring
      Tests    []Test    // exactly one per scenario
  }
  ```

  `Wrapper{Widget, Class, File}`, `Test{ScenarioID, File}`.
- Delete `TaskType` and the `task.Type != planner.TaskX` guard in all five
  callers.
- Fold `PlanWrappers` into building the `Plan`, so the wrapper file list has one
  producer instead of being re-derived by `ExpectedFiles`, `editableFiles` and
  the generator.
- Acceptance: no `switch`/`if` on a task kind survives; golden tree unchanged.

### Phase 3 — Collapse the one-implementation interfaces — DONE

- `wrappers.Generator`, `bodyFunc`, `Name()`, `NewDeterministicGenerator`,
  `DeterministicGenerator`, and the `WrapperGenerator` alias → one function
  `GenerateWrappers(app, plan, outDir)`.
- `runner.Verifier` + `singleRun` + `NewVerifier` → one function
  `Verify(ctx, runner, repairer, reporter)`, where a nil repairer means "run once
  and report". The `Name()` methods exist only to fill a log line, which can say
  `"no LLM configured: ran the suite once"` directly.
- `runner.ProgressReporter` and `log.Reporter` are two reporter interfaces, which
  is why `cli.loggerReporter` exists. Keep `log.Logger` only; delete the adapter.
- Delete `modules/codegen/flutter/module.go` (`Module = "flutter"`, unused) and
  fold its `GenerateAll` forwarding into the stage list.
- One interface is worth *keeping*, and it is the one that does not exist yet:
  the seam for language number two. `core/run` must not import a Flutter package
  directly, so define there

  ```go
  // Target is one language the engine can generate. Chosen once, in cmd.
  type Target interface {
      Scaffold(ctx context.Context, app *model.App, plan plan.Plan, dir string) error
      Implement(ctx context.Context, ...) error
      Test(ctx context.Context, dir string) (TestResult, error)
  }
  ```

  and assemble the Flutter implementation in `cmd/metacode`. One implementation
  today, but it is the reason the tree has a language axis at all — unlike the
  three interfaces above, which had no second implementation in prospect.
- Acceptance: `grep -rn "interface {" internal` returns `llm.Client`,
  `log.Logger`, `Repairer`, and `run.Target` — nothing else.

### Phase 4 — Move to the target tree — DONE

> **As built.** The composition root could not live in the shared layer: the
> package that orders the generators has to import them, and they import the
> shared helpers. So the shared layer is `codegen/dart` (the Dart writing
> toolkit: layout, literals, templates, marker, prune, shape checks) and
> `codegen/flutter` is the step order above it. `core/run` reaches the implement
> stage through `run.Target`, which broke the last cycle.


Mechanical, one commit per move so each diff stays reviewable. Run the golden
test after every commit.

1. `core/ir` → `core/model` (types only) + `core/build` (orchestration).
   `IR` → `App`; `Symbols.Symbols` disappears with the rename.
2. `core/spec` + `core/env` → `core/spec`. `planner` → `core/plan`. `runner` +
   `cli`'s stage list → `core/run`.
3. `modules/{project,data,ui}/rules.go` → `specs/<kind>/rules/`, and move the
   matching `build*` functions out of `core/build` into them. `modules/ui/catalog`
   → `specs/ui/catalog`.
4. `modules/{project,data,ui}/codegen/flutter` → `specs/<kind>/codegen/flutter`.
5. `modules/tests` + `modules/tests/codegen/flutter` + `modules/wrappers/codegen/flutter`
   + `implementer` → `behavior/rules` and `behavior/codegen/flutter`. The
   scenario and assertion parsing and `resolveBindings` go to `behavior/rules`;
   the test builder, the wrapper generator, `appdart.go` and the prompts go to
   `behavior/codegen/flutter`.
6. `modules/codegen` + `modules/codegen/dart` + the naming and Dart-literal half
   of `modules/shared` → `codegen/flutter`. `modules/shared`'s remaining string
   utilities go to whichever package uses them, and the package disappears.
7. `core/order` stays as `internal/order` — 12 lines, no imports, importable from
   anywhere. It is the one util that earns being global.
8. Give each `codegen/flutter` package a unique package name (`uiflutter`,
   `dataflutter`, `projectflutter`, `behaviorflutter`, `flutter` for the shared
   layer) and delete every import alias.
- Acceptance: no import in the tree needs an alias; nothing under `internal/`
  imports upward (`specs/*` and `behavior/*` import `core/model` and
  `codegen/flutter`, never `core/build`, `core/plan` or `core/run`); `modules/`
  no longer exists; golden tree unchanged.

### Phase 5 — One Dart renderer, one store rule — DONE

> **As built, and the one deliberate output change.** The transcripts settled
> it: with an API key set the model discarded the deterministic page wrapper and
> wrote a twenty-line composition of the generated page instead. The renderer
> now composes that page directly, which deleted the 372-line copy and, with it,
> the wrapper per button — a page instantiates its own children, so nothing
> could ever reference those files. The counter app's golden tree lost
> `increment_button_wrapper.dart` and `decrement_button_wrapper.dart`, and a
> full run with the LLM passes 7/7 tests in one request with the deterministic
> wrapper left untouched.


The largest remaining duplication, and easiest to get wrong, so it goes after
the move, when both renderers sit under `codegen/flutter`.

- `codegen/flutter/render.go` keeps one renderer. Today's
  `renderWrapperListItem`, `renderWrapperComponent`, `renderWrapperCatalogWidget`,
  `renderWrapperDefaultProp`, `renderWrapperPropValue`, `renderWrapperRawList`,
  `renderWrapperChildrenList`, `rawMapToComponent` and
  `buildWrapperComponentValue` are the existing `renderer` methods with a
  bindings map threaded through. Give the `renderer` struct optional
  `bindings` and `childWrappers` fields; delete the copies.
- Worth deciding while in there: with an API key set, the implement stage
  rewrites every wrapper anyway. Read the transcripts under
  `examples/counter_app/.metacode/llm/` first. If the deterministic wrapper body
  is only ever a compiling placeholder on that path, it can shrink to a stub and
  the binding-aware rendering goes entirely. Decide it explicitly; do not leave
  both paths alive because neither was measured.
- `generatePageWrapper` reaches into the raw props map for the literal path
  `body.center.column`. That is a spec shape smuggled into a generator: read the
  page's `Children` like every other component does.
- Make the single-store assumption explicit once. Either validate it in the
  resolve stage — `"this engine supports exactly one store today; data.yaml
  declares 3"` — or thread the store through the three call sites. Silently
  generating for `Stores[0]` is the worst of the three options.
- Acceptance: one `renderer` type in the tree; `Stores[0]` appears at most once,
  next to the validation that justifies it; golden tree unchanged.

### Phase 6 — Cyclomatic complexity budget — DONE

> **As built.** `gocyclo` counts every subtest closure into its parent, so a
> table of assertions scores like a branching algorithm while carrying none of
> the risk. The gate runs with `-ignore "_test\.go"`; non-test code is clean at
> `-over 12`.


- Add `gocyclo -over 12 ./engine` to `make check`. The known offenders are the
  ui sugar rules (`buildComponent` / `applyProps` / `extractSingleKind`: nested
  type switches with three fallback loops) and `cli.runCommand` (~150 lines of
  stage closures with logging inline).
- In `specs/ui/rules`, introduce one documented step that normalizes any YAML
  widget node into `{kind, props, children}`, then build components from the
  normalized form in a single pass. The three sugar rules — a string is the
  default prop, a list is children, a single-key map is the kind — belong in
  that one function, stated as three cases, not spread across three functions
  with fallbacks.
- `catalog.New()` allocates a fresh map on every call and is called *inside*
  `classifyKind`, `isVariableReference` and `defaultContentProp` — once per YAML
  node. Build one catalog in `cmd` and pass it in, as `Resolve` already does.
- `core/run` gets one named function per stage and a stage table. The reader
  should see the pipeline as a list.
- Comments: keep every rule, move the war stories. Roughly a dozen doc comments
  are postmortems ("a Cubit came back with placeholder bodies…", "which named
  every button on a non-numeric store increment"). They are the most valuable
  writing in the repo and the wrong length for a function header. Leave the
  one-line rule at the code and move the narrative to `docs/decisions.md`, one
  dated entry each, linked by name.
- Acceptance: `gocyclo -over 12` is clean; no function longer than ~60 lines;
  every package has a doc comment naming its one job in a sentence.

### Phase 7 — Documentation — DONE

The docs authorized the current structure, so they change for real.

- **New `engine/ARCHITECTURE.md`** — the document that answers "I want to
  understand this codebase":
  - the pipeline in ten lines: specs → model → plan → deterministic files → one
    LLM request → `flutter test` → repair loop;
  - the two axes, and the tree above, one line per package;
  - **how to add a spec kind**: a `specs/<kind>/rules` package that fills its
    slice of the model, a `codegen/<language>` under it, one line in
    `core/build`, one line in the stage list;
  - **how to add a language**: `codegen/<lang>` for the shared layer, a
    `codegen/<lang>` under each spec kind, one `run.Target` implementation
    assembled in `cmd`;
  - an ownership table: which generated path is deterministic, which the LLM may
    rewrite, and which is never rewritten (`test/`, `lib/widgets/`,
    `lib/stores/*_state.dart`). That invariant is enforced in
    `implementer.editableFiles` and stated nowhere a reader would look.
- **`README.md`** — "How it works" claims three stages; the engine runs ten.
  Replace with the real stage list and state the ownership rule up front. The
  README's spec examples also disagree with `examples/counter_app` (README shows
  `stack:` / `aligned.bottomRight:`, the example uses `body` / `center` /
  `column`); reconcile to what the parser accepts.
- **`specification/engine/metacode_engine.md`** — this is the doc that produced
  the current tree, and two of its rules are now false:
  - "break down scenario into subscenarios according to its unit parts" was
    reversed by `done/31-store-logic-and-vacuous-tests.md`: one scenario, one
    test, against the whole app. Rewrite it.
  - "each folder corresponding to the step and each file corresponding to
    sub-step" is what produced `modules/codegen/flutter` sitting beside
    `modules/ui/codegen/flutter`. Replace it with the two axes: a folder is a
    spec kind or a language, and a new level needs a reason on one of those axes.
- **`specification/engine/project_structure.md`** — describes a `.lock` folder
  that does not exist. Mark it planned and point at `backlog/23-lock-and-diff.md`.
- **`done/`** — 27 milestone docs, several superseding each other (`11a`, `11b`
  and `24` restructure the same tree three times). Add `done/README.md` listing
  them with a one-line outcome and marking which are superseded, so a reader
  stops treating an outdated one as current design.
- **`CLAUDE.md` / `makerbook/main.md`** — record the layout and the two axes, so
  the next session does not rebuild the old shape.
- Acceptance: `ARCHITECTURE.md` exists and its package map matches
  `go list ./...`; no doc describes a folder that is not in the tree.

## Order of operations

```
0 guard rails → 1 delete → 2 plan types → 3 interfaces → 4 move tree
  → 5 one renderer → 6 complexity → 7 docs
```

1–3 are deletions, and they shrink what Phase 4 has to move. 5 and 6 are much
cheaper once the tree is settled. 7 last, because it describes the result.

## What is explicitly out of scope

- The lock/diff optimization (`backlog/23`), grouping
  (`todo/grouping-support.md`), model spec support (`todo/20`), multi-store, and
  a second target language. This plan makes room for each of them; it does not
  start them.
- Any change to the generated Flutter output, the spec syntax, or the prompts.
  If a phase's diff touches a prompt or a `.tmpl`, it has left its scope.
