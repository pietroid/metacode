# LLM Generation Loop

Implement the non-deterministic generation loop described in the README:

1. For each spec, invoke an LLM tool to generate code.
2. Run the generated tests.
3. If a test fails, feed the error back to the LLM and regenerate until the test passes.

## Open questions

- Which LLM provider/API should be supported first? (OpenAI, Anthropic, local/Ollama)
- How should prompts be structured to keep them small and deterministic?
- How do we avoid infinite loops or runaway token usage?

## Notes

This is intentionally skipped in the MVP so that the deterministic scaffolding,
parsing, and test-running pipeline can be validated first.
