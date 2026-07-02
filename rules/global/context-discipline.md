---
scope: global
updated: 2026-07-02
---
# Context discipline (in-session)

Companion to [anti-stale.md](anti-stale.md) (which fights staleness in *files*) and
[speed-by-default.md](speed-by-default.md) (which fights wasted *I/O*): this fights **context rot**,
the in-session quality decay as a window fills. Signal density beats window size - a full window of
noise is worse than a tight one of exactly what matters.

- **Watch for rot.** Symptoms: repeating or contradicting earlier decisions, generic textbook
  output, drifting names/conventions, forgetting a stated constraint, over-hedging. These start well
  before the hard limit. When you see them, compact or restart - do not push through.
- **Bound the session.** Split work into phases (plan -> implement -> review). At a phase boundary,
  and by ~20-40 exchanges or ~30-50% of the window, write a handoff and start clean rather than
  letting one context balloon. A fresh session with a good grounding primer beats a rotted one.
- **Compact proactively**, not reactively: around the first rot symptom, not at the window limit. A
  clean compacted summary beats a bloated verbatim history.
- **Isolate with subagents.** For broad codebase search or reading many files, dispatch a subagent
  and keep the raw file dumps out of the main context - carry back only the conclusion.
- **Review against the original requirements, not the plan.** When checking generated work, re-anchor
  on the source ask; a plan-level misread is invisible if you only check against the plan.
- **Audit inputs before a multi-step task.** List what each step needs and where it comes from
  (static / retrieved / state-tracked); load only what the phase needs, discard the rest before the
  next step.

Grounding + resume are the memory lane's job ([docs/memory-lane.md](../../docs/memory-lane.md):
handoff packet). Loaded-component cost and in-session diagnostics (recall test, token-spike, the
subtraction pass) are the [context-budget](../../.claude/skills/context-budget/SKILL.md) skill's.
