---
name: intent-check
description: Use before acting on an ambiguous, high-stakes, or "am I even asking the right thing" request - reason from the literal words to the TRUE intent, actively hunt for a materially better approach than the one asked (not just follow along), and decide where a human checkpoint earns its place. Judges the whole job, not one step, so it fits multi-step plan / feature work. Invoke when a request feels underspecified, before an irreversible / outward-facing step, or before non-trivial work. The owner can call it as /intent-check when unsure they framed a request well.
---

# intent-check

Closes the "am I asking the right thing?" gap: reason from what was said to what is meant, AND
whether the asked-for approach is even the best one, BEFORE executing - then pause only where a
checkpoint earns it. Silent by default (surface only the distilled result, see Output contract);
loud only when the work clears the divergence gate (Section C). The point is less noise, not a
visible essay of reasoning.

Not a single-step clarifier. The request is often a whole multi-step plan or feature - judge it at
that level, and never assume the asked-for approach is right just because it would get the job done.
Catching the better path the owner did not mention is the job (`working-style.md`: "surface a better
option"; "acting as an expert is catching what the instruction left out").

The three-question core (surface vs core = Q1, explicit vs effective = Q2, purpose = Q3) runs on
every message via the standing-rules hook, weighed against `working-style.md`. Invoke this skill for
the full seven-question pass, the divergence gate, and checkpoint placement on ambiguous or
high-stakes work.

## A. Intent pass (seven questions, answer silently)

1. **Surface vs core** - what is literally asked vs the true goal behind it?
2. **Explicit vs effective** - does doing the literal ask fully satisfy that goal, or are there gaps?
3. **Purpose** - what is the ultimate objective, and does the asked-for work serve it? Judge all of
   it, not just the first step: for multi-step work, is every component essential, or is there a
   shorter path?
4. **Signal** - does the wording point at the real need, or could it mislead?
5. **Approach** - is the asked-for method even the best one? Generate the genuine alternatives,
   INCLUDING approaches the owner did not name, and compare. A request getting the job done does not
   make it the most efficient, simple, or robust way. This is the silent judgment the divergence
   gate (C) acts on.
6. **Risk** - the most likely misreads or failure modes, and which ambiguity causes each?
7. **Optimize** - every material change that would sharpen the plan as framed - ranked by impact,
   NOT capped at one. Surface all that clear the materiality bar; stay silent on marginal ones.

## B. Checkpoint placement (where to pause vs just proceed)

Insert a human checkpoint only when a step is **irreversible**, **outward-facing / high-consequence**,
or **needs context you lack**. Everywhere else, decide and proceed - a checkpoint on a reversible,
low-cost, in-context call just trains rubber-stamping (checkpoint fatigue). Concretely:

- Pause **before** the point of no return, not after (after is forensics, not control).
- Most tasks need **two or three** well-placed checkpoints, not one per step.
- Make each checkpoint a **single clear question** with only the decision-relevant context - a two-second scan.
- On a rejection, capture **why** and fix that cause (route via [learn-route](../learn-route/SKILL.md)), not just the instance.

## C. Divergence gate (front-load the search for a better approach)

Discovering a better approach mid-build is expensive rework, so look up front. Gate on one
**materiality bar** - multi-file, irreversible, outward-facing, or new-subsystem work is *above*; a
single obvious edit is *below*:

- **Below the bar** - silent intent pass only. No spin-up, no offer.
- **Above the bar + Q5 flags a plausibly-better approach** - auto-spin, do not ask:
  1. Dispatch a subagent to run **`superpowers:brainstorming`** in generate mode if the
     superpowers plugin is present on this surface; otherwise run the same divergence step inline
     (generate candidate approaches + tradeoffs yourself). Either way it produces candidates, it
     does not run the Socratic loop (a subagent cannot interview the owner). Feed it the concrete
     request, constraints, and established facts inline, not a pointer
     ([[handoffs-carry-facts-not-pointers]]), or it generates in a vacuum.
  2. ONLY IF brainstorming returns a real contender to the ask, dispatch a second subagent to run
     the [council](../council/SKILL.md) skill to adjudicate the competing approaches adversarially.
     Sequenced, not parallel: council needs candidates to judge.
  3. Present the result: ranked approaches, one line each, with a recommendation and the checkpoint
     to pick (an approach-swap is a fork the owner picks, not you). If the ask wins, say so in one
     line ("explored N alternatives, your approach is best, proceeding") - do not go silent, or the
     owner cannot tell it ran.
- **Above the bar + Q5 flags nothing better** - emit a one-line **offer** (an offer, not a
  checkpoint, so it stays consistent with B): "quick pass found nothing better because <why> - run
  full brainstorm+council to be sure? (y/n)". Non-blocking: **proceed on silence**. The <why> lets
  the owner judge the override instead of blind-clicking. EXCEPTION: on an irreversible /
  outward-facing step the offer blocks - wait for the answer.

Where the superpowers plugin is loaded, this spin-up **satisfies** its
brainstorm-before-building gate (`superpowers:using-superpowers`); do not brainstorm twice.

## Output contract

Emit only:
1. a one-line restatement of the TRUE intent;
2. any genuine fork you cannot settle from the objective (ask just those);
3. the approach verdict - if the gate ran: the ranked alternatives + recommendation, or the one-line
   "your approach is best"; if it did not run but the work is above the bar: the one-line offer;
4. if a step is irreversible or outward-facing: the checkpoint you are inserting and why.

## Companions

- [working-style.md](../../../rules/global/working-style.md) - the always-load one-line version of this ("Read for intent...").
- [learn-route](../learn-route/SKILL.md) - route a correction to its root cause so it cannot recur.
- [council](../council/SKILL.md) + `superpowers:brainstorming` - the divergent-approach evaluation the gate spins up.
