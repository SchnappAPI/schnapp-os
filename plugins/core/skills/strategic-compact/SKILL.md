---
name: strategic-compact
description: Use during long or multi-phase sessions to decide when to compact context at a logical boundary instead of waiting for arbitrary auto-compaction — after exploration before execution, after a milestone, before switching to unrelated work, or when responses start degrading under context pressure.
---

# strategic-compact

Compact at logical task boundaries, not wherever auto-compaction happens to fire. Auto-compact
often lands mid-task and drops live state; a boundary compact keeps the distilled output and
sheds the bulky lead-up. This skill is about *when* to compact a live session. For per-answer
depth see `token-budget-advisor`; for auditing loaded-component cost see `context-budget`.

## When to compact

| Transition | Compact? | Why |
|---|---|---|
| Research → planning | yes | research is bulky; the plan is the distilled output |
| Planning → implementation | yes | plan is captured; free context for code |
| Implementation → testing | maybe | keep if tests reference recent code |
| Debugging → next feature | yes | debug traces pollute unrelated work |
| After a failed approach | yes | clear the dead-end reasoning first |
| Mid-implementation | no | losing file paths and partial state is costly |

## What survives a compact

| Persists | Lost |
|---|---|
| CLAUDE.md + loaded rules | intermediate reasoning |
| Todo list | file contents you read |
| Files on disk, git state | tool-call history |
| Memory lane + handoff docs | verbal preferences not written down |

So **write before you compact**: anything load-bearing that lives only in the conversation
should land somewhere durable first.

## Compact vs. hand off

`/compact` keeps you in the same session with less history. When the work has reached a point
where a *fresh* window is better, use a handoff skill instead:

- **chat-context** (anthropic) — full-fidelity dump that preserves exact code/configs/queries
  when work is still in progress and the next window must continue inside it.
- **conversation-handoff** (anthropic) — structured summary when a task is wrapping and new
  work begins.

Either output belongs in the claude-kit lanes: durable facts to the
[memory lane](../../../../memory/README.md), session state to [`handoffs/`](../../../../handoffs/).
See [knowledge-capture](../../rules/global/knowledge-capture.md) for what goes where.

## Practice

1. Compact after planning once the plan is captured; compact after debugging before moving on.
2. Never compact mid-implementation.
3. Add a focus note: `/compact Focus on the auth middleware next`.
4. Watch for duplicate context — same rule in two scopes, a skill repeating CLAUDE.md, two
   skills overlapping a domain. `context-budget` finds these.
