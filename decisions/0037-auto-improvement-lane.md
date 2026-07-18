# 0037 - Autonomous improvement lane: auto-land without owner approval, staged by blast radius

Date: 2026-07-18. Status: accepted (owner directive 2026-07-18: "I want this to be automatic.
I don't want to have to approve it... detect when something is done frequently and auto
implement a fix"). Refines 0021 (learning loop) and 0028 (vault fact routing); supersedes the
owner-approval step of 0026 for improvement proposals. The 0026 RECURRENCE trigger (>= 2 of a
class, never severity) stays: it decides WHEN the loop acts; this ADR changes only WHO approves
(nobody - a deterministic gate plus staged rollout replace review).

## Decision

Extend the nightly learning loop with a transcript-mining lane that detects frequent patterns
(fired skills, repeated procedures, recurring corrections) and lands the fix autonomously.
Autonomy is tiered by blast radius, not by asking:

| Tier | Artifact | Landing policy |
|---|---|---|
| 1 (existing) | rule / memory-fact prose `.md` | auto-land via `learning-gate.sh` (unchanged) |
| 2 (new) | skill mint or sharpen (`skills/*/SKILL.md`) | auto-land when the extended gate approves: recurrence evidence (>= 2 sessions) attached, size cap, no trigger-phrase collision with the existing catalog, both generated projections regenerated in the same commit, all writing/secret gates pass |
| 3 (new) | hook | auto-land in OBSERVE mode (log-only wrapper, exit 0); self-escalates to blocking after >= 7 days with zero false-positive would-blocks; shellcheck + a `scripts/tests/` self-test land in the same commit |

Skill prune is also automatic: a skill with zero fires across two consecutive mining windows is
removed (git history keeps it recoverable), catalog regenerated in the same commit.

## Why staged for hooks

A bad blocking hook halts every session machine-wide; the shellcheck gate itself exists because
one quote bug crash-looped all six launchd services (2026-06-22). Observe-first keeps "automatic"
while capping the failure mode at "a log line was wrong" instead of "the machine is bricked".

## What still cannot auto-land

CI workflow changes, gate-strength changes to EXISTING gates, and anything outside `.md` +
`hooks/*.sh` observe-wrappers. Those remain issue-drafted (0026 rung-4 discipline): the loop may
not weaken its own containment.

## Rejected

- Keep owner approval (rejected by the owner directive above).
- Full unstaged hook autonomy (rejected: bricking precedent, no offsetting benefit - observe
  mode reaches blocking in a week anyway).
