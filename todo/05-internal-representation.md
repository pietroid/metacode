# 05 — Internal Representation

## Goal

Define typed domain objects that represent the parsed specs. These objects are the single source of truth for all later generators and planners.

## Scope

Define Go structs for:

- `Project` — name, description.
- `Store` — name, value type, initial value, strategy (`ephemeral` only for MVP).
- `Model` and `Enum` — declared but only parsed enough to detect their absence in MVP; full generation deferred.
- `UIComponent` — symbol name, kind (catalog vs. custom), props, children, variables referenced.
- `BehaviorScenario` — description, optional parent group path, `given`, `when`, `then` expressions.
- `BehaviorGroup` — nested groups of scenarios.
- `SymbolTable` — registry of all declared symbols (stores, widgets, actions) and their kinds.

Build a constructor that converts `RawSpecs` into the IR for the counter app. Full model/group support is deferred to later milestones.

## Acceptance criteria

1. Counter app raw specs convert into a populated IR with one project, one store, two UI components (`homePage`, `counterButton`), and three scenarios.
2. The IR can be printed for debugging without panicking.
3. Unknown top-level keys in specs produce warnings (not errors yet).
4. Unit tests cover counter app IR construction.

## Files to create/modify

```
engine/internal/ir/
├── project.go
├── store.go
├── model.go          # declarations only for MVP
├── ui.go
├── behavior.go
├── symbol.go
├── builder.go        # converts RawSpecs -> IR
└── builder_test.go
```

### Suggested types

```go
type Project struct {
    Name        string
    Description string
}

type Store struct {
    Name         string
    ValueType    string
    InitialValue any
    Strategy     string
}

type UIComponent struct {
    Name      string
    Kind      string        // catalog symbol or custom
    Props     map[string]any
    Children  []UIComponent
    Variables []string      // bare unknown names discovered in this subtree
}

type BehaviorScenario struct {
    ID          string
    Description string
    GroupPath   []string
    Given       string
    When        string
    Then        string
}

type Symbol struct {
    Name string
    Kind string // "store", "widget", "action", "variable"
}

type IR struct {
    Project    Project
    Stores     []Store
    Models     []Model
    UI         []UIComponent
    Behaviors  []BehaviorScenario
    Symbols    SymbolTable
}
```

## Layering notes

- Depends on: YAML parsing.
- Enables: catalog validation, symbol resolution, behavior parsing, and all generators.
- This is the most important layering milestone. Take time to get the types right, even if fields are added later.
- Store strategy is restricted to `ephemeral` for the MVP; the field exists so local/remote can be added later without redesign.
