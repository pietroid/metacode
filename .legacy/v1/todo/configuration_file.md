# Configuration File

Right now all options are hardcoded (spec dir, output dir, target framework).

## Future work

- Add a `metacode.yaml` config file at the project root.
- Supported options:
  - `specDir`
  - `outputDir`
  - `target` (flutter, react, swift, etc.)
  - `llm.provider`, `llm.model`, `llm.apiKey` (or env var reference)
  - `testCommand`
- Allow CLI flags to override config values.
