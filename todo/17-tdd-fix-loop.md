# 17 — TDD Fix Loop

## Goal

When generated tests fail, feed the failure context back to the LLM and regenerate the wrapper or test code until the tests pass or a maximum iteration count is reached.

## Scope

- If the test runner reports failures:
  1. Build a fix task for each failure containing:
     - The failing test file and name.
     - The test source code.
     - The relevant wrapper/source files.
     - The failure message.
     - The original behavior scenario.
  2. Send a prompt to the LLM asking it to fix the code.
  3. Regenerate the affected file(s).
  4. Re-run `flutter test`.
  5. Repeat up to a configured maximum number of iterations (default 3).
- Stop early if all tests pass.
- If the loop exhausts iterations, report the remaining failures and exit with an error.

## Acceptance criteria

1. A deliberately broken wrapper is corrected by the fix loop and tests pass.
2. The loop respects the maximum iteration count.
3. Each iteration is logged with the failure summary.
4. Unit tests simulate failures and verify the loop invokes the LLM client the expected number of times.

## Files to create/modify

```
engine/internal/runner/
├── fix_loop.go         # Iterative fix logic
└── fix_loop_test.go
```

### Suggested API

```go
package runner

type FixLoop struct {
    MaxIterations int
    Runner        *TestRunner
    Client        llm.Client
    Generator     func(ctx context.Context, task planner.Task, code string) (string, error)
}

func (fl *FixLoop) Run(ctx context.Context, tasks []planner.Task) error
```

### Fix prompt guidelines

Include in every fix prompt:

- "The following Flutter test is failing."
- "Failing test: <test code>"
- "Failure message: <message>"
- "Current wrapper code: <wrapper code>"
- "Original behavior: <assertion>"
- "Fix the wrapper code so the test passes. Return only the corrected Dart code in a ```dart fence."

## Layering notes

- Depends on: test runner, LLM client, AI wrapper generator, planner.
- Enables: reliable end-to-end generation.
- The fix loop is the core of the non-deterministic TDD approach. Keep it isolated so deterministic parts never depend on it.
- Future improvements: only regenerate files that changed, use finer-grained diffs, add cost/iteration limits.
