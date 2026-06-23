---
name: status
description: Use when the user asks "what's the state of everything", "status", "is anything stale/unmerged/unpushed", "are the connectors/services up", "when was the last backup", or wants a whole-system health view across surfaces before planning work. The cross-surface control plane — aggregates git, doc-freshness, memory, backup, connector/service health, and per-surface enablement into one view. Where surface-check answers "what's loaded HERE", status answers "what's the state of the WHOLE system".
---

# status

The control plane (PLAN Part 11.3). One view of the whole schnapp-os system: what is stale,
unmerged, or unpushed; whether the scheduled routines are healthy; whether connectors and services
are up; when the last backup ran; and which surfaces are enabled. Builds on — does not duplicate —
[`surface-check`](../surface-check/SKILL.md): surface-check reports the **current** surface;
`status` aggregates across **all** of them. **Probe every signal; never assume** (global rule
[`verify-before-asserting`](../../rules/global/verify-before-asserting.md)). State which signals you
could not read on this surface and the route to read them, rather than guessing.

## Signals to gather (probe each; skip-with-reason if the surface can't)

| Domain | What to read | How (this surface → fallback) |
|---|---|---|
| **Git / unmerged** | branches ahead of `main`, unpushed commits, dirty tree | Code: `scheduled-tasks/run-ci-routines.sh` (sync section) or `git`; web/iPhone: GitHub connector (list branches, compare to main) |
| **Doc freshness** | is `CATALOG.md` current; any stale `last-verified:` | Code: `plugins/core/scripts/check-freshness.sh`; else last `freshness` + `scheduled-routines` workflow run |
| **Scheduled routines** | did the nightly `scheduled-routines` run pass | GitHub Actions: latest run of `.github/workflows/scheduled-routines.yml` (Step Summary) |
| **Memory** | duplicate/contradictory/stale facts; supersede-orphans | read `memory/` + the freshness gate's supersede check; the consolidation routine's last proposal |
| **Backup** | age of the last archive; did a non-Mac session's work reach OneDrive + the vault | Mac connector `backup_status`; obsidian connector searchability probe |
| **Connectors / services** | op-mcp, GitHub, obsidian, mac (8765/66/67); SQL Server, Flask, site, runner, tunnels | Mac connector `service_status`/`site_health`/`tunnel_status`/`op_health`; else the infra-health routine's last report |
| **Per-surface enablement** | which of Code / claude.ai / iPhone / Cowork have rules+skills+connectors wired | the `surfaces/*.md` profiles vs what each reports; Part 10.2 state |

## Report

A compact table — **Domain | State | Detail | Action needed** — with a clear OK / WARN / BLOCKED per
row. Then a one-line verdict and the **single most important next action** (e.g. "1 branch unmerged
— merge PR #N", "backup 3 days stale — run backup-archive on the Mac", "all green").

Rules:
- Read-only. `status` never merges, deletes, restarts, or mutates — it reports and points at the
  skill/command that would act (`merge-with-discretion`, `/clean-gone`, the infra-health routine).
- Distinguish "WARN: real drift" from "could not read on this surface" — never let an unreadable
  signal look green. Name the fallback for each gap (same always-complete discipline as
  `surface-check`).
- Cross-reference the scheduled routines: if the nightly `scheduled-routines` run is green, trust
  its freshness + sync findings instead of re-deriving them; if it has not run or is red, say so.
