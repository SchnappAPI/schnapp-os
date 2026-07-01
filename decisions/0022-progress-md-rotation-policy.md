# 0022 — PROGRESS.md rotation policy

Date: 2026-06-30. Status: DECIDED (agent judgment; owner explicitly delegated the mechanics:
"you are an expert in this, why are you asking me").

## Context
`PROGRESS.md` reached 1281 lines. The header spec ("append one line per step") had drifted —
recent entries were 10-15 line paragraphs. No agent reads the full file each session; things
were being silently overlooked. Confirmed, not hypothetical: two "still open" items from the
2026-06-23 section — `#2` repo-flattening (decisions/0011) and the `brain-capture` MCP server
prune — were never closed anywhere in the file and would have been buried further by ordinary
growth. Owner asked for a reflection point on the approach, then declined to pick the
trigger/retention mechanics, asking the agent to decide instead.

## Decision
1. **Trigger: size threshold, ~600 lines.** When `PROGRESS.md` exceeds ~600 lines, reconcile
   it. Not calendar-based (bloat doesn't track the calendar) and not per-Part (Parts stopped
   being the organizing unit once decisions/0011 reframed `PLAN.md` as a backlog, not the spine).
2. **Backup: full verbatim snapshot to `docs/archive/`, every time — not just the closed
   portion.** Recent entries aren't all backed by a `handoffs/` file; archiving only the "old"
   part would destroy information that exists nowhere else. Naming:
   `PROGRESS-archive-<oldest-date>-to-<newest-date>.md`. History artifact, append-only, never
   edited after write (anti-stale.md exemption, same as `decisions/` and `handoffs/`).
3. **Retention: current era only, compressed to true one-liners.** "Current era" = the window
   still worth skimming (this rotation: the 2026-06-23 decisions/0011 pivot forward). Fully
   closed, superseded-by-ADR material collapses to a short pointer-summary; nothing still open
   collapses away silently.
4. **Before cutting, grep every "still open" / "pending" / "deferred" mention in the range
   being archived for a later resolution.** Anything never closed gets an explicit "Open items
   carried forward" line in the new live file. This step is what caught the two items above.

## Why this shape
The failure mode was never data loss — git history already makes `PROGRESS.md` fully
recoverable at any point. The failure mode is a live file too long to actually read, which lets
open items rot invisibly. The fix optimizes for the live file being something an agent (or the
owner) can skim in one read, while keeping full fidelity one hop away: the archive, git history,
and — for anything with real narrative weight — `handoffs/`, which already serves as the dense
per-session record this file kept redundantly duplicating.

## Not decided here
Same-class flag, not acted on: `PLAN.md` (675 lines) has the identical unbounded-growth shape.
No rotation policy for it yet.
