# Metacode Implementation Overview

This folder contains the incremental implementation plan for Metacode. Each numbered markdown file is a self-contained milestone that produces a verifiable piece of functionality. Milestones are designed to layer on top of each other without rewriting earlier code.

## Goal

A Go CLI (`metacode run`) that, when invoked inside a Flutter project containing a `metacode/` spec folder, parses the YAML specs and generates a working Flutter application driven by behavior specs. The first end-to-end target is the counter app example from the README.

## Tech stack

- **Engine**: Go 1.22+
- **Target runtime**: Flutter SDK (assumed installed on the host)
- **Target state management**: `flutter_bloc` + `equatable`
- **LLM**: Configurable OpenAI-compatible HTTP client; defaults to the same model class as OpenCode (`opencode-go/kimi-k2.7-code`)
- **LLM config**: read from environment variables
  - `METACODE_LLM_BASE_URL`
  - `METACODE_LLM_API_KEY`
  - `METACODE_LLM_MODEL`

## Repository layout (planned)

```
metacode/
├── engine/                          # Go implementation
│   ├── cmd/metacode/                # CLI entry point
│   ├── internal/
│   │   ├── cli/                     # Command handling
│   │   ├── log/                     # Logger and progress reporter
│   │   ├── spec/                    # Spec discovery and parsing
│   │   ├── ir/                      # Internal representation
│   │   ├── catalog/                 # UI catalog definitions
│   │   ├── generators/flutter/      # Flutter code generators
│   │   ├── planner/                 # Generation planning
│   │   ├── llm/                     # LLM client
│   │   └── runner/                  # Test runner and TDD loop
│   └── go.mod
├── examples/
│   └── counter_app/                 # MVP example
│       ├── pubspec.yaml
│       └── metacode/
│           ├── project.yaml
│           ├── data.yaml
│           ├── ui.yaml
│           └── behaviors.yaml
├── specification/                   # Existing spec docs
└── todo/                            # This folder
```

## Phases

1. **Engine foundation** — bootstrap, YAML parsing, internal representation, validation.
2. **Deterministic Flutter generation** — project scaffold, stores, dumb UI widgets.
3. **LLM-driven behavior wiring** — plan and generate code that connects UI to stores using behaviors.
4. **Testing and TDD loop** — generate tests, run `flutter test`, and iterate on failures.
5. **MVP verification** — generate the counter app end-to-end and verify all tests pass.
6. **Advanced features** — behavior grouping, model specs, store strategies, navigation, lock/diff.

## Success criteria for MVP

Running the following command inside `examples/counter_app/`:

```bash
metacode run
```

must:

1. Parse all specs without errors.
2. Generate a valid Flutter project under `lib/` and `test/`.
3. Generate unit/widget tests that encode the behavior specs.
4. Run `flutter test`.
5. Have all tests pass (after the TDD fix loop, if needed).

## How to read these todos

- Each todo has a **Goal**, **Scope**, **Acceptance criteria**, **Files to create/modify**, and **Layering notes**.
- "Scope" defines what is included; everything outside the scope is explicitly deferred.
- "Layering notes" explain what the milestone depends on and what it enables.
- Later milestones may extend types introduced earlier, but they should not force redesigns of earlier milestones.
