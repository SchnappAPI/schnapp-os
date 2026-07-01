# 0025 — PLAN.md retired to a pointer

Date: 2026-07-01. Status: DECIDED (streamline Phase 4, T2). Executes decisions/0011 (backlog
reframing) to its conclusion. Mirrors decisions/0022 (PROGRESS.md rotation policy).

## Context
PLAN.md was the 11-Part build spine. That build is done: all Parts closed (PROGRESS.md). At 677
lines of finished work it rotted the same way PROGRESS.md rotted before 0022: its "Architecture"
block still described the pre-flatten, pre-vault state (`claude-kit/`, `memory/`, `presets/`), and
its few genuinely open threads were buried in prose rather than tracked where they'd be seen. Live
planning had already moved to per-initiative docs under `docs/superpowers/plans/`, each with its own
task checkboxes, making PLAN.md a stale duplicate of trackers that already exist elsewhere.

## Decision
Retire PLAN.md to a thin pointer. Archive its full text verbatim to
`docs/archive/PLAN-archive-<date>.md` (history, append-only, never edited after write — same
exemption as `decisions/` and `handoffs/`). The live pointer names where planning
(`docs/superpowers/plans/`), decisions (`decisions/`), status (`PROGRESS.md`), and the component
inventory (`CATALOG.md`) now live, and carries forward any thread that was genuinely still open and
recorded only in the archived plan. Before cutting, every open/pending/deferred/TODO signal in
PLAN.md was verified closed, superseded, or tracked elsewhere (ADR-0022 step 4 precedent); none
required carrying forward as a new open item.

## Consequences
- Live planning is per-initiative (`docs/superpowers/plans/`), each with its own checkboxes. The
  anti-stale "flip the PLAN.md box" now means flipping the matching per-initiative plan-doc box.
- Docs that cited PLAN.md as the status/tracker source (`CLAUDE.md`, `README.md`) now point at
  `PROGRESS.md` plus the live plan docs instead.
- No history lost: the full original is both in the archive and in git history. No active work
  lost: every open thread was verified closed or carried forward explicitly, none vanished.

## References
Executes decisions/0011 (backlog reframing). Mirrors decisions/0022 (PROGRESS.md rotation policy,
same archive-then-pointer shape). Archive: `docs/archive/PLAN-archive-2026-07-01.md`. Plan:
`docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md` (Phase 4, T2).
