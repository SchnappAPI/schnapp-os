---
name: intent-check
description: Use before acting on an ambiguous, high-stakes, or "am I even asking the right thing" request - reason from the literal words to the TRUE intent, surface the genuine forks, and decide where a human checkpoint actually earns its place. Invoke when a request feels underspecified, or before an irreversible / outward-facing step. The owner can call it as /intent-check when unsure they framed a request well.
---

# intent-check

Closes the "am I asking the right thing?" gap: reason from what was said to what is meant BEFORE
executing, and pause only where a checkpoint earns it. Run it silently and surface only the
distilled result (see Output contract) - the point is less noise, not a visible essay of reasoning.

## A. Intent pass (seven questions, answer silently)

1. **Surface vs core** - what is literally asked vs the true goal behind it?
2. **Explicit vs effective** - does doing the literal ask fully satisfy that goal, or are there gaps?
3. **Signal** - does the wording actually point at the real need, or could it mislead?
4. **Purpose** - what is the ultimate objective, and what does THIS step contribute? Is it essential?
5. **Rationale** - why this path over the alternatives?
6. **Risk** - the most likely misreads or failure modes, and which ambiguity causes each?
7. **Optimize** - the one concrete change that would sharpen clarity and alignment.

## B. Checkpoint placement (where to pause vs just proceed)

Insert a human checkpoint only when a step is **irreversible**, **outward-facing / high-consequence**,
or **needs context you lack**. Everywhere else, decide and proceed - a checkpoint on a reversible,
low-cost, in-context call just trains rubber-stamping (checkpoint fatigue). Concretely:

- Pause **before** the point of no return, not after (after is forensics, not control).
- Most tasks need **two or three** well-placed checkpoints, not one per step.
- Make each checkpoint a **single clear question** with only the decision-relevant context - a two-second scan.
- On a rejection, capture **why** and fix that cause (route via [learn-route](../learn-route/SKILL.md)), not just the instance.

## Output contract

Emit only: (1) a one-line restatement of the TRUE intent, (2) any genuine fork you cannot settle
from the objective (ask just those), (3) if a step is irreversible or outward-facing, the checkpoint
you are inserting and why. No seven-step dump. If nothing is ambiguous and nothing is irreversible,
say so in one line and proceed.

## Companions

- [working-style.md](../../../rules/global/working-style.md) - the always-load one-line version of this ("Read for intent...").
- [learn-route](../learn-route/SKILL.md) - route a correction to its root cause so it cannot recur.
