# Build cost: finance app

Measured with `date +%s` and the `session_cost` tool, per the `metacode-app` skill.

| Step | Time | Cost | Tokens | Check runs |
|---|---|---|---|---|
| Build finance app (3 tabs: finances, goals, menu) | 1m 44s | $0.46 | n/a | 1 |
| Fix dropdown layout error on the Menu tab | 46s | $0.08 | n/a | 3 |
| **Total** | **2m 30s** | **$0.54** | **n/a** | **4** |

Notes:
- Per-step token counts aren't available: the usage tool's token totals stopped changing between readings during each step. Its last reading put the whole session at 400,783 tokens (input 16, output 12,617, cache read 349,482, cache write 38,668). That figure includes work outside these two steps.
- Of the 3 check runs in the fix step, 2 failed. The first failed because the running app saved `contribution: 50` to `state.yaml` without quotes (an engine bug). The second failed on a test that assumed the app opens on the Finances tab.
