---
name: plan-execution
description: Use when executing any multi-step plan or initiative - after planning is done and work begins, when tempted to spawn_task a follow-on step, when work fans out into parallel pieces, when resuming an initiative another session started, or when the owner asks "what's the state of X plan". One orchestrator session runs children as background agents; the plan doc is the only shared state; chips only for owner-gated steps. Per ADR 0039.
---

# plan-execution

One initiative, one orchestrator, one plan doc. Canonical rationale:
[decisions/0039-orchestrator-plan-execution.md](../../decisions/0039-orchestrator-plan-execution.md).

## The rules

1. **The planning session becomes the orchestrator.** It runs the plan to completion and never
   chips off a follow-on step. If the orchestrator's context degrades (context-discipline.md
   symptoms), it writes the plan doc current and hands off to ONE fresh orchestrator; children
   are never promoted to coordinator.
2. **Children are background agents, not sessions.** Agent tool, `run_in_background: true`,
   worktree isolation when they write files. Parallel independent steps launch in one batch.
   Headless `claude -p` only when work must outlive the orchestrator; seed it with the plan doc
   path.
3. **The plan doc is the only shared state.** Location: the project's own plan home if it has
   one (schnapp-os: `docs/superpowers/plans/`), else `docs/plans/<initiative>.md` in the target
   repo. Session memory, chat context, and agent transcripts never carry plan state.
4. **Chip only when owner-gated:** a password or credential only the owner holds, a spend or
   scope decision, an irreversible step per the intent-check checkpoint test. The chip prompt
   names the plan doc. Everything else just runs.
5. **Blocked-on-owner is surfaced once, as the single next step** (working-style reply shape),
   with everything not depending on it already done.

## Plan doc skeleton

```markdown
# <initiative>

Objective: <one line>
ADR: <link if one exists>

## Tasks

- [x] step - verify: <command/evidence>
- [~] step (partial: <what remains>)
- [ ] step [OWNER-GATED: <why>]

## Decisions

- <date> WON'T DO <thing>: <why> <- children check here before acting
- <date> <choice>: <why>

## Children

- <date> <agent label or session> -> <step> -> <outcome + commit>
```

## Orchestrator loop

1. Write the plan doc before the first child. Every child prompt includes: plan doc path,
   "read Tasks and Decisions first", the one step it owns, and "report outcome + commit SHA".
2. Launch independent steps as one parallel batch; dependent steps as they unblock.
3. On each child result: flip the box, log the child, append the tracker line, commit and push
   (same-commit rule, anti-stale.md). A failed child gets its failure logged in Decisions
   before any retry (working-style: undocumented failure is forgotten failure).
4. Owner-gated step reached: do all non-dependent work first, then surface the single
   copy-paste-ready step and stop.
5. Plan complete: verify against the original objective (not the plan), then session-end
   ceremony per the target repo's conventions.

## Resuming (any session)

Read the plan doc FIRST: unflipped boxes are the work, Decisions bound what you may do,
Children shows what is already running. Never re-derive or re-litigate either
(handoffs-carry-facts). Then follow handoff-resume if a handoff exists.
