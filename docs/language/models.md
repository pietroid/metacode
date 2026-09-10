# models.yaml

Models are how the app describes the shapes it stores. The file is optional: a
project whose stores hold primitives does not need one.

## Primitives

`string`, `boolean`, `number` (integer or double), `datetime`, `list`.

## Declaring a model

```yaml
user:
  name: string
  age: number
  gender: gender
  partner: user?
  children: list(user)?
```

- each field is a key/value pair
- a value may be a primitive, another model, or an enum
- `?` marks a field optional
- `list(<type>)` is a collection of that type

## Enums

```yaml
gender:
  - male
  - female
```

## What you get

Each model becomes a class holding its fields, with `copyWith` and value
equality. Each enum becomes an enum. A field marked `?` is nullable and not
required by the constructor; every other field is required.

A store declaring `list(task)` therefore holds `List<Task>`, and a scenario
seeding one writes the fields it wants:

```yaml
given:
  taskStore.value:
    - description: "Buy milk"
      done: false
```

Seeding a field the model does not declare, or leaving out one it requires, is
an error that names the scenario.
