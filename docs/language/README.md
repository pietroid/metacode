# The Metacode spec language

Metacode generates a working app from a folder of YAML. This is the reference
for that YAML. You do not need to know Go, and you do not need to know how the
engine works, to write it.

## The idea in one page

A Metacode project has a `metacode/` folder holding four required files and
two optional ones:

```
metacode/
├── project.yaml     the app's name
├── data.yaml        what the app stores
├── models.yaml      the shapes it stores (optional)
├── ui.yaml          what is on screen
├── navigation.yaml  where the app can go (optional)
└── behaviors.yaml   what the app does
```

Every file is a set of **symbols**, and the symbols are shared. `ui.yaml`
declares a widget called `addTaskButton`; `data.yaml` declares a store called
`taskStore`; `behaviors.yaml` writes a sentence that uses both:

```yaml
adding a task appends it to the list:
  given:
    taskStore.value: []
  when: addTaskButton.onAddTask
  then: taskStore.value.first.description should be "New task"
```

That shared vocabulary is what separates a Metacode spec from a prompt. A
prompt describes an app in prose and hopes the reader agrees with you. A spec
names things, and a name that is not declared anywhere is an error, not a
guess.

## What happens to it

A run turns the specs into a Flutter app and a test suite, then checks its own
work:

1. Everything the specs literally say is generated **deterministically**. The
   same specs produce the same bytes, every time, with no model involved: the
   project, the models, the stores, the widgets, the wiring layer, and one test
   per scenario.
2. What is left is **behavior** — what a store action actually does, and which
   piece of state a widget displays. That is written by a language model, in
   one request that carries the whole spec and every generated test.
3. The suite runs. Failures go back to the model. When it is green, the app is
   done.

The tests are never handed to the model. They come from your scenarios, they
are regenerated from your scenarios on every run, and a model that could edit
them would have verified nothing.

## Running twice

The first run writes the whole app. The second one only writes what your edits
reached.

After every run, Metacode copies your spec files into `metacode/.lock/`. The
next run compares the two and works out which parts of the app your changes
touch. Rename a button and the wiring is rewritten. Change an appBar title and
nothing is: the widget is regenerated from the spec either way, and no model is
asked for anything. Edit one scenario and only the store and the widget that
scenario reaches are rewritten, while the rest stays as it is.

The generated tests are rebuilt from your scenarios on every run regardless,
and the whole suite runs on every run. If something you did not expect to break
breaks, the fix loop opens the whole app back up. The lock makes the common
case cheap; it never decides whether your app is correct.

Commit `metacode/.lock/` along with your specs, so a teammate who pulls your
branch gets the same short run you did.

To ignore it for one run, use `metacode run -regenerate`, or delete the
directory. Do that when the generated code and your specs have drifted apart in
a way the diff is clearly not seeing.

## Where to go next

| | |
|---|---|
| [behaviors.md](behaviors.md) | scenarios, given/when/then, grouping. **Start here.** |
| [ui.md](ui.md) | declaring widgets, variables, and event names |
| [catalog.md](catalog.md) | the widget and icon vocabulary |
| [navigation.md](navigation.md) | routes, and how each one appears |
| [actions.md](actions.md) | what the app does rather than holds, and how it is verified |
| [data.md](data.md) | stores |
| [models.md](models.md) | models and enums |
| [project.md](project.md) | the project file |

Complete examples live in `examples/counter_app`, `examples/focus_app` and
`examples/sheet_app`, the last of which is the one with routes.

## The one rule worth internalising

**Metacode cannot generate a behavior you did not describe.** If you never tie
the store to the screen, the screen will not show the store. If you never write
a scenario for the empty list, nothing decides what an empty list looks like.

That is a design decision, not a gap. The behaviors file is the specification,
so it deserves the time you would otherwise spend reviewing generated code.
