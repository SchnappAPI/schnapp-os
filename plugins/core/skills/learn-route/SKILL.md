---
name: learn-route
description: Use immediately after a correction or capture lands — to classify what kind of knowledge it is and route it to the right destination via the correct lane. Invoke whenever a mistake is corrected, a fact is superseded, or a behavioral pattern needs to be codified.
---

# learn-route

The authored classifier for the learning loop's capture-and-route step. Run this after any
correction arrives (hook fires on hookless surfaces, or invoke manually). It does three things:
classify → pick the lane → act. The classification taxonomy lives in
[memory/README.md](../../../../memory/README.md) ("on-correction" section); the lane policy lives
in [ADR 0012](../../../../decisions/0012-self-edit-gate-two-lane.md). This skill does not restate
either — it points to each and adds the execution notes.

## 1 — Classify

Follow the "on-correction" routing in [memory/README.md](../../../../memory/README.md):

- **Behavioral / how-to-work** → sharpen the EXISTING rule in
  [`plugins/core/rules/global/`](../../rules/global/) (add a new file only if there is no home;
  never duplicate an existing rule).
- **Durable fact** (a value, name, or location that must be remembered across sessions) →
  `memory/` supersede: write the corrected fact, set `source: correction`, set today's `updated:`,
  mark the old fact as superseded.
- **Stale doc or stale claim** → fix the doc in the same change.

When unsure of the type, apply the "one fact, one canonical home" principle from
[ADR 0011 #4](../../../../decisions/0011-plan-review-ten-redecisions.md): pick the single most
appropriate place; do not scatter copies.

## 2 — Pick the lane

Consult [ADR 0012](../../../../decisions/0012-self-edit-gate-two-lane.md) for the authoritative
lane split. The short rule:

| If the edit … | Lane |
|---|---|
| Is mechanical: typo, formatting, dead-link fix, regenerating a catalog, backfilling provenance — **does not change a rule's meaning or a fact's truth** | **Direct to main** — commit and push. |
| Changes a **rule's meaning**, **supersedes a fact**, adds or removes a rule — anything a reviewer should weigh | **Branch + PR** — use `self-edit-stage.sh`. |

The gate is **preferred-not-mandatory**. When in doubt, use the gate (the cost of an extra PR is
lower than the cost of an unreviewable rule change landing silently).

Humans always commit to main directly; this routing applies to **agent-proposed** self-edits only.

## 3 — Act

**Mechanical lane (direct to main):**
```
git add <file>
git commit -m "fix: [meta] <short description>"
git push
```

**Judgment lane (branch + PR):**
```
# (the proposed edit is already in the working tree)
bash plugins/core/scripts/self-edit-stage.sh <slug> "<rationale>"
```

The `<rationale>` should state: what changed, why it is correct, what source/event triggered it,
and (for fact supersedes) what value is being replaced. Example:

```
bash plugins/core/scripts/self-edit-stage.sh supersede-api-key \
  "correction: API key rotated 2026-06-27; old value was stale; source: owner; supersedes previous key in memory/credentials.md"
```

The stager creates `self-edit/<date>-<slug>`, commits the change there with the rationale in the
commit body, restores the original branch with a clean working tree, and opens a PR (or prints a
compare URL if `gh` is absent). Main is untouched until the PR is merged.

The human (or a future eval agent) reviews and approves. No further action is needed from the
agent once the stager exits 0.

## Companion skills

- [session-hygiene](../session-hygiene/SKILL.md) — on hookless surfaces, run this skill by hand
  as the "route the correction" step of the on-correction procedure. `session-hygiene` points to
  `memory/README.md` for the canonical on-correction flow; `learn-route` adds the lane decision
  and the exact `self-edit-stage.sh` invocation.
