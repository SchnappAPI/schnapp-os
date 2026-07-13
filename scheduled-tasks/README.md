# scheduled-tasks - the self-running layer

Routines that run **unattended** and report, without anyone opening a session. This directory is
the single source for *what* runs, *when*, on *which surface*, and *whether it may act on its own*.
The actual scheduling primitives are the owner's existing ones - GitHub Actions `cron` (cloud,
Mac-independent) and Mac LaunchAgents - not a new daemon. Anti-sprawl: reuse, don't rebuild.

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
| Learning worker (correction distill) | asks-first (gated) | LaunchAgent `com.schnapp.memory-consolidation` → `learning-worker.sh` | no (repo only) | [install section below](#launchagent-install---learning-worker-phase-4) |
| Memory consolidation | asks-first | SPEC ONLY - no runner yet | no (repo only) | [memory-consolidation.md](memory-consolidation.md) |
| Infra / pipeline health | safe (probe) | LaunchAgent → `check-infra-health.sh` (pure bash) | yes (launchctl/docker/ports) | [infra-health.md](infra-health.md) |
| Mac liveness (dead-man's-switch) | safe (probe) | GitHub Actions cron | no (pings the Mac from the cloud) | [mac-liveness.md](mac-liveness.md) |
| Caffeinate (hub availability) | safe (auto) | LaunchAgent → `caffeinate -s` | yes (holds the AC sleep assertion) | [caffeinate.md](caffeinate.md) |

The **safe, Mac-independent** routines are wired now in
[`.github/workflows/scheduled-routines.yml`](../.github/workflows/scheduled-routines.yml) via the
single-source bundle [`run-ci-routines.sh`](run-ci-routines.sh), which runs four read-only passes:
the doc-freshness sweep (the hard gate), the sync/unmerged check, a memory-freshness sweep
(`check-stale-facts.sh`), and the learning-loop eval (`learning-eval.sh`). The two that need the Mac or
judgment are specified here for a LaunchAgent to drive a `claude -p` session (owner installs the
LaunchAgent; the spec is the agent's instructions). The `status` skill reads the same
signals on demand.

## Why split CI vs LaunchAgent
GitHub Actions is the right host for repo-only, Mac-independent routines - it is the whole point of
schnapp-os that these do not depend on the Mac being awake. Anything that needs the Mac's MCP
(SQL Server, Flask, Docker, services) or LLM judgment runs from a Mac LaunchAgent that launches a
headless Claude session, reusing the existing connectors and skills.

---

## LaunchAgent install - learning-worker (Phase 4)

The nightly learning worker (`scripts/learning-worker.sh`) is scheduled via
[`com.schnapp.memory-consolidation.plist`](com.schnapp.memory-consolidation.plist). The plist uses
a `__REPO__` placeholder for the repo's absolute path (also its `WorkingDirectory`) and a `__HOME__`
placeholder for the log paths, so it can be committed without hard-coding the Mac's directory layout
or username.

**Policy: activation is owner-confirmed, production-Mac-only.** CI builds and unit-tests the worker
(`--dry-run`), but `launchctl load` runs on the production Mac only, via the `Schnapp_Mac` MCP,
after explicit owner approval. Never auto-loaded by CI or a cloud session.

### Headless auth (one-time prerequisite)

launchd cannot read the login Keychain (where interactive `/login` and `claude setup-token` store their
OAuth credentials), so the worker resolves its credential from **1Password at runtime** instead. The
LaunchAgent inherits `OP_SERVICE_ACCOUNT_TOKEN`, so `op read` works headless; the plist carries only the
op:// **reference** (`LEARNING_CLAUDE_TOKEN_REF`), never the value.

**Sanctioned credential: the subscription OAuth token**, `op://web-variables/CLAUDE_CODE_OAUTH_TOKEN/credential`
(an `sk-ant-oat…` token from `claude setup-token`). It bills the Claude **subscription**, not the metered
API (the cost-discipline default), and is verified to authenticate headless on CLI v2.1.112. Store the value
with **no surrounding whitespace or quotes** (a malformed copy once 401'd a valid token: see ADR 0019). It
expires ~yearly; re-mint via `claude setup-token`. `ANTHROPIC_API_KEY` (metered, non-expiring) is the
fallback; never leave both set. The full auth model, precedence, and 401 decoding are canonical in
[`docs/headless-claude-auth.md`](../docs/headless-claude-auth.md); read that before changing any of this.

### Install steps (run on the Mac, after explicit owner OK)

```bash
# 1. Substitute the repo path, home dir, and op:// token reference into the plist
REPO="$HOME/code/schnapp-os"   # adjust if different
TOKEN_REF="op://web-variables/CLAUDE_CODE_OAUTH_TOKEN/credential"   # subscription OAuth token (ADR 0019); worker auto-exports it as CLAUDE_CODE_OAUTH_TOKEN
sed -e "s|__REPO__|$REPO|g" -e "s|__HOME__|$HOME|g" -e "s|__CLAUDE_TOKEN_REF__|$TOKEN_REF|g" \
  "$REPO/scheduled-tasks/com.schnapp.memory-consolidation.plist" \
  > ~/Library/LaunchAgents/com.schnapp.memory-consolidation.plist

# 2. Create the log directory AND the queue file (WatchPaths needs the file to exist to arm)
mkdir -p ~/Library/Logs/schnapp-os
touch "$REPO/scheduled-tasks/.learning-queue.tsv"

# 3. Load the agent. RunAtLoad false - it fires WHEN the queue file changes (a capture is enqueued)
#    and every 30 min as a backstop. Re-run unload+load after any plist change.
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

The worker reads the local git-ignored queue (`scheduled-tasks/.learning-queue.tsv`), has a headless
`claude -p` distill each correction and write any proposed rule/fact edit to the working tree, then
GATES that diff with `learning-gate.sh` (no branches - ADR 0016): a clean self-edit is committed
straight to `main`; anything the gate holds is filed as a GitHub issue for review, never landing on
main. See
[memory-consolidation.md](memory-consolidation.md) for the asks-first consolidation policy and the
agent instructions that govern the live `claude -p` run.

---

## LaunchAgent install - vault-autocommit

`scripts/vault-autocommit.sh` sweeps the schnapp-vault working tree into git every 5 minutes
(commit + rebase-pull + push, main-only, 120s quiet-window debounce so it never commits
mid-edit; the vault's own pre-commit schema gate still applies and a rejected commit exits 2
with the tree left dirty). Closes the Phase-1 follow-up: Obsidian / obsidian-mcp edits no
longer wait for a human push. Plist: [com.schnapp.vault-autocommit.plist](com.schnapp.vault-autocommit.plist)
(same `__REPO__`/`__HOME__` render + owner-confirmed `launchctl load` policy as above).

```bash
REPO=~/code/schnapp-os
sed -e "s|__REPO__|$REPO|g" -e "s|__HOME__|$HOME|g" \
  "$REPO/scheduled-tasks/com.schnapp.vault-autocommit.plist" \
  > ~/Library/LaunchAgents/com.schnapp.vault-autocommit.plist
launchctl load ~/Library/LaunchAgents/com.schnapp.vault-autocommit.plist
launchctl list | grep com.schnapp.vault-autocommit   # verify
```

Health: `check-infra-health.sh` expects the label; failures show as launchd last-exit != 0 and
in `~/Library/Logs/schnapp-os/vault-autocommit.log`.
