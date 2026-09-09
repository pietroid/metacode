# Decisions

Why the engine works the way it does. Each entry is a rule that cost something
to learn, kept here so the code can state the rule in a line and point at the
story rather than retelling it in a doc comment.

Dates are when the decision was recorded, not when the code changed.

---

## 2026-09-08 — One scenario, one test, against the whole app

A scenario is never split by layer. Whatever its trigger, it becomes exactly one
test that pumps the composed page and drives it the way a user would.

Scenarios used to compile down to a Cubit unit test when their trigger was a
store action. Those tests passed while the button that was supposed to call the
Cubit was wired to nothing, so the suite was green and the app was dead.

Code: `behavior/codegen/flutter/testcase.go`, `core/plan/build.go`.

## 2026-09-08 — Ask once, with everything

The implement stage makes one request carrying the whole spec, every generated
test, and every file the model may write. Each repair iteration is one more
request carrying every failure at once.

Generating a wrapper at a time and then repairing a test at a time meant a
seven-scenario counter app made seventeen requests, each seeing one slice of the
problem. That is how the counter Cubit came back with placeholder `increment`
and `decrement` bodies: the request that wrote it had never been shown the tests
those methods had to satisfy. Repairing one failure at a time was worse — each
fix overwrote the file the previous one had just repaired, without seeing why.

Code: `behavior/codegen/flutter/implement.go`.

## 2026-09-08 — A wrapper composes the dumb widget; it does not re-render it

A wrapper instantiates the generated widget and passes the values and callbacks
that reach the store. The generated page already exposes a parameter per
variable and a parameter per event of every widget it embeds, put there for
exactly this purpose.

The deterministic wrapper generator used to walk the UI spec a second time and
rebuild the Scaffold, the Column and every child: 372 lines that were a near
copy of the widget renderer, so both had to agree about every widget in the
catalog. With an API key configured the model then threw all of it away and
wrote the twenty-line composition instead. Removing it also removed the wrapper
per button, which nothing could reference — a page instantiates its own
children, so it could never use them.

Code: `behavior/codegen/flutter/wrappers_render.go`.

## 2026-09-08 — Where a generated file goes is decided once

Paths and class names for generated code come from `codegen/dart`'s layout
rules. Nothing else restates them.

Six places used to each rebuild a piece: the planner wrote wrapper paths, the
pruner rebuilt them to decide what was stale, the implementer rebuilt them again
to decide what it owned, and the test builder rebuilt the import paths a third
time. Any two of them drifting produced a test importing a file nothing had
written.

Code: `codegen/dart/layout.go`.

## 2026-09-08 — The action a widget event runs comes from the spec, not from the values

`decrementButton.onPressed` runs `decrement`, read off the widget's name.

It used to be guessed by parsing the scenario's given and then values as
integers and comparing them. That works for counters and silently mislabels
everything else: every button on a non-numeric store was named `increment`.

Code: `behavior/rules/binding.go`.

## 2026-09-08 — A store action body is business logic, so a generator does not write it

The scaffolded Cubit declares its methods and throws `UnimplementedError`. The
bodies come from the behavior scenarios through the implement stage.

Hardcoding `increment` and `decrement` in the generator made the counter app
work and made every other app quietly wrong. It also pushed real rules into the
wrapper layer, where a generated wrapper reached through `cubit.emit` because
the Cubit had no method to call. Nothing is inferred from the store's type
either: a default `increment` on every numeric store put a method on the Cubit
that no scenario asked for, and hid the absence of the ones that were.

Code: `specs/data/codegen/flutter/store.go`.

## 2026-09-08 — A test with no interaction is not a test

An event with no known tester idiom is an error. A scenario whose `then` names
neither a store nor a widget is an error.

Both used to fall back to something. An unknown event produced an empty action,
so the test pumped the widget and asserted without ever interacting — it passed
whenever the initial state happened to match, and reported the scenario as
covered. An unresolvable `then` fell back to the store's value, writing a test
that asserted something the scenario never mentioned.

Code: `behavior/codegen/flutter/testcase_build.go`.

## 2026-09-08 — Find widgets by key, not by type

Generated widgets carry `key: Key("<name>")`, and generated tests find them that
way.

Finding by Flutter type fails the moment a page has two buttons: `tap()` reports
"ambiguously found multiple matching widgets" and every tap scenario in the spec
fails at once.

Code: `behavior/codegen/flutter/testcase_build.go`.

## 2026-09-08 — Generated output is marked, and stale output is pruned

Every generated file opens with `GENERATED BY METACODE`. After generation, files
under the directories this engine owns that carry the marker and were not
produced by this run are deleted.

Generation only ever wrote files, so renaming a widget or a scenario left the
old output on disk. Stale test files kept running and kept failing, which is how
one renamed widget turned into a list of failures for scenarios that no longer
existed. The marker is what makes the deletion safe: a hand-written file in the
same directory survives.

Code: `codegen/dart/prune.go`.

## 2026-09-08 — The bracket check has to read comments

The shape check applied to model output skips comments and string literals
before counting brackets.

A doc comment reading "seed a scenario's Given state" opens a string that never
closes, and every bracket after it stops counting. A correct file came back from
the model, failed the check, and was silently discarded three times in a row,
while the run reported the scaffolded placeholder as the model's work. A discard
is now logged as an error, because it means the model did the work and the
engine threw it away.

Code: `codegen/dart/validate.go`.

## 2026-09-08 — Map iteration is sorted everywhere it can reach output

Any map walk that can reach generated code, a warning, or planned work is
ordered.

Go randomizes map iteration on every execution, so an unordered walk produces
different bytes from identical specs. Reproducible output is what makes
generated files reviewable in a diff, and it is a precondition for the
lock-and-diff optimization.

Code: `order/order.go`.

## 2026-09-08 — Scenario names are prose, so file names are slugs

A scenario ID becomes a file name through one slug rule.

Leaving the prose in produced test files like `not decrements when is 0_test.dart`,
which every tool that takes a path had to be careful with, and which the Flutter
test output parser could not read back.

Code: `codegen/dart/layout.go`.

## 2026-09-08 — One target, assembled in cmd, behind a struct of functions

`run.Target` carries the generation stages, the implement constructor and the
test command. `cmd/metacode` is the only place that names Flutter.

It is a struct rather than an interface because there is one target today: an
interface would add a method set, a constructor and a name method without adding
a second implementation. Adding a language means writing a sibling assembly.
Three interfaces that did have exactly one implementation each — the wrapper
generator, the verifier, and the stage reporter — were removed for the same
reason. `Target.validate` exists because a stage left unset is a nil call in the
middle of a run: adding `NewImplementer` to the struct and forgetting it in the
assembly panicked with a line number instead of a name.

Code: `core/run/target.go`, `cmd/metacode/main.go`.
