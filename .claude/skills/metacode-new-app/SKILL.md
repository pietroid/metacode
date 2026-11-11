---
name: metacode-new-app
description: Build a whole new Metacode app (or a large new module) from a one-line idea in minutes - grill the idea, plan every unit up front, scaffold compiling stubs, then fill them with many parallel designer and coder agents, and check once. Use when the user asks for a new app, a new example in examples/, or a new module with several screens. For a change to an existing app, use metacode-app.
---

# Build a new Metacode app

You are the orchestrator. Everything is decided up front (the **plan**, written by a planner agent from your spec), so that a few agents can each fill a few files at once without ever talking to each other, and the app compiles at every moment. Agents are cheap and parallel; your own turns are the bottleneck, so **keep yours few**: no exploring, no reading of what agents wrote unless a check fails.

Tools: the `metacode` MCP server (`.mcp.json`; tools `mcp__metacode__*`). Without it, every tool runs from the shell the same way: `tool/mc <tool> <app> [--arg value]` (e.g. `tool/mc scaffold examples/travel`). Never launch the app.

**First**, for the report: `date +%s` and `session_cost` (`mcp__usage-bars__session_cost`) if available.

## 1. Grill (lazy dev): at most one round

Find the 2-4 decisions that change the plan and that the request leaves open (who uses it, the core loop, which screens, what is shared/online, which external data). Ask them in **one** `AskUserQuestion` call, each with a recommended default first. Don't ask what you can decide (look, names, colors, sample data). If the request already decides them, or the user said not to ask, skip this and state your assumptions in the report.

## 2. Spec: a short file, then a planner writes the plan

Write `<app>/spec.md` (10-30 lines): what the app is for, who uses it, the screens and flows the user asked for, what is shared/online, external data, and the grill answers and your assumptions. Don't plan it yourself: spawn one `metacode-planner` agent with the prompt `Spec: <app>/spec.md`. It reads PLAN.md, writes `plan.yaml` (models, state, labels, routes, and every unit), and runs `scaffold` until it reports `OK`. This keeps the long plan out of your context and off your (more expensive) model: in the benchmarks the plan was 50-65% of a run's cost when the orchestrator wrote it.

When it replies, read only its summary (not plan.yaml). If it reports a decision you disagree with, tell it with `SendMessage` and let it fix the plan.

Planning a small app or a module change yourself is fine: then `init`, read [PLAN.md](PLAN.md), write `plan.yaml` in one `Write`, and `scaffold` until `OK` (fix with `Edit`, never rewrite the plan).

## 3. Fan out

`briefs` (app; per_agent defaults to 30) writes one self-contained brief per agent (designer, coder, stylist) and lists them. In **one message**, spawn one agent per brief, all in parallel:

- role `designer` and `stylist` -> `subagent_type: metacode-designer`
- role `coder` -> `subagent_type: metacode-coder`
- prompt: just `Brief: <path to the brief file>` (it holds everything; don't paste it).

Coders validate and then run their own files' tests (`test`), so interpreter crashes are fixed by them, not by you. Keep coders on Sonnet: on Haiku they cost ~10x less but left 4 interpreter crashes for the orchestrator, whose turns cost more than the savings (benchmark: Sonnet coders $1.78 / 3m43s / 2 checks; Haiku $1.91 / 7m / 5 checks).

**Few, full agents.** Each agent pays a fixed ~20-30k tokens to start, and each one that finishes wakes you up (a turn over your whole context). So 2-6 agents, not 20: a typical app is 1-4 coders + 1-2 designers (the style rides with a designer). Briefs of 30-40 units finish in ~2 minutes. While they run, don't poll: wait for their notifications.

## 4. Check, fix, repeat

When all are back: `check` (app). It runs every test and the layout check (every route at phone/tablet/desktop) and groups failures by file.

- Layout failures: send them to the designer that wrote those files (`SendMessage` to that agent, with the failure text): it still has its brief and its files in context. Don't fix layouts yourself.
- A few small failures in code: fix them yourself (open only the failing file).
- Many, or in many files: spawn one agent per failing file group, same subagent type, prompt `Brief: <its brief path>. Fix: <the failure text for its files>`.
- A failure that comes from the plan (a missing value, a wrong type, a label): have the planner fix the plan (`SendMessage`), or `Edit` it yourself, `scaffold` again (it rewrites the contract and only the files still stubs), patch the affected files.

Repeat until `OK`. Then `status` should say all planned files are done.

## 5. Report

What was built (screens, the backend and API pieces), the assumptions you made, how to run it (`flutter run -d macos --dart-define=METACODE_PROJECT_DIR=<app>`), and one line:

```
⏱ 4m 10s · $1.20 · 310k tokens · 12 agents · 2 check runs
```

## Modules

A module is an app folder in `modules/<name>/` with its own spec.md and plan.yaml. Plan the parent first (where `miniApp: <name>` or its `<name>.<Thing>` parts go), then run steps 2-3 per module (independent: their planners, then their agents, can all run at once), and `check` the root.
