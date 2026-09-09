# 19 — Behavior Grouping Support

## Goal

Extend the behavior parser and planner to support nested scenario groups, flattening them into individual test cases.

## Scope

- Parse grouped behaviors where a scenario key contains a list of sub-scenarios.
- Support arbitrary nesting depth.
- Preserve the group path on each `BehaviorScenario`.
- Flatten groups into individual scenarios when generating tests.
- Include group path in generated test descriptions for clarity.

## Acceptance criteria

1. The grouped percentage example from `behaviors_spec.md` parses into 6 individual scenarios with correct group paths.
2. Generated test names include the group path (e.g. `Renders the correct color based on the percentage / for less than 30% / 0% case`).
3. Planner tasks reference the flattened scenario IDs.
4. Unit tests cover flat and nested groups.

## Files to create/modify

```
engine/internal/ir/
├── behavior_parser.go    # extend to recurse into groups
├── behavior.go           # BehaviorScenario.GroupPath already exists
└── behavior_parser_test.go

engine/internal/planner/planner.go  # handle grouped scenario IDs
engine/internal/generators/flutter/tests.go  # use group path in test names
```

## Layering notes

- Depends on: behavior parser, planner, test generator.
- Enables: more complex behavior specs without changing the IR shape (only `GroupPath` is populated).
- Keep flattening deterministic. Groups are a syntactic convenience, not a runtime construct.
- Future: parameterized groups (tables) can build on this structure.
