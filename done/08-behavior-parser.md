# 08 — Behavior Parser

## Goal

Parse `behaviors.yaml` scenarios into structured `BehaviorScenario` objects with `given`, `when`, and `then` expressions.

## Scope

- Parse flat scenarios (grouping is deferred to a later milestone).
- Extract the three core fields:
  - `given`: a condition string like `counterStore.value is 5` (optional).
  - `when`: an event/action reference like `counterButton.onPressed` or `counterStore.increment`.
  - `then`: an assertion like `counterStore.value should be 6`.
- Store the scenario description (the YAML key) and a generated stable ID.
- Parse simple assertion forms:
  - `<symbol.path> should be <value>`
  - `<symbol.path> is <value>` (alias for `should be` in `given`)
- No nested groups, no tables, no parameterized cases yet.

## Acceptance criteria

1. Counter app behaviors parse into three scenarios with correct `given`, `when`, and `then` values.
2. Missing `when` is allowed and represented as empty string.
3. A behavior with neither `given` nor `when` (pure rendering assertion) parses correctly.
4. Malformed assertion syntax produces a clear error.
5. Unit tests cover the counter app and invalid cases.

## Files to create/modify

```
engine/internal/ir/
├── behavior_parser.go       # Parsing logic
└── behavior_parser_test.go
```

### Suggested types

```go
package ir

type Assertion struct {
    Target string // e.g. "counterStore.value"
    Op     string // "should be"
    Value  string // "6"
}

type BehaviorScenario struct {
    ID          string
    Description string
    GroupPath   []string
    Given       *Assertion
    When        string
    Then        *Assertion
}
```

## Layering notes

- Depends on: IR builder (behavior scenarios are stored on the IR).
- Enables: behavior planner, test generator, AI wrapper generator.
- Keep assertion parsing regex/simple-string based. A future milestone can replace it with a proper expression grammar.
- The `when` field is kept as a raw string for now; the planner will decide whether it is a UI event or a store action.
