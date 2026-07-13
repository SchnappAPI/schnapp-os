---
name: rules-distill
description: Use when reusable lessons have piled up uncaptured: after a stocktake, during periodic maintenance, or when several skills or sessions keep repeating a principle that no rule, memory file, or decision yet records. Extracts cross-cutting principles and routes each to the right knowledge home.
---

# rules-distill

Cross-read a corpus (skills under [`skills/`](../) and/or recent
[`handoffs/`](../../handoffs/)), extract principles that recur, and route each to its
canonical home. List every source first, *then* judge what is a repeated principle vs a one-off.

Routing follows the standing rules, not this skill: [knowledge-capture](../../rules/global/knowledge-capture.md)
(general lesson → global lane; project fact → project lane) and [anti-stale](../../rules/global/anti-stale.md)
(one fact, one file; supersede, never append a contradiction). Never invent a rule the corpus
does not support: [verify-before-asserting](../../rules/global/verify-before-asserting.md).

## Phase 1: Inventory

List the corpus before reading any of it, so nothing is skipped:

- Skills: `ls skills/*/SKILL.md`. Note each `name` + `description`.
- Existing rules: `ls rules/global/ rules/modules/*/`.
- Recent sessions: newest files in [`handoffs/`](../../handoffs/).

## Phase 2: Extract and route

Keep a candidate **only if all four hold**:

1. **Recurs**: appears in 2+ sources. One source means it stays where it is.
2. **Actionable**: phrasable as "do X" / "don't do Y", not "X matters".
3. **Has a failure mode**: one sentence on what breaks if ignored.
4. **Not already captured**: check existing rules/memory/decisions, including the same idea in other words.

Assign each survivor a **destination** and a **verdict**:

| Destination | What lives there | Pick when |
|---|---|---|
| [`rules/global/`](../../rules/global/) | always-on, language-neutral behavior | a general lesson all projects need |
| [`rules/modules/`](../../rules/modules/) | path-scoped lang/tool/activity rules | the lesson only applies to a language, tool, or activity |
| [vault memory lane](../../docs/memory-lane.md) | durable cross-surface facts/context (`~/code/schnapp-vault/memory/`) | a fact to recall, not a behavior to enforce |
| [`decisions/`](../../decisions/) | the *why* behind a locked choice | a tradeoff was settled and the reasoning must persist |

| Verdict | Meaning |
|---|---|
| Append | add to an existing section of the chosen file |
| New section | new heading in an existing file |
| New file | new rule/memory/decision file |
| Revise | existing text is wrong or thin: give before/after |
| Already covered | drop it (say where it lives) |
| Stays put | too specific: keep in its skill/session |

## Phase 3: Review, then write

Present a table (`# | principle | destination | verdict | target | confidence`) plus, per row,
evidence (which sources), the failure mode, and draft text. **Write nothing until the owner
approves a row.** On approval: supersede a stale fact, never stack a second copy; a memory entry
carries `source:` and `updated:`. Draft text names the source skill so the detailed *how* stays findable.

## Example

```
# | principle                                              | dest         | verdict     | target                  | conf
1 | Validate LLM output before reuse (type, shape, escape) | rules/global | New section | (new) llm-output-trust  | high
2 | Bound every retry/iteration loop with a stop condition | rules/global | Append      | working-style.md        | med
3 | SQL Server bulk loads need fast_executemany            | rules/module | Already cov | coding/speed-by-default | n/a
```

Row 1: in `council` and `grill-me`; failure mode = malformed model output
crashes the consumer. General → global lane, new file. Row 3 drops: already stated.
