# behaviors.yaml

Behaviors are the centerpiece of Metacode. Everything else exists so a scenario
has names to refer to.

A behavior is not an integration test and not a unit test. It describes what
the app does, at the surface: an event goes in, a value comes out. It never
mentions a class, a layer, or a method. "The counter increments when the button
is pressed" is a behavior; "CounterCubit.increment emits state+1" is an
implementation detail, and Metacode is the thing that decides implementation
details.

Each scenario becomes exactly one test, and that test drives the whole app the
way a user would.

## A scenario

```yaml
When counterButton is pressed, it should increment the counter:
  given:
    counterStore.value: 5
  when: counterButton.onPressed
  then: counterStore.value should be 6
```

The key is free text. It never appears in the generated code as anything but a
test name and a comment, so write it for a human. It is also what the model
reads when it implements the behavior, so a vague description costs you.

The three lines under it are the deterministic part:

**`given`** is the state the scenario starts from. It is a mapping of a target
to the value it holds, so the colon is the operator and the value stays YAML. A
list or a mapping is written as one:

```yaml
show the tasks that are already in the store:
  given:
    taskStore.value:
      - description: "Buy milk"
        done: false
      - description: "Call mom"
        done: true
  when: # always
  then: taskTile.last.taskTitle should be "Call mom"
```

A value the store's type cannot hold is an error, not a coercion. Seeding
`"[]"` into a list store used to produce a test that ran, passed, and checked
nothing.

**`when`** is the event that happens. Leave it empty (`when: # always`) for a
scenario about what is on screen rather than about something a user did.

**`then`** is the expectation, written `<target> should be <value>`. That is
the only operator; `is` and `=` read the same way.

## Addressing things

A target is a dotted path rooted in a symbol you declared.

**A store field.** `counterStore.value`, `taskStore.value.first.done`.

**A widget variable.** Always through the widget that renders it:
`homePage.counterValue`. A bare `counterValue` is undefined, because two
widgets may each have one.

**A row.** `.first` and `.last` address one element, both in a stored list and
in the widget a list builds one of per element:

```yaml
then: taskStore.value.first.done should be true
then: taskTile.last.taskTitle should be "Call mom"
when: taskCheckbox.first.taskToggled
```

`last` is read from the given, because the given is what the screen is showing.
A `last` with no list in the given is an error.

**A count.** `<widget>.count` asks how many rows a list rendered:

```yaml
then: taskTile.count should be 3
```

**A widget.** When the value of a `then` names a widget, the scenario asserts
that widget is on screen. This is how you specify which of two layouts shows:

```yaml
show the empty state when there are no tasks:
  given:
    taskStore.value: []
  when: # always
  then: homePage.homeContent should be emptyState
```

That scenario is also what tells the UI spec that `homeContent` holds a widget
rather than a string. `ui.yaml` alone cannot tell those apart, and does not
try.

A path may go two segments deep, plus one more if a row selector is in it.
`taskStore.value.first.done` is the deepest thing you can write.

## Events

`when` names an event on a widget. How that event is addressed is decided in
`ui.yaml`, and there are exactly three forms. See [ui.md](ui.md#naming-an-event).
The short version: name your events, and address them by the name you gave.

```yaml
when: addTaskButton.onAddTask      # an alias declared on the prop
when: incrementButton.onPressed    # a callback prop of the widget's own root
when: taskCheckbox.first.taskToggled  # the same alias, on one row
```

A row selector is not part of the event. `taskCheckbox.first.taskToggled` and
`taskCheckbox.last.taskToggled` are one event fired by two different rows.

`when` can also name a store action directly, `counterStore.decrement`, for a
rule with no UI behind it.

## Grouping

A group is a key whose value is more scenarios. It exists so a rule with many
cases reads as one rule:

```yaml
toggling:
  toggling a row marks its task done:
    given:
      taskStore.value:
        - description: "Buy milk"
          done: false
    when: taskCheckbox.first.taskToggled
    then: taskStore.value.first.done should be true

  toggling a row twice returns it to open:
    given:
      taskStore.value:
        - description: "Buy milk"
          done: true
    when: taskCheckbox.first.taskToggled
    then: taskStore.value.first.done should be false
```

A group can also be a list, which reads better when the cases are variations of
one sentence:

```yaml
When counterButton is pressed, it should increment the counter:
  - case for 0:
      given:
        counterStore.value: 0
      when: counterButton.onPressed
      then: counterStore.value should be 1
  - case for 1:
      given:
        counterStore.value: 1
      when: counterButton.onPressed
      then: counterStore.value should be 2
```

Groups nest as deep as you like. Only the leaves are scenarios, and the path to
a leaf becomes its identity, so two groups may reuse a case name.

Grouping matters more than it looks. Scenarios that share an event describe one
piece of behavior under different preconditions, and the model is shown all of
them together. "Does not go below zero" is only visible if the case at zero
arrives beside the cases above it.

## Writing scenarios that work

**Cover the surface, not the machinery.** Name the event and the outcome.
Anything between them is Metacode's problem.

**Be concrete.** A scenario has literal values in it. That is what makes it a
test rather than a wish.

**Describe the rule, not just the example.** The model is told to implement the
behavior the scenarios describe, not only the numbers they check, and the
description you wrote is how it knows the difference between "returns 0 here"
and "never goes below zero".

**Two scenarios cannot share a file name.** Names become file names, so two
scenarios that slug to the same token are an error rather than a silent
overwrite. Rename one.
