# UI Spec

Every widget is declared under a single `widgets:` key at the top of ui.yaml. A
file without it is an error, not an empty app.

## Keys

- Each key is a widget or component
- A key can be a known word from the common ui vocabulary (stack, column, button) or can be a new word. 
- If it is a new word not declared anywhere else, it will be considered as a new symbol

## Values

Any key can contain (1) a direct child (2) a list of items or (3) a nested mapping

1.Direct child
```yaml
counterButton:
    button
```

2.List of items
```yaml
stack:
    - item1
    - item2
    - item3
```

3.Nested mapping
```yaml
button:
    label: "add"
    style: defaultStyle
```

(3) is always the internal representation of a key value pair because it is the most flexible for the case of ui.

(1) and (2) are syntax sugars for:

1
```yaml
counterButton:
    child:
        button
```

2
```yaml
stack:
    children:
        - item1
        - item2
        - item3
```

## Variables

Variables are what moves metacode. We can leave any name when we know the value of a widget to be dynamic:

```yaml
homePage:
    stack:
        - center:
            text:
                counterValue
```

counterValue in this case is a variable, because it is an unknown value.

The variables will be tied later in the tests and when the AI generates it.

A variable is typed by the prop it fills: `value: taskDone` on a checkbox is a
boolean, `onChanged: taskToggled` is a handler. See the prop types table in
ui_catalog.md.

A variable can also hold a widget rather than a value:

```yaml
homePage:
    scaffold:
        body: homeContent
```

What makes `homeContent` a widget is a behavior saying so, as in
`homePage.homeContent should be emptyState`. The UI spec alone cannot tell a
widget name from a value, and does not try to.

## Naming an event

A variable on a callback prop names that event, and that name is how a behavior
reaches it:

```yaml
addTaskButton:
    floatingActionButton:
        child:
            icon: icons.add
        onPressed: onAddTask
```

`addTaskButton.onAddTask` is the address of that button's onPressed. The name is
declared once, where the prop is, and it belongs to the widget that declares it
rather than to the catalog widget underneath.

## UI Catalog

The list of UI Catalog with all its internal specification is inside ui_catalog.md

## Dot notation

A behavior addresses an event on a widget three ways, and no others:

- by an alias, as above: `addTaskButton.onAddTask`
- by a callback prop of the widget's own root, which needs no alias because a
  widget has one root: `incrementButton.onPressed`
- by naming the catalog widget on the way, while that names exactly one widget
  inside: `controls.elevatedButton.onPressed`

An alias shadows the prop it names. Once onPressed is called `onAddTask`, the
address `addTaskButton.onPressed` is an error, because two names for one event
is how a spec starts disagreeing with itself.

A widget holding several buttons cannot be addressed by a path, since the path
does not say which button. Name the one you mean where it is declared:

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

Then `counterControls.onIncrement` and `counterControls.onDecrement` are both
unambiguous.

A row selector is not part of the address: `taskCheckbox.first.taskToggled` and
`taskCheckbox.last.taskToggled` are the same event, fired by different rows.