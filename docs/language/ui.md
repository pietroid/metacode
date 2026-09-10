# ui.yaml

The UI spec is a layout spec, with one deliberate omission: it has no logic in
it. Nothing here says what happens, only what is on screen and what parts of it
are not yet decided.

Every widget is declared under a single `widgets:` key. A file without it is an
error, not an empty app.

```yaml
widgets:
  homePage:
    scaffold:
      body: homeContent
      floatingActionButton: addTaskButton

  addTaskButton:
    floatingActionButton:
      child:
        icon: icons.add
      onPressed: onAddTask
```

## Keys

Each key is a widget. It is either a word from the catalog (`column`, `text`,
`scaffold` — see [catalog.md](catalog.md)) or a new word, in which case it is a
new symbol you have just declared and can refer to from anywhere else.

A top-level key whose name ends in `Page` is a page, and gets its own file
under `lib/pages/`. Everything else is a widget under `lib/widgets/`.

## Values

A key holds one of three things, and two of them are sugar for the third.

**A direct child**

```yaml
counterButton:
  elevatedButton
```

**A list of items**

```yaml
stack:
  - item1
  - item2
```

**A nested mapping**, which is the real internal form:

```yaml
elevatedButton:
  child: "Add"
  onPressed: onAdd
```

The first desugars to `child:` and the second to `children:`, using whichever
prop the catalog names as that widget's default content.

## Variables

A variable is what moves Metacode. Write any name where a value is not decided
yet:

```yaml
homePage:
  stack:
    - center:
        text: counterValue
```

`counterValue` is unknown, so it is a variable. What fills it is decided by the
behaviors and written by the implement stage.

**A variable's type comes from the prop it fills.** `value: taskDone` on a
checkbox is a boolean; `onChanged: taskToggled` is a handler; a bare name under
a text prop is text, because it renders as text. The prop types table is in
[catalog.md](catalog.md#prop-types). Nothing infers a type from the name.

**A variable can hold a widget:**

```yaml
homePage:
  scaffold:
    body: homeContent
```

What makes `homeContent` a widget is a behavior saying so:
`homePage.homeContent should be emptyState`. The UI spec cannot tell a widget
name from a value on its own, and does not try.

## Naming an event

A variable on a callback prop names that event, and the name is how a behavior
reaches it:

```yaml
addTaskButton:
  floatingActionButton:
    child:
      icon: icons.add
    onPressed: onAddTask
```

`addTaskButton.onAddTask` is now the address of that button's `onPressed`.

The name you choose also names the store action the event runs, so choose it
the way you would name a method. `onAddTask` becomes `addTask`. `taskToggled`
becomes `taskToggled`. A leading `on` is dropped and nothing else is guessed.

If you give no alias and address a raw catalog prop, the widget's own name has
to supply the verb: `incrementButton.onPressed` runs `increment`, because the
`Button` suffix says what the widget is and what is left says what it does.
Naming the event is the more reliable habit.

## Addressing an event

A behavior reaches an event three ways, and no others:

- **by an alias**: `addTaskButton.onAddTask`
- **by a callback prop of the widget's own root**, which needs no alias because
  a widget has one root: `incrementButton.onPressed`
- **by naming the catalog widget on the way**, while that names exactly one
  widget inside: `controls.elevatedButton.onPressed`

An alias shadows the prop it names. Once `onPressed` is called `onAddTask`, the
address `addTaskButton.onPressed` is an error, because two names for one event
is how a spec starts disagreeing with itself.

A widget holding several buttons cannot be addressed by a path, because the
path does not say which button. Name the one you mean, where it is declared:

```yaml
counterControls:
  row:
    - elevatedButton:
        child: "Increment"
        onPressed: onIncrement
    - elevatedButton:
        child: "Decrement"
        onPressed: onDecrement
```

Both `counterControls.onIncrement` and `counterControls.onDecrement` are now
unambiguous.

A row selector is not part of the address. `taskCheckbox.first.taskToggled` and
`taskCheckbox.last.taskToggled` are the same event on two rows.

Addressing something that is not there is an error. `addTaskButton.onWiggle`
used to generate a parameter nothing rendered, a button wired to nothing, and a
test that failed on a value.

## Lists

A `listView` is either static or dynamic.

Static means `children`, a list of widgets. Dynamic means `items`, the variable
holding the collection, plus `item`, the widget built once per element:

```yaml
defaultState:
  column:
    - text: "My tasks"
    - expanded:
        listView:
          items: taskList
          item: taskTile
```

The names follow the pair the spec already has: `child` is one widget,
`children` is many widgets, `items` is many values, `item` is the one widget
per value. There is no `itemCount`, because the count is the length of `items`
and saying it twice invites the two to disagree.

The row widget, and everything inside it, is built once per element and knows
which element it is. That is what makes `taskTile.first` addressable from a
behavior, and what lets a checkbox inside the row toggle its own task.

## What is not here

Styling is deliberately absent: no `style`, `theme`, `color`, or `elevation`.
Layout and structure are specified; appearance is not, yet.
