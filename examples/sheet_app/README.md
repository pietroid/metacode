# sheet_app — routes, and a bottom sheet

The smallest app that needs `navigation.yaml`. A list of tasks on one
route, an add form on another, and the add form is a bottom sheet because the
route table says so and for no other reason.

## What it shows

**A route is a destination, not a widget.** `addTaskSheet` is an ordinary
widget in `ui.yaml` and says nothing about how it appears. `navigation.yaml`
says it is a `bottomSheet`, and that is the only place the word occurs.

**An action is verified, not expected.**

```yaml
pressing add opens the sheet:
  when: addTaskButton.onAddTask
  then: navigator should push addTask
```

There is no state to look at afterwards, so the generated test records the
pushes the app made and checks this one happened exactly once.

**Closing is a pop, not the absence of an open.** `navigator should pop` is a
positive fact about a different action, which is why the language needs no
negative form.

**A given can say where the app starts.** A scenario about a button inside the
sheet needs the app to be in the sheet, and seeding a store cannot put it
there:

```yaml
saving appends the task to the list:
  given:
    navigator.route: addTask
    taskStore.value: []
```

**One press can do both.** `saveTaskButton` writes the store and closes the
sheet, which is two scenarios about one event, and the wrapper runs them in
that order.

## Running it

```bash
cd examples/sheet_app
go run ../../engine/cmd/metacode run
```

Seven scenarios, seven tests, all green.

With no API key the run stops before the implement stage and runs the suite
anyway. Four of the seven pass from the scaffold alone, and every navigation
scenario is among them: a push and a pop are spelled by the spec, so no model
is asked for either. What needs the implement stage is what always does — the
body of the store action, and which of the two layouts the page shows.
