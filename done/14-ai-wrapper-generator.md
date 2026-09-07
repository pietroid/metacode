# 14 — AI Wrapper Generator

## Goal

Use the LLM to generate the wiring layer that connects dumb UI widgets to Cubits so that behavior specs are satisfied.

## Scope

- For each `wrapper` task from the planner:
  - Build a detailed prompt containing:
    - The relevant behavior scenario.
    - The generated Cubit and state classes.
    - The generated dumb widget code.
    - Instructions to produce a single Dart file that wires them together.
  - Call the LLM client.
  - Parse the response and write the generated Dart file to the target path.
- Generated wrappers should:
  - Provide cubits via `BlocProvider` or `BlocProvider.value`.
  - Use `BlocSelector` or `BlocBuilder` to pass state slices into dumb widgets.
  - Inject stable callbacks (no closures capturing mutable state in `build`).
  - Keep widgets stateless.
- For the counter app, generate a wrapper that makes `HomePage` reactive and wires `CounterButton.onPressed` to `CounterCubit.increment()`.

## Acceptance criteria

1. Wrapper generator processes each `wrapper` task and writes a Dart file.
2. Generated wrapper compiles alongside deterministic files.
3. Running the Flutter app (manually or via widget tests) shows the counter value and increments on button tap.
4. Unit tests verify the prompt includes the behavior assertion and generated code.

## Files to create/modify

```
engine/internal/generators/flutter/
├── wrapper.go           # LLM wrapper generation
├── prompt_builder.go    # Reusable prompt assembly
└── wrapper_test.go
```

### Suggested API

```go
package flutter

func GenerateWrappers(
    ir *ir.IR,
    tasks []planner.Task,
    client llm.Client,
    outDir string,
) error
```

### Prompt guidelines

Include in every prompt:

- "You are generating Flutter code that connects existing generated widgets to existing generated Cubits."
- "Do not modify the dumb widget or cubit classes. Import them."
- "Use flutter_bloc. Prefer BlocSelector."
- "Make the code compile and satisfy this behavior: <assertion>."
- "Return only the Dart code, wrapped in a ```dart ... ``` fence."

## Layering notes

- Depends on: project generator, store generator, UI generator, LLM client, planner.
- Enables: test generator and TDD fix loop have runnable code to verify.
- This is the first non-deterministic milestone. Keep prompts explicit and constrained to reduce hallucination.
- The wrapper generator should validate that generated Dart files are syntactically valid before writing them; syntax errors trigger the fix loop.
