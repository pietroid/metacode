# task_app — a target, not a working example

A spec-only fixture. There is no `lib/` and no `test/`, and `metacode run`
stops before generating anything. It exists so the next capability gaps are
written down as YAML someone can run, rather than as prose in a design doc.

For examples that work, see `counter_app` and `focus_app`.

## What the app would do

A task list with three stores: the tasks (persisted locally), the active
filter, and the text typed into the input. You type a title, press add, the
task appears; you tick a checkbox, it leaves the "open" filter; you kill the
app and the tasks are still there. Roughly the smallest app that is not a
counter.

## What stops it today

Run it and the resolve stage names the first blocker. In order:

**No namespace for app lifecycle.** `when: app.restart` has nothing to resolve
against; only stores and widgets are addressable.

**One event drives one store.** `addTaskButton.onPressed` clears the draft
*and* appends a task, and the binding resolver rejects the second store rather
than guessing. This is the multi-store gap: the engine supports one store per
project, and `app.Stores[0]` is load-bearing in several generators.

Beyond those two the specs are unverified, because the run never gets far
enough to find out.

## Running it

```bash
cd examples/task_app
go run ../../engine/cmd/metacode run
```

Expect it to fail. When it stops failing, the milestone is done.
