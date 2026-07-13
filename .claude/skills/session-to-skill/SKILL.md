---
name: session-to-skill
description: Use after a session where a non-obvious, repeatable multi-step procedure was worked out (a way of pulling two sources in a specific order, a format that summarizes a document type well, a debugging sequence that worked) and it would otherwise be lost and rediscovered next time. Extracts that procedure from the transcript and proposes it as a reusable skill.
---

# session-to-skill

Mine a finished session for an emergent **procedure** and turn it into a skill. This fills the gap
between the two existing capture skills, and does not overlap them:

| Skill | Captures | From | Destination |
|---|---|---|---|
| [`learn-route`](../learn-route/SKILL.md) | a correction | one mistake, just fixed | sharpen a rule / supersede a fact |
| [`rules-distill`](../rules-distill/SKILL.md) | a recurring *principle* | a skill/handoff corpus | a rule / memory / decision |
| **session-to-skill** | a repeatable *procedure* | a raw session transcript | a new skill (via `skill-creator`) |

A procedure is a multi-step *how*, not a one-line *what*. "Search the web and summarize" is a
description; "pull the vendor export, dedup on the composite key, then reconcile against the API
before loading" is a procedure worth a skill.

## 1 - Identify (is there a skill here?)

Answer five yes/no questions about what the session actually did:

1. Did it take a **multi-step** approach (not a single obvious call)?
2. Was it **non-standard** - did you make uninstructed judgment calls to get it right?
3. Was the **result notably good** (or did it fix something that kept going wrong)?
4. Is the **task type likely to recur**?
5. Are the **steps generalizable** beyond this one instance?

Mostly-yes -> a candidate. Otherwise stop: a one-off stays in the handoff, not a skill.

**Recurrence bar (do not mint one-offs).** Prefer to wait until the task type has appeared across
several sessions before extracting - one or two runs do not prove generalization. A single-session
extraction is allowed but must be flagged for closer review (it is a guess about the future).

## 2 - Articulate

Write the procedure as a structured skill definition, not prose:

- **Trigger condition** - when this skill should fire (the `description` frontmatter).
- **Prerequisites** - what must be true/available first.
- **Steps in order** - the actual sequence, with the judgment calls made explicit.
- **Decision points** - where the path branches and how to choose.
- **Expected output** - what "done" looks like.
- **Edge cases** - what broke and how it was handled.

## 3 - Deduplicate + conflict-check (before writing anything)

List existing skills (`ls .claude/skills/*/SKILL.md`, note each `name` + `description`) and compare.
If one already covers this, **strengthen it** instead of adding a sibling (anti-stale: one home, no
overlap). If two skills would tell the agent to do the same job differently, that conflict makes the
agent uncertain which to follow - resolve it, do not stack. This is the same bar as
`rules-distill` Phase 2 #4 ("not already captured") and the `context-budget` subtraction pass.

## 4 - Review, then author

Present the candidate (the six articulation fields + which sessions evidence it + the dedup result)
and **write nothing until the owner approves.** On approval, author the skill with the
`skill-creator` skill if that plugin is present (proper `SKILL.md` + progressive disclosure);
otherwise write the `SKILL.md` by hand to the same shape. Then
regenerate `CATALOG.md`. Route the primitive choice through
[`scaffolding-choice`](../../../rules/modules/activity/scaffolding-choice.md) first - sometimes the
right home is a rule or a hook, not a skill.

## Autonomous lane (not yet wired)

The nightly learning loop currently mines the *correction queue* (`capture-nudge` ->
`learning-worker` -> `learning-gate`), never transcripts for procedures. Adding a transcript-mining
lane is a designed follow-up: it must reuse the same gate discipline (clean proposal -> main, held ->
GitHub issue; single-session extractions always held for review) and be TDD'd like the other lanes
([decisions/0021](../../../decisions/0021-learning-loop-agent-sdk.md),
[0026](../../../decisions/0026-enforcement-ladder-recurrence-escalation.md)). Until then, run this
skill by hand.
