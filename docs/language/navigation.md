# navigation.yaml

The route table: where the app can go, what each destination shows, and how it
appears. It is optional. A project without it is one page, and `ui.yaml`
already names it.

```yaml
initialRoute: home

routes:
  home:
    child: homePage
    type: page

  addTask:
    child: addTaskSheet
    type: bottomSheet
```

## What a route is

A route has three parts and no more.

**Its name** is the key, and it is how everything else reaches it. A behavior
writes `navigator should push addTask`; nothing writes a path or a URL.

**`child`** names a widget from `ui.yaml`. It is an ordinary widget, declared
the way every other widget is, and it knows nothing about being a destination:

```yaml
addTaskSheet:
  column:
    - text: "New task"
    - saveTaskButton
    - cancelButton
```

**`type`** is how the destination appears: `page`, `bottomSheet` or `dialog`.
It is required. A default would be the one thing the route table exists to say,
guessed.

That split is the point. A widget is a widget, and the same one is a sheet in
this app and a page in the next one without a single behavior changing. It is
also why `bottomSheet` appears here and nowhere else: not in `ui.yaml`, which
has no logic in it, and not in a scenario, which says where the app went and
not what the destination looked like on the way.

## initialRoute

Where the app opens. It is required once you declare routes, and it has to name
a `page`: a sheet and a dialog are shown over something, so an app that opened
on one would have a barrier with nothing behind it and nothing to go back to.

## Getting there

Moving between routes is behavior, so it lives in `behaviors.yaml`:

```yaml
pressing add opens the sheet:
  when: addTaskButton.onAddTask
  then: navigator should push addTask

cancelling closes it:
  given:
    navigator.route: addTask
  when: cancelButton.onCancel
  then: navigator should pop
```

`push` and `pop` are actions, not values. See [actions.md](actions.md) for what
that means and how they are verified.

## Starting somewhere else

A scenario about a button inside a sheet needs the app to be in the sheet, and
seeding a store cannot put it there. A `given` says where the app starts:

```yaml
saving appends the task:
  given:
    navigator.route: addTask
    taskStore.value: []
  when: saveTaskButton.onSaveTask
  then: taskStore.value.first.description should be "New task"
```

The generated test drives the app to that route the way a user would, then
starts the scenario. Getting there is setup, so it does not count as behavior:
a scenario that starts on `addTask` and then asserts one push is asserting the
push its own event made.

`navigator.route` is the one target a given can name beside a store, and the
route it names has to be one the table declares and not the one the app
already opens on.

## What the engine does with it

`lib/navigation/router.dart` is generated from this file on every run: a
[go_router](https://pub.dev/packages/go_router) route per entry, with the page
class that matches its type. Nothing else in the tree decides how a sheet is
shown, and no model writes any of it. What a model writes is the push, in the
wrapper of the widget whose event runs it.

## What is not here yet

**Parameters.** `push taskDetail` cannot say which task. Pass what a
destination needs through the store for now.

**Anything under a route.** Nesting, guards, redirects and deep links are all
absent. Every route is top level, and `push` stacks it over what is already
there.
