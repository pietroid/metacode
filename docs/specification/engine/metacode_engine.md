# Metacode Engine

This describes the engine working.

## Steps

### 1.Specs Parsing

_Goal: parse and verify the structure of the YAML Specs_

1. YAML syntax check: Usually done by YAML libraries.
2. Spec syntax check: each kind of Spec has it specific set of validity rules.
3. Symbol extraction: extract the symbols (names) that will be recognized against existing ones or created.

### 2. Internal representation construction

_Goal: identify symbols, correlate them, classify them_

1. Check symbols against catalog of existing symbols
2. Check validity of symbols (e.g. a certain UI component can have just specific members)
3. Create new symbols and classify them in which context they exist

### 3. Planning

_Goal: decide what will be generated, before anything is written_

1. Scan each scenario from behaviors and identify where each reference lives (UI, store, etc).
2. **One scenario becomes exactly one test, against the whole app.** A scenario is never broken down by layer. An earlier version of this document asked for the opposite — split a multi-layer scenario into unit tests — and that was wrong: a scenario that compiled down to a store unit test passed while the button that was supposed to call the store was wired to nothing. See `docs/decisions.md`, "One scenario, one test, against the whole app".
3. Plan the wrappers: one per page. A page's generated widget takes a callback for every event of every widget it embeds, so one wrapper at the top wires the whole screen.
4. The plan names work, not files. Where the work lands on disk and what its classes are called belong to the target language.

### 4. Execution

_Goal: Actually generate code and test it_

1. Execute the list from the planning based on a set of routines that instructs what should be done in each of the plannning steps.
2. Run all tests.
3. Fix tests until they pass.

## Some implementation notes

### Code conventions

- **A folder is a spec kind or a language, nothing else.** A spec kind has `rules/` for interpreting itself and `codegen/<language>/` for generating from itself. A new directory level needs a reason on one of those two axes.

  An earlier version of this document asked for a folder per pipeline step and a file per sub-step. That produced 25 packages for 6,000 lines, six of them named `flutter`, and a `modules/codegen/flutter/` sitting beside `modules/ui/codegen/flutter/` at the same depth meaning something different. See `engine/ARCHITECTURE.md` for the layout that replaced it.
- One package, one job, stated in its doc comment in a sentence.
- Comments carry the rule, not the history. A rule that cost something to learn gets an entry in `docs/decisions.md` and a one-line pointer at the code.
- Anything tied to a concrete spec or a concrete language lives with that spec or that language, never in `core/`. `core/` is what every spec and every language has in common.
- `make check` gates the tree: vet, tests, the golden example, zero unreachable code, and a complexity cap per function.

### Internal representation

- From step 2 we have definite objects that match their meaning: the project, its stores, its widgets, its scenarios, and the symbols and bindings resolved between them. They live in `core/model`, which imports nothing.
- The plan is deliberately not comprehensive. It carries identity only — this page needs a wrapper, this scenario needs a test. An earlier version of this document asked for objects connecting the spec, the program and "any other metadata necessary"; what that produced was a Task struct carrying three prose fields that were built on every run and read by nothing.

### Layered Architecture

Two axes, and the folders say which:

1. **Spec kind** — `specs/{project,data,ui}/` and `behavior/`, each with `rules/` and `codegen/<language>/`. Behaviors sit at the top level because they are the centerpiece: they are what the tests verify and what the implement stage is asked to satisfy.
2. **Target language** — `codegen/dart/` is the writing toolkit below every generator, `codegen/flutter/` is the step order. A second language is a sibling of both.

`core/` is what is common to every spec and every language: the model, spec loading, building, planning, and running. It never imports a generator; the pipeline reaches one through `run.Target`, assembled in `cmd/metacode`.

### Logging

Everything is passive to be logged as we want for now a very verbose process, to understand what is happening.

So consider everything that is communicated in any of metacode steps to be captured by the logs. The logger is a centralized class that takes care of spitting that out to the console. For now, it will do for everything.