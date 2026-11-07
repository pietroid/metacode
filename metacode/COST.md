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

# Build cost: example apps carousel (landing page)

Session of 2026-11-07. Measured the same way: `date +%s` and `session_cost` at the start and after the last check passed.

| Reading | `date +%s` | `session_cost` (USD) |
|---|---|---|
| Start | 1794083216 | $0.1511 |
| End | 1794083652 | $1.9520 |

| Step | Time | Cost | Tokens | Check runs |
|---|---|---|---|---|
| Carousel with 4 working mini apps (food, guitar, freelancer, plants), 4 photos, tests | 7m 16s | $1.80 | n/a | 6 `tool/check.sh` + 3 `tool/check_engine.sh` |

What was built:
- 4 models (`food`, `chord`, `job`, `plant`) and 8 new state fields.
- 26 actions and 60 bindings in total after the change (the tool's count).
- 4 Unsplash photos in `assets/` (720×360 JPEG, 22–77 KB each, about 186 KB together).
- Tests: 6 new action tests, 5 new binding tests and 2 new renderer tests. All tests pass: 25 app tests, 26 engine tests.

Notes:
- Tokens aren't available: both `session_cost` readings returned 0 for every token count, so only the dollar figure is reliable.
- Of the 6 `tool/check.sh` runs, 5 failed, each on one problem, fixed before the next run:
  1. and 2. Public helpers with a non-State first parameter (`groupDigits`, `examplePromptFor`) look like bindings to the tool. The fix was to make them private. The first rename didn't apply because macOS `sed` doesn't support `\b`.
  3. dart_eval doesn't support unary `-` on `num` (`-left`). Fixed as `0 - left`.
  4. and 5. dart_eval won't return an `int` or a `num` where a `double` is declared (`return 0`, `p > 1 ? 1.0 : p.toDouble()`). Fixed with a `_capAtOne(num) -> double` helper.
- Of the 3 `tool/check_engine.sh` runs, 2 failed:
  1. 6 renderer tests failed because `test/renderer_test.dart` built its own hard-coded state without the new fields (`TypeError: Not a subtype of type num`). It now starts from `state.yaml`.
  2. The new carousel tap test failed because it re-pumped the app in the same test, and Flutter kept the first bloc. The taps were moved to a separate test, and the render loop now pumps an empty tree between slides.
- About 7 extra direct `flutter test test/renderer_test.dart` runs were used while debugging those two failures.
