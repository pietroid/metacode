# data.yaml

A store is where a piece of state lives. Everything the app remembers is in one.

```yaml
stores:
  taskStore:
    value: list(task)
    initialValue: []
    strategy: local
```

| Key | Meaning |
|---|---|
| `value` | the type it holds: a primitive, a model, or `list(<type>)`. Same vocabulary as [models.md](models.md). |
| `initialValue` | what it holds before anything happens. Must match `value`. |
| `strategy` | where it lives. |

## Strategies

| | |
|---|---|
| `ephemeral` | memory only, gone when the app closes |
| `local` | preserved on the device |
| `remote` | preserved in a database on a server |

## Actions

A store's actions are not declared here. They come from the behaviors:

- a widget event bound to the store gives the store an action named after that
  event, as described in [ui.md](ui.md#naming-an-event)
- an explicit `when: taskStore.someAction` in a scenario declares one directly

What the action does is business logic, so no generator writes it. The
signature is derived from the spec and the body is written by the implement
stage, from the scenarios that specify it. Those scenarios are quoted above the
method in the generated code, so the requirement and the implementation sit in
one place.

An action run by a widget that is rendered once per row takes the row: a
checkbox inside a list gives its store `void taskToggled(int index)`, because
the wrapper of a row already knows which row it is.

## One store, for now

The engine currently supports one store per project, and says so at the resolve
stage rather than generating something that half works. Multiple stores are a
planned change.
