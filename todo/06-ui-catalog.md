# 06 — UI Catalog

## Goal

Encode the common UI vocabulary from `specification/base_specs/ui_catalog.md` so the engine can distinguish catalog widgets from custom symbols and validate allowed props.

## Scope

- Define a catalog data structure containing each symbol from `ui_catalog.md`.
- For each catalog symbol, store:
  - The Flutter widget name it maps to.
  - Its default content prop (`child`, `children`, `title`, `icon`, `data`, etc.).
  - A list of supported functional/layout props.
- Provide a lookup function `catalog.Find(name) (Symbol, bool)`.
- No styling props, no custom widget extensions yet.

## Acceptance criteria

1. `catalog.Find("text")` returns the Text widget mapping with default prop `data`.
2. `catalog.Find("column")` returns Column with default prop `children`.
3. `catalog.Find("unknownWidget")` returns `false`.
4. Unit tests assert that every symbol in `ui_catalog.md` is present in the catalog.

## Files to create/modify

```
engine/internal/catalog/
├── catalog.go        # Catalog struct and lookup
├── definitions.go    # Hard-coded catalog entries
└── catalog_test.go   # Tests
```

### Suggested API

```go
package catalog

type Symbol struct {
    Name           string
    FlutterWidget  string
    DefaultProp    string // "child", "children", "title", "icon", "data", etc.
    AllowedProps   []string
}

type Catalog struct {
    symbols map[string]Symbol
}

func New() *Catalog
func (c *Catalog) Find(name string) (Symbol, bool)
func (c *Catalog) IsKnown(name string) bool
```

## Layering notes

- Depends on: nothing (pure data).
- Enables: symbol resolution and UI validation.
- The catalog is intentionally hard-coded for the MVP. A future milestone can load it from a YAML/JSON file.
- Keep the list in sync with `specification/base_specs/ui_catalog.md`.
