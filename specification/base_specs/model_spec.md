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