# Engine Improvement Plan

The counter app works end to end. That is the achievement worth protecting, and
it is also the problem: several parts of the engine are shaped like the counter
app rather than like a code generator. This folder is the plan to fix that
without losing the working example.

## Reading order

Milestones 19, 20, 21 are the original feature roadmap. The files below are
structural work discovered by reading the engine against its own specification.

| # | Title | Kind | Blocks | Status |
|---|---|---|---|---|
| 22 | [Reproducible output](../done/22-reproducible-output.md) | Correctness | 23 (lock/diff) | **done** |
| 24 | [Collapse the duplicate generator layer](../done/24-collapse-generator-layers.md) | Structure | everything | **done** |
| 25 | [Enforce the core/module boundary](25-core-module-boundary.md) | Structure | multi-target | — |
| 26 | [Generalize wrapper generation](26-generalize-wrappers.md) | Correctness | 20, 21 | — |
| 27 | [Multi-store support](27-multi-store-support.md) | Correctness | 20, 21 | — |
| 28 | [Diagnostics with source positions](28-diagnostics-and-source-positions.md) | UX | — | — |
| 29 | [Test generation fidelity](29-test-generation-fidelity.md) | Correctness | 19 | — |
| 30 | [Golden-file harness and CI](30-golden-harness-and-ci.md) | Infrastructure | all | — |

## Phases

**Phase A — make the engine trustworthy.** 22 (done), 30. Until output is
byte-reproducible and there is a harness that catches regressions without a
Flutter SDK, every other change is unverifiable. 22 also happens to be a hard
prerequisite for the lock/diff optimization the README promises: diffing
generated files is meaningless if unchanged specs produce different bytes.

Generation is now reproducible, pinned by
`engine/internal/planner/pipeline_determinism_test.go`. 30 turns that guarantee
into something CI enforces on every commit; until then it only holds as long as
someone remembers to run `make check`.

**Phase B — make the structure match the specification.** 24 (done), 25. The
specification says core and modules are separable and targets are plug-and-play.
The code says otherwise. This is the cheapest it will ever be to fix, because
there is exactly one target.

24 is done: `internal/generators/` is gone, generation lives entirely under
`modules/`, and the deterministic and LLM wrapper strategies share one driver so
they agree on file names and class names by construction. 25 is next.

**Phase C — remove counter-app-shaped assumptions.** 26, 27, 29. These are the
things that will produce wrong code, silently, on the second example.

**Phase D — grow capability.** 19, 20, 21, then 23. The existing roadmap, which
becomes safe to execute once A–C are done.

## The target that keeps this honest

`examples/task_app/` is a spec-only fixture whose README maps every one of its
constructs to the engine assumption it breaks. Phase C and D are done when
`metacode run` succeeds there.
