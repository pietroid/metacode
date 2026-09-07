# UI Spec

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

## UI Catalog

The list of UI Catalog with all its internal specification is inside ui_catalog.md

## Dot notation

TODO: we will not need dot notation for this MVP, let's grab some examples later.