# Manual Code Zones

Real projects usually contain a mix of generated and hand-written code. We need a
safe way for developers to edit generated files without losing changes on the next
run.

## Proposals

- Mark hand-edited regions with special comments (e.g. `// [manual] ... // [/manual]`).
- Keep generated code in a dedicated `generated/` folder and allow manual wrappers
  around it.
- Generate only scaffolding/skeletons and let developers own the rest.

## Notes

This is closely related to incremental generation and should be designed together.
