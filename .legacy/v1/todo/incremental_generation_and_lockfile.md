# Incremental Generation and Lockfile

The README proposes that Metacode should only regenerate code that changed between runs.

## MVP status

The current `.lock` file is only a placeholder: it stores a hash of the spec files
and a timestamp, but every run still performs full regeneration.

## Future work

- Compute a per-spec fingerprint (hash of each top-level spec block).
- Compare fingerprints with the previous lockfile.
- Only re-run code generation for changed/added/removed specs.
- When a spec changes, run all tests (to catch regressions) but only rewrite
  files that depend on the changed symbols.
- Support removal of specs by deleting the corresponding generated files.
