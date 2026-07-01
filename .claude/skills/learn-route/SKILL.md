---
name: learn-route
description: Use immediately after a correction or capture lands — to classify what kind of knowledge it is and route it to the right destination via the correct lane. Invoke whenever a mistake is corrected, a fact is superseded, or a behavioral pattern needs to be codified.
---

# learn-route

The authored classifier for the learning loop's capture-and-route step. Run this after any
correction arrives (hook fires on hookless surfaces, or invoke manually). It does three things:
classify → route → act. The classification taxonomy lives in
[docs/memory-lane.md](../../../docs/memory-lane.md) ("On-correction update" section); the routing policy lives
in [ADR 0016](../../../decisions/0016-no-branches-precommit-gate.md) (refines 0012/0013/0015 —
no branches, everything to main). This skill does not restate either — it points to each and adds
the execution notes.

## 1 — Classify

Follow the "On-correction update" routing in [docs/memory-lane.md](../../../docs/memory-lane.md):

- **Behavioral / how-to-work** → sharpen the EXISTING rule in
  [`rules/global/`](../../../rules/global/) (add a new file only if there is no home;
  never duplicate an existing rule).
- **Durable fact** (a value, name, or location that must be remembered across sessions) →
  `memory/` supersede: write the corrected fact, set `source: correction`, set today's `updated:`,
  mark the old fact as superseded.
- **Stale doc or stale claim** → fix the doc in the same change.

When unsure of the type, apply the "one fact, one canonical home" principle from
[ADR 0011 #4](../../../decisions/0011-plan-review-ten-redecisions.md): pick the single most
appropriate place; do not scatter copies.

## 2 — Route it (everything to main, no branches)

Per [ADR 0016](../../../decisions/0016-no-branches-precommit-gate.md): **no branches.** Two paths,
by who is acting:

- **In-session, acting on a correction the owner just made** — the owner is the reviewer in real
  time. Edit the EXISTING rule (behavioral) or supersede the fact (memory), bump `updated:`, and
  commit **straight to `main`**.
- **The nightly autonomous worker** (`learning-worker.sh`) is the only self-gated path: it writes a
  proposed edit, then `learning-gate.sh` vets it — a clean proposal commits to `main`, anything held
  becomes a GitHub **issue** for review. You never run that by hand.

## 3 — Act (in-session)

Edit the EXISTING rule/fact in the working tree (never duplicate; bump its frontmatter `updated:`),
then commit straight to main:

```
git add <file>
git commit -m "fix: [meta] <what changed + why + source>"
git push
```

Keep it small and in-scope (the one file that owns the fact). State in the commit body what changed,
why it is correct, what triggered it, and — for a fact supersede — what value it replaces.

## Companion skills

- [session-hygiene](../session-hygiene/SKILL.md) — on hookless surfaces, run this skill by hand as
  the "route the correction" step of the on-correction procedure. It points to `docs/memory-lane.md`
  for the canonical on-correction flow; `learn-route` adds the classification + the commit-to-main step.
