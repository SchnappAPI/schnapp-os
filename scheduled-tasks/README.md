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

---

## LaunchAgent install — learning-worker (Phase 4)

The nightly learning worker (`plugins/core/scripts/learning-worker.sh`) is scheduled via
[`com.schnapp.memory-consolidation.plist`](com.schnapp.memory-consolidation.plist). The plist uses
a `__REPO__` placeholder for the repo's absolute path (also its `WorkingDirectory`) and a `__HOME__`
placeholder for the log paths, so it can be committed without hard-coding the Mac's directory layout
or username.

**Policy: activation is owner-confirmed, production-Mac-only.** CI builds and unit-tests the worker
(`--dry-run`), but `launchctl load` runs on the production Mac only, via the `Schnapp_Mac` MCP,
after explicit owner approval. Never auto-loaded by CI or a cloud session.

### Headless auth (one-time prerequisite)

`claude setup-token` stores the Claude OAuth token in the **login Keychain**, which a launchd job
cannot read — the live run 401s. So store the token in 1Password and let the worker resolve it via
`op` at runtime (the LaunchAgent inherits `OP_SERVICE_ACCOUNT_TOKEN`). The plist carries the op://
**reference** (`LEARNING_CLAUDE_TOKEN_REF`); the value is never written to disk.

```bash
# Mint a long-lived token (prints an sk-ant-oat... value), then store it in 1Password.
# Keep the value out of your shell history / any transcript — paste it into the op prompt only.
claude setup-token
op item create --category "API Credential" --vault Private \
  --title "Claude Code OAuth (memory-worker)" "credential[password]=<paste-token>"
# Your reference is then: op://Private/Claude Code OAuth (memory-worker)/credential
```

### Install steps (run on the Mac, after explicit owner OK)

```bash
# 1. Substitute the repo path, home dir, and op:// token reference into the plist
REPO="$HOME/code/schnapp-os"   # adjust if different
TOKEN_REF="op://Private/Claude Code OAuth (memory-worker)/credential"   # your reference
sed -e "s|__REPO__|$REPO|g" -e "s|__HOME__|$HOME|g" -e "s|__CLAUDE_TOKEN_REF__|$TOKEN_REF|g" \
  "$REPO/scheduled-tasks/com.schnapp.memory-consolidation.plist" \
  > ~/Library/LaunchAgents/com.schnapp.memory-consolidation.plist

# 2. Create the log directory if it doesn't exist
mkdir -p ~/Library/Logs/schnapp-os

# 3. Load the agent (RunAtLoad false — it will first fire at 03:17)
launchctl load ~/Library/LaunchAgents/com.schnapp.memory-consolidation.plist
```

### Verify it is loaded

```bash
launchctl list | grep com.schnapp.memory-consolidation
```

### Uninstall / disable

```bash
launchctl unload ~/Library/LaunchAgents/com.schnapp.memory-consolidation.plist
rm ~/Library/LaunchAgents/com.schnapp.memory-consolidation.plist
```

### What the worker does (asks-first policy)

The worker reads the local git-ignored queue (`scheduled-tasks/.learning-queue.tsv`), distills
each queued correction, and routes judgment-bearing ones through `self-edit-stage.sh` to open a PR.
It NEVER writes `memory/` or `plugins/core/rules/` directly. See
[memory-consolidation.md](memory-consolidation.md) for the asks-first consolidation policy and the
agent instructions that govern the live `claude -p` run.
