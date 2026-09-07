# 05b — Layered Architecture Refactor

## Goal

Restructure the engine internals to match the layered architecture described in `specification/engine/metacode_engine.md`:

- **Core**: generic, spec-agnostic engine machinery (logging, spec parsing, internal representation).
- **Modules**: concrete spec/code-generation rules and target-specific implementations (Flutter generators, UI catalog, LLM integrations, etc.).

## Scope

- Move `internal/log`, `internal/spec`, and `internal/ir` under `internal/core/`.
- Create `internal/modules/` with a Flutter module root (`internal/modules/flutter/`) and a small placeholder so the package tree is established.
- Update all imports in `cmd/metacode`, `internal/cli`, and tests.
- Add/update `package` comments and short file headers explaining the layer.
- No functional behavior change; this is a pure reorganization.
- No generator implementation yet.

## Acceptance criteria

1. `go test ./...` passes after the move.
2. `go run ./cmd/metacode run` from `examples/counter_app` still discovers, parses, and builds the IR.
3. Directory layout clearly separates core from modules:
   ```
   engine/internal/
   ├── cli/
   ├── core/
   │   ├── log/
   │   ├── spec/
   │   └── ir/
   └── modules/
       └── flutter/
   ```
4. New code follows the convention of a primary exported function per file orchestrating helpers.

## Files to create/modify

- Move:
  - `engine/internal/log/*` -> `engine/internal/core/log/*`
  - `engine/internal/spec/*` -> `engine/internal/core/spec/*`
  - `engine/internal/ir/*` -> `engine/internal/core/ir/*`
- Create:
  - `engine/internal/modules/flutter/module.go`
- Modify:
  - `engine/cmd/metacode/main.go`
  - `engine/internal/cli/run.go`
  - all test files with moved imports

## Layering notes

- Depends on: todos 01–05.
- Enables: UI catalog, Flutter generators, LLM client, and planner modules to live under `internal/modules/` without polluting the core.
- This refactor intentionally does not change logic; it only renames package paths and adds package-level documentation.
