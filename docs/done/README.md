# Completed milestones

One line per milestone, newest last. Several of these describe a tree or a
design that a later milestone replaced: those are marked **superseded**, and
what replaced them is named. Read a superseded doc as history, not as current
design.

For the design as it stands now: `engine/ARCHITECTURE.md`. For why the rules are
what they are: `docs/decisions.md`.

| # | Milestone | Outcome |
|---|---|---|
| 00 | Overview | **Superseded** by `engine/ARCHITECTURE.md`. Its planned layout (`internal/{spec,ir,catalog,generators}`) is not the tree. |
| 01 | Go project bootstrap | The `engine/` module and `go.work`. |
| 02 | Logger and reporter | `internal/log`. The reporter is a struct now, not an interface. |
| 03 | Spec discovery | `internal/core/spec`, walks up for a `metacode/` folder. |
| 04 | YAML parsing | `spec.Parse` into raw maps. |
| 05 | Internal representation | **Partly superseded** by 32: the types stayed and live in `core/model`, but the interpretation moved out to each spec's `rules/`, and Models/Enums were removed as unbuilt. |
| 05b | Layered architecture | **Superseded** by 32. The `core`/`modules` split it introduced did not hold: `core/ir` imported `modules/ui/catalog`. Replaced by the spec-kind and language axes. |
| 06 | UI catalog | `specs/ui/catalog`, the widget vocabulary. One shared instance since 32. |
| 07 | Symbol resolution | Now `core/build/resolve.go`. |
| 08 | Behavior parser | Now `behavior/rules/parse.go`. |
| 09 | Project generator | `specs/project/codegen/flutter`. |
| 10 | Data store generator | `specs/data/codegen/flutter`. Method bodies deliberately absent since 31. |
| 11 | UI widget generator | `specs/ui/codegen/flutter`. |
| 11a | Modules and templates refactor | **Superseded** by 32. Introduced `modules/`, which 32 replaced with `specs/`. Its templates decision stands. |
| 11b | Drop .tmpl suffix, project topology | Template tree mirrors a real Flutter project; the generator walks it. Stands. |
| 12 | LLM client | `internal/llm`, Anthropic by default, OpenAI-compatible optional. |
| 13 | Behavior planner | **Superseded** by 32. Its Task struct carried prompt text nothing sent; replaced by `core/plan`, which names work only. |
| 14 | AI wrapper generator | **Superseded** by 26 and 32. Wrappers are rendered deterministically and refined by the implement stage; there is no per-wrapper request. |
| 15 | Test generator | One test per scenario. Reinforced by 31. |
| 16 | Flutter test runner | `core/run/test_runner.go`. Takes its command from the target since 32. |
| 17 | TDD fix loop | `core/run/fix_loop.go`. One request per iteration carrying every failure. |
| 18 | Counter app end to end | The example under `examples/counter_app`. |
| 22 | Reproducible output | Sorted map iteration everywhere it can reach output. Stands. |
| 24 | Collapse generator layers | Removed the duplicate `generators/` tree. Its wrapper-strategy interface was itself removed by 32, having only ever had one implementation. |
| 26 | Generalize wrappers | Wrappers derived from the spec rather than hardcoded. Its renderer was replaced in 32 by composing the generated widget. |
| 31 | Store logic and vacuous tests | One scenario, one test, against the whole app. No inferred store actions, no fallback assertions. Stands. |
| 32 | Simplification | The current tree and `make check`. See `todo/simplification-plan.md`. |
