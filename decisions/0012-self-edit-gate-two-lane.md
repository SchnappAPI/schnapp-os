# 0012 — Self-edit gate: two-lane policy (judgment vs mechanical)

Date: 2026-06-27. Status: DECIDED by owner (deliberate re-decision, D1 resolved 2026-06-27).

## Context

Phase 3 of the agentic-OS learning loop requires a governance gate: when the system proposes a
judgment-bearing self-edit (changing a rule's meaning, superseding a fact, adding or removing a
rule), it must land as a **reviewable PR**, not a silent commit to main.

Two prior constraints bear on this:
- **ADR 0011 #9** (git workflow) — main-only for routine work; no straight-to-main autopush without
  the force-push guard. Self-edits are a sanctioned exception to the "no feature branches" norm.
- **§7.7** (build order, item 8) of `docs/schnapp-os-research-and-decisions-2026-06-23.md` — "git
  pull-request review for self-edits" was listed as a desired guardrail; **§7.8** ("hard parts") adds
  that "self-modification needs governance, gained nearly for free by routing every self-edit through git."

The owner re-decided Decision D1 on 2026-06-27: the gate exists **and** the agent may commit
low-risk/mechanical self-edits directly to main. The gate is **preferred-not-mandatory**.

Humans always commit to main directly; this gate applies to **agent-proposed** self-edits only.

## Decision

Two-lane model. The lane is determined by whether the edit changes **meaning or truth**:

| Lane | What | How |
|---|---|---|
| **Direct to main** | Mechanical: typo / formatting / dead-link fix, re-running a generator (e.g. `gen-catalog.sh`), backfilling provenance — anything that does **not** change a rule's meaning or a fact's truth. | Agent commits straight to main (0011 #9 path). |
| **Branch + PR (gate)** | Judgment: changing a **rule's meaning**, **superseding a fact**, adding/removing a rule, anything a reviewer should weigh. | `plugins/core/scripts/self-edit-stage.sh <slug> "<rationale>"` → `self-edit/<date>-<slug>` branch + PR. |

The `learn-route` skill (`plugins/core/skills/learn-route/SKILL.md`) is the **authored classifier**
that routes a given correction into the correct lane. It is the single point of truth for the
routing procedure; this ADR is the single point of truth for the lane policy.

## Consequences

- **Phase 4 workers** route judgment-bearing self-edits through `self-edit-stage.sh`; mechanical
  fixes commit direct to main.
- `learn-route` is the authored classifier; it points here (ADR 0012) for the lane split and to
  `memory/README.md` for the correction taxonomy — it does not restate either.
- A future **eval agent** can auto-approve low-risk staged PRs without the gate losing its value.
- This **refines** ADR 0011 #9: it adds the sanctioned self-edit-branch exception. It does not
  supersede 0011 — the main-only principle for routine work stands.
