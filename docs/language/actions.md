# Actions

An action is something the app *does* rather than something it *holds*.
Pushing a route is one. Playing a sound and sending a notification will be.

The distinction matters because of how a scenario checks it. A value is
expected: the app settles, and you look at it. An action leaves nothing behind
to look at, so it is verified: the test records the calls the app made and
checks the one the scenario named happened.

```yaml
opening the sheet:
  when: addTaskButton.onAddTask
  then: navigator should push addTask
```

## The sentence

Every `then` is `<target> should <predicate>`, and there are two predicates.

**`be <value>`** is state. `counterStore.value should be 6` is the only kind of
`then` most specs need, and it reads exactly as it always did.

**A verb** is an action. `navigator should push addTask`, `navigator should
pop`. The subject comes first, the verb says what it did, and the argument, if
the verb takes one, comes last.

There is no negative form and there does not need to be one. Closing a sheet is
not the absence of opening it, it is a pop, which is a positive fact about a
different action.

## The subjects

Metacode ships these. A project cannot declare its own yet.

| Subject | Action | Takes | Means |
|---|---|---|---|
| `navigator` | `push` | a route name | the app moved to that route |
| `navigator` | `pop` | — | the app left the route it was on |

A route name has to be one `navigation.yaml` declares, checked the same way an
icon name is checked against the icon vocabulary. See
[navigation.md](navigation.md).

## Exactly once

`navigator should push addTask` means the app pushed that route once. Twice
fails.

That is deliberate, and it is the whole reason a verification is worth having:
a double push is the most common navigation bug there is, and a check that
passed on it would be checking almost nothing. There is no way to write "twice"
or "at least once" yet. Loosening it later is compatible with every spec
written under this rule; tightening it later would not have been.

## Where an action runs

An action needs a widget event to fire it:

```yaml
cancelling closes the sheet:
  given:
    navigator.route: addTask
  when: cancelButton.onCancel
  then: navigator should pop
```

A `then` naming an action with no `when` is an error. It would compile to a
test that starts the app and checks a call nobody made.

## An event can do both

An event that writes the store and moves the app is two scenarios about one
press, and that is the ordinary shape rather than a workaround:

```yaml
adding:
  saving appends the task:
    given:
      navigator.route: addTask
      taskStore.value: []
    when: saveTaskButton.onSaveTask
    then: taskStore.value.first.description should be "New task"

  saving closes the sheet:
    given:
      navigator.route: addTask
    when: saveTaskButton.onSaveTask
    then: navigator should pop
```

The store action comes from the first, the pop from the second, and the wrapper
runs them in that order: the sheet closes on work that is already done.

## Store actions and these

Both are called actions and they are different things, so both are always
qualified.

A **store action** is a method on your store. It is named by the spec, its body
is business logic, and the implement stage writes it. See
[ui.md](ui.md#naming-an-event).

A **navigator action** reaches outside the app. Its call is fixed by the table
above, and no model chooses it.
