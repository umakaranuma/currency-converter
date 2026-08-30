# Agent Spec Pack — Currency Converter

This folder is the **single source of truth** for building this app. The
implementing agent must read every file here and build **only** what these
files describe. Nothing outside this folder (including the original assignment
PDF/markdown) should be treated as a requirement — it has already been distilled
into these files.

## Source

Distilled from `Flutter-Engineer-Assignment.md` (Flutter Engineer Assignment —
Currency Converter, 2-hour take-home). Where the assignment left a decision
open, this pack **makes the decision** and records the rationale in
[`decisions.md`](decisions.md). The agent must not re-open those decisions.

## Reading order

| # | File | Purpose |
|---|------|---------|
| 1 | [`context.md`](context.md) | What is being built, for whom, hard limits, assumptions |
| 2 | [`rules.md`](rules.md) | Non-negotiable constraints. Do / Don't. Read before writing any code |
| 3 | [`features.md`](features.md) | Functional requirements — the behaviour to implement |
| 4 | [`architecture.md`](architecture.md) | Layers, folder structure, dependency direction |
| 5 | [`tech-stack.md`](tech-stack.md) | API endpoint, packages, state management choice |
| 6 | [`caching.md`](caching.md) | When cache is read, written, invalidated; offline behaviour |
| 7 | [`error-handling.md`](error-handling.md) | Exception hierarchy, network vs API vs cache errors |
| 8 | [`testing.md`](testing.md) | What to test, what not to test, and why |
| 9 | [`deliverables.md`](deliverables.md) | README content, submission checklist, definition of done |

## How the agent should work

1. Read all nine files before touching code.
2. Follow [`architecture.md`](architecture.md) for folder layout exactly.
3. Implement [`features.md`](features.md) top to bottom.
4. Satisfy every MUST in [`rules.md`](rules.md). Treat SHOULD as strong default.
5. Write the test(s) described in [`testing.md`](testing.md).
6. Produce the project `README.md` per [`deliverables.md`](deliverables.md).
7. Run `flutter analyze` and `flutter test` — both must pass clean.

## Keyword convention

**MUST** / **MUST NOT** — hard requirement, failure = incomplete.
**SHOULD** — the chosen default; deviate only with a recorded reason.
**MAY** — optional, do it only if time remains.
