# 0039: Orchestrator plan execution: background agents by default, chips only when owner-gated

Date: 2026-07-18
Status: Accepted
Refines: 0011 (working-style promotion lane), rules/global/working-style.md "Nothing dangles"

## Context

Multi-step plans were executed by chaining spawn_task chips: the planning session chips off
step 1, that session chips off step 2, and so on. By plan completion the owner had a half dozen
sibling sessions with no shared state, no lineage (which session spawned which), no central
tracker, and per-session memory that let one session redo or contradict what another already
did or decided against. The owner named this on 2026-07-18 (same day as the schnapp-bet
failover build, which demonstrated the alternative: one session, background subagents, one
report) and asked for hands-off execution: "Instead of spawning a task chip, can you just
start the new session for me every time?"

Chips were being used for two unrelated things: (a) parallelizing or continuing in-scope work,
where the owner's click adds nothing, and (b) flagging work that genuinely needs an owner
decision or credential. Only (b) needs a chip.

## Decision

1. One initiative, one orchestrator. The session that makes the plan runs it to completion.
   It does not chip off follow-on steps.
2. Children are background agents (Agent tool, worktree isolation when they write files), not
   sibling sessions. Results return to the orchestrator; the owner watches one transcript.
   Headless `claude -p` sessions are the fallback only when work must outlive the orchestrator.
3. The plan doc is the shared brain. Checklist, decision log (including explicit won't-dos),
   and child registry live in the initiative's plan doc; children read it first and flip boxes
   same-commit (anti-stale.md tracker currency). Session memory never carries plan state.
4. Chips are reserved for owner-gated work: a credential or password, a spend or scope
   decision, an irreversible step per the checkpoint test. Everything else just runs.
5. Codified as the `plan-execution` skill (the procedure) plus a sharpened "Nothing dangles"
   bullet in rules/global/working-style.md (the default).

## Consequences

- Hands-off by default: in-scope follow-on work starts immediately as a background agent; the
  owner is interrupted only by genuine gates.
- Session sprawl and cross-session contradiction drop to near zero because plan state has one
  home and execution has one coordinator.
- Orchestrator context is the new scarce resource: children isolate their file-dump noise, and
  a long initiative hands off to a fresh orchestrator via the plan doc, not by chipping.
- Chips that do appear now always mean "the owner must decide or act", restoring their signal.
