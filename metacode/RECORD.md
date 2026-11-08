# Session record

One entry per session: what it did, and its time and cost. Oldest first.

Measured with `date +%s` and the `session_cost` tool, read at the start of the work and again after the last check passed (per the `metacode-app` skill). Token counts are usually `n/a` because the tool's token totals don't change between readings, so the dollar figure is the reliable one.

## 2026-11-05: finance app

- Built a finance app with three tabs: finances, goals and menu.
- Fixed a dropdown layout error on the Menu tab.

| Step | Time | Cost | Tokens | Check runs |
|---|---|---|---|---|
| Build finance app | 1m 44s | $0.46 | n/a | 1 |
| Fix Menu dropdown layout | 46s | $0.08 | n/a | 3 |
| **Total** | **2m 30s** | **$0.54** | **n/a** | **4** |

Notes:
- The tool's last reading put the whole session at 400,783 tokens. That number also covers work outside these two steps.
- 2 of the 3 check runs in the fix step failed. The first: the running app saved `contribution: 50` to `state.yaml` without quotes (an engine bug). The second: a test assumed the app opens on the Finances tab.

## 2026-11-07: example apps carousel (landing page)

- Added a carousel to the landing page with 4 working mini apps (food, guitar, freelancer, plants), each with its own photo in `assets/` (about 186 KB in total).
- Added 4 models and 8 state fields, plus 6 action, 5 binding and 2 renderer tests. All tests passed: 25 app tests, 26 engine tests.

| Time | Cost | Tokens | Check runs |
|---|---|---|---|
| 7m 16s | $1.80 | n/a | 6 `tool/check.sh` + 3 `tool/check_engine.sh` |

Notes:
- Most failed runs were dart_eval limits:
  - Public helpers whose first parameter isn't State are read as bindings, so they have to be private.
  - Unary `-` on `num` isn't supported. Write `0 - x`.
  - An `int` can't be returned where a `double` is declared.
- The two failed engine runs were renderer test setup problems. The tests used hard-coded state, and one test re-pumped the app. The tests now start from `state.yaml`, and each tap test is separate.

## 2026-11-07: per-app styles for the example apps

- Gave each carousel sub-app (`food`, `music`, `work`, `plants`) its own `style/style.yaml`, with its own fonts, colors, corner radius, icon weight and title size. This shows that each app can have its own look.
- Wrapped each sub-app's `homePage` in a container with its own `surface` color, so the new colors show inside the root app's phone frame. The old content is now the `content` widget.
- No engine changes: the engine already applied a sub-app's `style/`.

| Time | Cost | Tokens | Check runs |
|---|---|---|---|
| 1m 8s | $0.24 | n/a (the tool reported 0) | 1 `tool/check.sh` (passed) |
