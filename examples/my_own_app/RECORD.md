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

## 2026-11-08: travel example replaces music and plants

- Removed the `music` and `plants` modules and their carousel chips, live links, routes, pages and labels. The carousel is now food · work · travel.
- Added `modules/travel`, a trip planner. It has a list of trips, and a trip page with a day strip, transport and attraction filters, and each day's plans with their costs. A cost bar stays at the bottom with the day's cost, the cost so far and the trip total. There is a ticket sheet per plan, and a food budget sheet with quick amounts and a typed amount. Its look is warm sand, sea teal and terracotta, in Plus Jakarta Sans, with three SVG cover illustrations.

| Step | Time | Cost | Tokens | Check runs |
|---|---|---|---|---|
| Travel example | 8m 19s | $2.33 | n/a | 5 |

## 2026-11-08: travel example, real photos, long trips, Portuguese data

- Replaced the sample trips with two long ones: a 16-day grand tour of Europe (Lisbon, Sintra, Barcelona, Paris, Versailles, Florence, Rome) and 15 days in Egypt (Cairo, Giza, Luxor, a Nile cruise, Aswan, Abu Simbel, Hurghada). There are 63 plans in all.
- Added 57 real photos from Wikimedia Commons (about 3 MB). They show on the trip covers, each day's card, the attraction rows and the ticket sheet. Credits are in `modules/travel/IMAGE_CREDITS.md`.
- Every text in the trip data is now a `localized` value (`en`, `ptBr`), shown with the shared `tr`. Dates are written out in both languages, and euros use a decimal comma in Portuguese.
- The trip page has a grid of dates, with a dot where a new city starts, and a day card with a photo and previous/next arrows. The day chips are gone.

| Step | Time | Cost | Tokens | Check runs |
|---|---|---|---|---|
| Photos, long trips, Portuguese data | ~23m (from the previous reading) | $2.96 | n/a | 3 |

## 2026-11-10 to 11: app-building pipeline (MCP server, skill, parallel agents)

- Built a pipeline that builds a whole app from a short request: the `metacode` MCP server (`tool/mcp.dart`, also a CLI as `tool/mc`), the `metacode-new-app` skill and two agent types, `metacode-coder` and `metacode-designer`. The orchestrator writes one `plan.yaml`: models, state, labels, routes, and every page, component, action, value and test. `scaffold` writes the contract files and one stub per unit that already compiles. `briefs` cuts the plan into self-contained work orders, and agents fill them in parallel. Coders use `validate` (~0.2s per file) and `test`; the orchestrator runs `check` once.
- Engine and catalog changes made along the way:
  - an indeterminate `progress` stands still under reduced motion;
  - `icon` props accept a value;
  - new props: `progress.color`, `enabled` on every button, `textField.keyboard`;
  - `tool/check.sh [app]` takes an app folder;
  - verified dart_eval limits in REFERENCE.md: `break` in a `for` of an action, `?: null` over a map read, `List.of(..)..add`, and `indexWhere` crash or fail to compile.
- Benchmarks: each run is a fresh headless `claude -p` session. Opus orchestrates and the agents run on Sonnet unless noted. Each app was checked again independently afterwards.

| Run | App | Units | Time | Cost | Orchestrator / agents | Agents | Check runs | Tests passing |
|---|---|---|---|---|---|---|---|---|
| 1 | travel (inside the build session) | 53 | 4m 48s | $4.13* | n/a | 11 | 4 | 68 |
| 2 | travel | 69 | 3m 43s | $1.78 | $1.05 / $0.74 | 5 | 2 | 85 |
| 3 | travel, Haiku coders | 72 | 7m 02s | $1.91 | $1.67 / $0.25 | 4 | 5 | 88 |
| 4 | travel, one-file plan | 63 | 4m 18s | $1.64 | $0.98 / $0.65 | 3 | 2 | 83 |
| 5 | split (logic-heavy) | 116 | 12m 53s | $3.03 | $1.98 / $1.05 | 4 | 3 | 126 |
| 6 | cafe (screen-heavy) | 181 | 7m 06s | $2.76 | $1.52 / $1.24 | 5 | 1 | 245 |

\* Inflated: that orchestrator's context was full from building the tools.

Notes:
- Each agent pays ~30k tokens to start, and each finished agent wakes the orchestrator for a turn over its whole context. Going from 11 small agents to 3-5 full ones roughly halved the cost. Briefs of 30-40 units still finished in ~2 minutes (cafe).
- Haiku coders cost about 10x less, but they left interpreter crashes for the Opus orchestrator to fix, which cost more than Haiku saved.
- The orchestrator is 50-65% of every run's cost, and its share grows with the plan (1,297 lines for cafe). Screens are cheap (cafe: 1.5¢ per unit, first check passed). Logic costs (split: 2.6¢ per unit, extra turns for algorithmic fixes and phone overflows).
- Gaps the runs found:
  - nullable models in state (`expense?`) don't compile in dart_eval;
  - the theme can't change while the app runs;
  - no horizontal `listView` and no navigation rail;
  - `WhoAmIPicker` becomes `who_am_ipicker.yaml`;
  - planned values that nothing uses aren't flagged;
  - designers have no layout check of their own.

## 2026-11-11: split and cafe in the carousel, pipeline improvements

- Moved `split` and `cafe` into `modules/` as carousel examples 4 and 5. Each has a chip, phone colors, a live page with a start-over button, and a chat prompt and reply in en and pt_br. All 811 tests passed on the first check run (1m 48s, $0.49).
- Pipeline:
  - a `metacode-planner` agent (Sonnet) writes the plan from a short `spec.md`, so the Opus orchestrator no longer writes it;
  - designers get a `layout` tool, and layout failures go back to the designer that wrote them;
  - `check` flags planned names that nothing uses;
  - `per_agent` defaults to 30;
  - `WhoAmIPicker` now maps to `who_am_i_picker`.
- Engine and catalog:
  - nullable models in state compile (an `if`-based `fromJsonOrNull` replaces the `?:`);
  - `core.theme.set('dark'|'light'|null)`;
  - `listView.horizontal`;
  - a scaffold's `navigationBar` becomes a side rail at 840px and wider (`rail:` to change or turn it off);
  - a `coffee` icon.
  All covered by widget and engine tests; `tool/check_engine.sh` passes.
- The planner agent and the `layout` tool haven't been benchmarked yet.
- Later the same day: moved `split` and `cafe` back to `examples/` as standalone apps and took them off the website. The root app is back to its committed state. All three apps pass `tool/check.sh` (437, 126 and 245 tests).
