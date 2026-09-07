# 07 — Symbol Resolution

## Goal

Cross-reference all named symbols from the four specs, classify them, and report undefined or conflicting names.

## Scope

- Build a `SymbolTable` from the IR:
  - Stores declared in `data.yaml`.
  - UI symbols declared as top-level keys in `ui.yaml`.
  - Catalog widgets referenced inside UI trees.
  - Variables discovered as bare unknown names inside UI trees.
  - Actions referenced in behaviors (e.g. `counterStore.increment`, `counterButton.onPressed`).
- Validate that every symbol referenced in a behavior exists in the symbol table.
- Validate that UI component props match the catalog's allowed props.
- For the counter app, resolve:
  - `counterStore` -> store
  - `homePage`, `counterButton` -> widgets
  - `counterValue` -> variable (to be bound to `counterStore.value`)
  - `counterButton.onPressed` -> event reference
  - `counterStore.increment` -> store action
  - `counterStore.value` -> store field access

## Acceptance criteria

1. Counter app symbols resolve without errors.
2. A behavior referencing an undefined store produces a clear error.
3. A UI component using an unknown prop produces a warning or error.
4. The symbol table is exposed on the IR for generators to use.
5. Unit tests cover success and error cases.

## Files to create/modify

```
engine/internal/ir/
├── resolver.go       # Resolution logic
├── resolver_test.go
└── symbol.go         # SymbolTable type (already introduced)
```

### Suggested API

```go
package ir

func (ir *IR) Resolve(catalog *catalog.Catalog) error

type SymbolTable struct {
    Stores   map[string]Store
    Widgets  map[string]UIComponent
    Actions  map[string]ActionRef // e.g. "counterStore.increment"
    Events   map[string]EventRef  // e.g. "counterButton.onPressed"
    Variables map[string]VariableRef
}
```

## Layering notes

- Depends on: IR builder, UI catalog.
- Enables: deterministic generators and behavior planner.
- Keep expression parsing simple for MVP. Support only dot-notation chains of depth 1 or 2 (e.g. `store.action`, `widget.event`, `store.field`).
- Deeper dot notation and method arguments are deferred.
