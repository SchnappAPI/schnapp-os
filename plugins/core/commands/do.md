---
description: Dispatch a task — pick the rules, the skill or agent, and the model tier, then run it
argument-hint: "[task description]"
---
# /do

One front door for "just do this." Take the task, route it to the right worker with the right
rules at the right model tier, say what you chose and why, then run it. This composes what already
exists (rules, skills, agents, the planner) — it does not reimplement any of them.

`$ARGUMENTS` is the task. If empty, ask for it in one line.

## Steps Claude follows

1. **Classify the task.** What kind of work is it — ETL/SQL, web tool, policy/procedure,
   Quickbase/AppFolio, research, a perf problem, a code review, repo/infra hygiene, or a
   general question? Name the class. If genuinely ambiguous, ask one clarifying question; do not
   guess on a task that mutates data, money, or production.

2. **Route to rules + worker + model.** Resolve all three, then state them before acting:
   - **Rules:** global rules always apply. Name any path-scoped modules the task needs directly
     from [`rules/modules/`](../rules/modules/) (e.g. ETL/SQL → `lang/python` + `lang/sql-server` +
     `activity/etl-pipeline` + `context/work|personal`; web → `lang/typescript` + `activity/web-tool`;
     policy → `activity/policy-procedure`; Quickbase → `tool/quickbase`). Inventory: [`../CATALOG.md`](../CATALOG.md).
   - **Skill/agent:** pick from [`../CATALOG.md`](../CATALOG.md). Prefer an existing skill/agent over
     doing it inline. Examples: build/optimize an ETL load → `etl-pipeline-build` +
     `performance-optimizer`; SQL correctness → `sql-etl-reviewer`; "is X slow" →
     `performance-optimizer`; deep question → `deep-research`; decision/interrogation → `council` /
     `grill-me`; review a diff → `/code-review`; whole-system state → the `status` skill; what's
     loaded here → `surface-check`.
   - **Model tier:** match effort to the work — a small, well-specified edit or lookup → a fast
     tier (haiku); standard build/review → sonnet; deep reasoning, architecture, or a hard debug →
     opus. State the tier; if dispatching to an agent, that agent's own `model` frontmatter wins.

3. **Plan if non-trivial.** For 3+ step or architecturally significant work, run the **Plan**
   agent (or `superpowers` brainstorming) first and confirm the approach before executing.

4. **Safety gate (asks-first).** If the task mutates data, money, or production — a deploy, a
   schema change, a merge, a destructive or outward-facing action — state the plan and get explicit
   confirmation before doing it. Read-only/idempotent work proceeds.

5. **Dispatch and run.** Hand off to the chosen skill/agent (or do it inline if no skill fits),
   carrying the resolved rules. Honor the always-loaded operating rules (verify before asserting,
   speed by default, secrets are references, never silently fail).

6. **Report.** State what was done, the result, and any follow-up (unpushed work, a queued
   approval, a doc/memory update the change implies). Persist anything durable per session-hygiene.

## Output shape (before running)
> **Class:** … **Preset/rules:** … **Worker:** <skill/agent/command> **Model:** … **Why:** one line.
> Then (if needed) the plan, then execution.

Keep the routing line short. The value is correct dispatch, not ceremony — if the task obviously
maps to one skill, say so in a line and run it.
