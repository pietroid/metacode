# 13 — Behavior Planner

## Goal

Analyze the resolved IR and produce a concrete generation plan for the AI wrapper layer. The plan tells the engine which files the LLM needs to generate and what each file must satisfy.

## Scope

- For each behavior scenario, determine:
  - What is being tested (store action, UI rendering, UI-to-store wiring).
  - Which files are involved.
  - What deterministic code already exists (cubit, dumb widget).
  - What wiring code is missing (BlocProvider, BlocSelector, BlocBuilder, callback injection).
- Produce a list of `GenerationTask` objects, each with:
  - Task type: `wrapper`, `test`, `fix`.
  - Target file path.
  - Prompt context: relevant spec snippets, generated code, behavior assertion.
  - Acceptance criteria derived from the behavior assertion.
- For the counter app, produce tasks such as:
  - Wrap `HomePage` with a `BlocSelector<CounterCubit, CounterState, int>` that passes `counterValue`.
  - Provide a `FloatingActionButton` wrapper that calls `context.read<CounterCubit>().increment()`.
  - Generate a widget test that verifies the counter increments when the button is tapped.

## Acceptance criteria

1. Counter app IR produces at least one wrapper task and one test task.
2. Each task references the exact behavior scenario ID and assertion.
3. Tasks are ordered: wrappers before tests.
4. Unit tests assert the plan contains expected task types and file paths.

## Files to create/modify

```
engine/internal/planner/
├── planner.go        # Planning logic
├── task.go           # Task types
└── planner_test.go
```

### Suggested API

```go
package planner

type TaskType string

const (
    TaskWrapper TaskType = "wrapper"
    TaskTest    TaskType = "test"
    TaskFix     TaskType = "fix"
)

type Task struct {
    ID              string
    Type            TaskType
    TargetFile      string
    ScenarioID      string
    Description     string
    PromptContext   string
    ExpectedOutcome string
}

func Plan(ir *ir.IR) ([]Task, error)
```

## Layering notes

- Depends on: IR, symbol resolution, behavior parser.
- Enables: AI wrapper generator and test generator.
- The planner is intentionally deterministic. It does not call the LLM; it only describes what the LLM should do.
- Later milestones can extend tasks with dependency graphs and parallel execution hints.
