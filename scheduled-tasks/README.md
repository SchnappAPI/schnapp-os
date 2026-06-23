# scheduled-tasks — the self-running layer (PLAN Part 11.1)

Routines that run **unattended** and report, without anyone opening a session. This directory is
the single source for *what* runs, *when*, on *which surface*, and *whether it may act on its own*.
The actual scheduling primitives are the owner's existing ones — GitHub Actions `cron` (cloud,
Mac-independent) and Mac LaunchAgents — not a new daemon. Anti-sprawl: reuse, don't rebuild.

## Safety policy (non-negotiable)
Every routine is classified, and the classification decides whether it may run on its own:

- **safe (auto):** read-only or idempotent-and-reversible, no data/money/production mutation.
  Runs unattended and reports. Examples: doc-freshness sweep, sync/unmerged check, health probes,
  read-only memory review.
- **asks-first (queued):** anything that mutates data, money, or production, or that needs
  judgment (a memory *rewrite*, a merge, a deploy, a schema change). The routine does NOT act; it
  detects the condition and **queues** a report/prompt for an interactive session to approve.

This mirrors the rest of schnapp-os: never silently fail, never silently mutate. A scheduled
routine that wants to change state stops at the proposal and hands it to a human-approved session.

## Where results go
- **CI routines** (GitHub Actions): write a report to the job's **Step Summary** every run; exit
  non-zero only when a hard gate fails (so the failure is visible). No surprise commits.
- **Mac/agent routines** (LaunchAgent → a `claude -p` session): persist findings to the repo
  (a memory note, a handoff, or PROGRESS) via the normal end-of-session write, and notify.
- Nothing here mutates the repo automatically beyond an explicit, reviewed report path.

## Surface mapping (which scheduler runs which)
| Routine | Class | Scheduler | Needs Mac? | Spec |
|---|---|---|---|---|
| Doc-freshness sweep | safe | GitHub Actions cron | no | [doc-freshness-sweep.md](doc-freshness-sweep.md) |
| Sync / unmerged check | safe | GitHub Actions cron | no | [sync-unmerged-check.md](sync-unmerged-check.md) |
| Memory consolidation | asks-first | LaunchAgent → `claude -p` | no (repo only) | [memory-consolidation.md](memory-consolidation.md) |
| Infra / pipeline health | safe (probe) | LaunchAgent → `claude -p` | yes (Mac MCP) | [infra-health.md](infra-health.md) |

The two **safe, Mac-independent** routines are wired now in
[`.github/workflows/scheduled-routines.yml`](../.github/workflows/scheduled-routines.yml) via the
single-source bundle [`run-ci-routines.sh`](run-ci-routines.sh). The two that need the Mac or
judgment are specified here for a LaunchAgent to drive a `claude -p` session (owner installs the
LaunchAgent; the spec is the agent's instructions). The `status` skill (Part 11.3) reads the same
signals on demand.

## Why split CI vs LaunchAgent
GitHub Actions is the right host for repo-only, Mac-independent routines — it is the whole point of
schnapp-os that these do not depend on the Mac being awake. Anything that needs the Mac's MCP
(SQL Server, Flask, Docker, services) or LLM judgment runs from a Mac LaunchAgent that launches a
headless Claude session, reusing the existing connectors and skills.
