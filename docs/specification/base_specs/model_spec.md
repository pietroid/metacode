# Model Spec

The models are the foundation for data representation in any system.

We have the following primitives:

- string
- boolean
- number (integer or double)
- datetime
- list

## Declaring a model

A model is declared inside models.yaml by its name.

```yaml
user:
    name: string
    age: number
    gender: gender
    partner: user?
    children: list(user)?
```

- each field is declared as a key value pair
- not only primitives but other models can be used as values
- non-required fields are followed by ?
- list types are explicited by ()

## Enums

In the example, a gender enum was used. Enums are declared the following way:

```yaml
gender:
    - male
    - female
```

## What is generated

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
an error naming the scenario.
