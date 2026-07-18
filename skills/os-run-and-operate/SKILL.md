---
name: os-run-and-operate
description: Use to OPERATE the running schnapp-os system - "restart mac-mcp / obsidian-mcp", "is the connector up", "where are the logs", "redeploy op-mcp / memory-mcp on Render", "what jobs run on a schedule and where does their output go", "why did a [mac-liveness] or [render-health] GitHub issue open (or not close)", "the nightly learning worker / vault autocommit did or did not run", "check the portal (mcp.schnapp.bet)", "which launchd service serves port 8765/8767". Runbooks with verify lines for the connector fleet, launchd services, Render deploys, scheduled jobs, health probes, and the auto-issue alarm mechanism.
---

# os-run-and-operate

Operating the LIVE system: what runs where, how to restart it, where output lands, and how the
system alarms when something dies. Every port, label, URL, and path below was verified against
repo files (as of 2026-07-17). Absolute paths refer to this machine's clones at
`/Users/schnapp/code/schnapp-os` and `/Users/schnapp/code/schnapp-vault` (path = this machine's
clone; another Mac substitutes its own `~/code/...`).

Jargon, once:
- **Connector**: an MCP (Model Context Protocol) server exposing tools to Claude surfaces.
- **launchd / LaunchAgent**: macOS's service manager / a per-user service definition (`.plist`).
- **cloudflared tunnel**: outbound tunnel publishing a Mac-local port at a `*.schnapp.bet` URL.
- **Portal**: the Cloudflare One MCP-server portal at `mcp.schnapp.bet`, the OAuth front
  claude.ai/iPhone use ("Schnapp Portal" connector).
- **Render**: the free cloud host running the two Mac-independent connectors.

## 1. The connector fleet

| Server | Host | Service / port | URL | Log |
|---|---|---|---|---|
| op-mcp (1Password resolver) | Render | Render web service | `https://op-mcp.onrender.com` (`/mcp`, `/health`) | Render dashboard logs |
| memory-mcp (vault memory lane) | Render | Render web service | `https://memory-mcp-rtad.onrender.com` (`/mcp`, `/health`) | Render dashboard logs |
| mac-mcp (Mac shell/SQL/files/services) | Mac | launchd `com.schnapp.macmcp`, port 8765 | `https://mac-mcp.schnapp.bet/mcp` | `~/mac-mcp/mcp.log`, `~/mac-mcp/mcp.err.log` |
| obsidian-mcp (Obsidian vault notes) | Mac | launchd `com.schnapp.obsidian-mcp`, port 8767 | `https://obsidian-mcp.schnapp.bet/mcp` | `~/obsidian-mcp/obsidian-mcp.log` |
| github-mcp (GitHub repo/issue/PR/Actions ops) | GitHub (official MCP server) | none - no Mac service (ADR 0036) | `https://api.githubcopilot.com/mcp/`, reached via the portal's github-mcp slot (portal-side Authorization = `GITHUB_PAT` + `X-MCP-Toolsets` headers) | GitHub-side; nothing local |

Note the label inconsistency: `com.schnapp.macmcp` has no hyphen;
`com.schnapp.obsidian-mcp` does. Copy exactly.

How clients reach them:
- **claude.ai web + iPhone**: the portal `https://mcp.schnapp.bet/mcp` fronts the
  static-bearer servers (op-mcp, memory-mcp, mac-mcp) plus GitHub's official github-mcp behind one
  OAuth connector (decisions/0020, 0036). obsidian-mcp is static-bearer too since 2026-07-18
  (`OBSIDIAN_MCP_AUTH_TOKEN`); its portal slot is a pending owner add.
- **Claude Code / Cowork**: direct origin URLs with bearer headers from env vars, per the
  repo-root `.mcp.json` (server names `Schnapp_Mac`, `Schnapp_Secrets`, `Schnapp_Memory`).
- Source of truth for each Mac server is this repo: `~/<svc>/server.py` is a symlink to
  `connectors/<svc>/server.py`. Edit in the repo, then restart the service to deploy.

Render free-tier fact: services sleep after ~15 min idle; first call cold-starts in ~30-60s.
The render-health cron (section 6) doubles as keep-warm.

## 2. Restart a Mac connector (graceful TERM, never kickstart -k)

Canonical rule: decisions/0010-mcp-graceful-restart-bind-race.md. `launchctl kickstart -k`
SIGKILLs, which once caused a ~2 min `[Errno 48]` bind-race crash loop. Graceful TERM lets
uvicorn close the socket; KeepAlive relaunches in ~3s.

```bash
# pick ONE label: com.schnapp.macmcp | com.schnapp.obsidian-mcp
launchctl kill TERM gui/$(id -u)/com.schnapp.macmcp
sleep 5
# verify: port LISTENing again and the label loaded
lsof -nP -iTCP:8765 -sTCP:LISTEN && launchctl list | grep com.schnapp.macmcp
```

Ports: 8765 mac-mcp, 8767 obsidian-mcp.

CAUTION when operating remotely: if your session reaches the Mac THROUGH mac-mcp (claude.ai,
cloud), restarting mac-mcp in the foreground severs your own channel. Restart it via a detached
double-fork daemon, or from a local Mac shell (ADR 0010 "surface correction"; handoffs 020/021).
obsidian-mcp is safe to restart through mac-mcp.

The mac-mcp `service_restart` tool defaults to this graceful mode; `mode='hard'` keeps
`kickstart -k` and is for last resort only.

## 3. Logs: what lands where

| Producer | Log |
|---|---|
| mac-mcp | `~/mac-mcp/mcp.log` (stdout), `~/mac-mcp/mcp.err.log` (per-call `call_id` ledger, redacted inputs; ADR 0034 misdelivery evidence) |
| obsidian-mcp | `~/obsidian-mcp/obsidian-mcp.log` |
| learning worker | `~/Library/Logs/schnapp-os/memory-consolidation.log` + `.err.log` |
| infra-health probe | `~/Library/Logs/schnapp-os/infra-health.log` + `.err.log` |
| vault-autocommit | `~/Library/Logs/schnapp-os/vault-autocommit.log` (out+err combined) |
| caffeinate | `~/Library/Logs/schnapp-os/caffeinate.log` + `.err.log` |
| CI routines (cloud) | GitHub Actions job Step Summary (never commits) |
| Render pair | Render dashboard only (no Mac-side log) |

mac-mcp logs are truncated in place at 10 MB by `com.schnapp.macmcp.logrotate` running
`~/mac-mcp/rotate_logs.sh` (live copy on the Mac; repo mirror `connectors/mac-mcp/rotate_logs.sh`).
The mac-mcp launchd plist itself is NOT repo-tracked (documented in `connectors/mac-mcp/README.md`).

## 4. Deploy / redeploy

**Rules, skills, hooks: `git push` IS the deploy.** Every surface reads the repo live (portable
shell symlinks, portal raw reads). Nothing to restart.

**Mac connectors**: edit `connectors/<svc>/server.py` in the repo, commit+push (main only, see
`os-change-control`), then graceful-restart the service (section 2). The symlink makes the
restart the deploy.

**op-mcp (Render, blueprint)**: defined by repo-root `render.yaml` (Docker build of
`connectors/op-mcp/Dockerfile`, `rootDir: connectors/op-mcp`, health check `/health`).
`autoDeployTrigger: off` in render.yaml, so a push does NOT auto-deploy: redeploy manually in the
Render dashboard (service op-mcp, Manual Deploy). Secrets (`OP_SERVICE_ACCOUNT_TOKEN`,
`OP_MCP_BEARER`) live only in Render env, `sync: false`. Full first-time runbook incl. the
Cloudflare portal front: `connectors/op-mcp/DEPLOY.md`.

**memory-mcp (Render, manual web service, NOT in render.yaml)**: created by hand per
`connectors/memory-mcp/DEPLOY.md` (Root Directory `connectors/memory-mcp`, Docker, env
`GITHUB_TOKEN` + `MEMORY_MCP_BEARER`, optional `MEMORY_REPO`/`MEMORY_BRANCH`/`MEMORY_DIR`
defaulting to `SchnappAPI/schnapp-vault`/`main`/`memory`). Whether its auto-deploy-on-push is on
is unverified from the repo; confirm in the Render dashboard before assuming a push shipped.

```bash
# verify either Render service after a deploy
curl -s https://op-mcp.onrender.com/health            # {"status":"ok",...}
curl -s https://memory-mcp-rtad.onrender.com/health   # {"status":"ok",...}
```

## 5. Scheduled jobs inventory

Full spec directory: `scheduled-tasks/README.md` (classification safe vs asks-first lives there).

### Mac LaunchAgents (plists in `scheduled-tasks/`, owner-armed, never CI-loaded)

| Label | Cadence | Runs | Output / failure surface |
|---|---|---|---|
| `com.schnapp.memory-consolidation` | WatchPaths on `scheduled-tasks/.learning-queue.tsv` + every 30 min backstop | `scripts/learning-worker.sh` (section 5a) | `~/Library/Logs/schnapp-os/memory-consolidation.log`; holds become GitHub issues |
| `com.schnapp.infra-health` | every 30 min + at load | `scripts/check-infra-health.sh` (pure bash probe) | `~/Library/Logs/schnapp-os/infra-health.log`; RED = macOS notification + ntfy + nonzero exit |
| `com.schnapp.vault-autocommit` | every 5 min | `scripts/vault-autocommit.sh` (section 5b) | `~/Library/Logs/schnapp-os/vault-autocommit.log`; gate rejection = exit 2 |
| `com.schnapp.caffeinate` | continuous | `caffeinate -s` (AC-only sleep hold; the Mac is the tunnel hub) | `~/Library/Logs/schnapp-os/caffeinate.log` |

Install/uninstall runbooks (the `__REPO__`/`__HOME__` sed render + `launchctl load`) are canonical
in `scheduled-tasks/README.md` and `scheduled-tasks/infra-health.md`; do not improvise them.

```bash
# verify what is armed right now
launchctl list | grep -E 'com\.schnapp|bet\.schnapp'
```

### GitHub Actions cron (cloud, Mac-independent)

| Workflow | Schedule | Does | Output |
|---|---|---|---|
| `scheduled-routines.yml` | nightly 08:17 UTC + manual dispatch | `scheduled-tasks/run-ci-routines.sh`: five read-only passes (doc-freshness hard gate, sync/unmerged, stale memory facts, learning-loop eval, open owner items) | job Step Summary; red ONLY on the freshness gate |
| `mac-liveness.yml` | every 30 min | probes `https://schnapp.bet` then `https://mac-flask.schnapp.bet`; the dead-man's-switch for the Mac platform | `[mac-liveness]` GitHub issue (section 6) |
| `render-health.yml` | every 30 min | probes both Render `/health` URLs; keep-warm + alarm | `[render-health]` GitHub issue (section 6) |
| `freshness.yml` | every push + PR | freshness gate, test suite, links, plist validation, secret + stale-note scans | red check on the commit |
| `ci-lint.yml` | push to main + PR | writing-style lint | red check on the commit |

The nightly stale-facts sweep can only scan the vault when the repo secret `VAULT_READ_TOKEN` is
set on SchnappAPI/schnapp-os; without it that pass reports SKIP, never a false OK.

### 5a. The nightly learning worker

`scripts/learning-worker.sh` (header comments are the authoritative spec; ADRs 0021/0026/0028):
drains the git-ignored queue `scheduled-tasks/.learning-queue.tsv` (fed by `hooks/capture-nudge.sh`),
runs a bounded Agent SDK distill (`scripts/learning_distill.py`, file tools only, no Bash),
then `scripts/learning-gate.sh` auto-lands only clean small `.md` diffs: rule edits to this repo's
main, fact edits to the VAULT's main via a worker-owned clone at
`~/.cache/schnapp-os/learning-vault` (never the live vault tree). Anything held becomes a GitHub
issue. Recurring error classes (>= 2) draft a gate-proposal issue instead of prose.
`--dry-run` exercises the plumbing with no network/git.

```bash
# did it run, and cleanly?
tail -30 ~/Library/Logs/schnapp-os/memory-consolidation.log
wc -l /Users/schnapp/code/schnapp-os/scheduled-tasks/.learning-queue.tsv 2>/dev/null  # 0/absent = drained
```

Headless auth for the worker is the subscription OAuth token resolved from 1Password at runtime;
canonical doc `docs/headless-claude-auth.md`. Never wire the metered `ANTHROPIC_API_KEY` alongside it.

### 5b. Vault autocommit

`scripts/vault-autocommit.sh` sweeps `/Users/schnapp/code/schnapp-vault` into git every 5 min:
add + commit + rebase-pull + push, main-only, 120s quiet-window debounce, mkdir-mutex serialized.
The vault's own pre-commit schema gate still applies; a rejection leaves the tree dirty and exits 2
(visible as launchd last-exit != 0). Exit codes: 0 ok, 1 precondition, 2 commit blocked, 3 push/pull.

```bash
tail -20 ~/Library/Logs/schnapp-os/vault-autocommit.log
cd /Users/schnapp/code/schnapp-vault && git status --porcelain   # empty = swept
```

## 6. Health probes and the auto-issue mechanism

Three layers, deliberately independent (the probe must not depend on what it watches):

1. **On-Mac**: `com.schnapp.infra-health` runs `scripts/check-infra-health.sh` every 30 min.
   Checks the expected LaunchAgent labels (list in the script, override
   `INFRA_EXPECTED_AGENTS`), bacpac backup age (< 8 days), the `mssql` Docker container, and
   ports 8765/8767 LISTENing. RED: logs, macOS-notifies, pages via ntfy
   (`scripts/notify-ops.sh` when `NTFY_URL` is set), exits nonzero. NEVER remediates.
2. **Cloud watching the Mac**: `mac-liveness.yml`, the dead-man's-switch: if `schnapp.bet` stops
   answering, infra-health is presumed dead too.
3. **Cloud watching Render**: `render-health.yml` for op-mcp + memory-mcp.

Auto-issue open/close (workflows 2 and 3, and `scripts/ops-alert.sh` for Mac routines):
- On DOWN: open ONE GitHub issue on SchnappAPI/schnapp-os assigned to `SchnappAPI`, deduped by
  title prefix (`[mac-liveness]`, `[render-health]`, or `[<key>]` for ops-alert). While still
  down, later runs COMMENT on the existing issue, never open a second.
- On recovery: the next green run comments and auto-closes the issue. An open issue with one of
  these prefixes therefore means "still down (or the closer has not run yet)": do not close it by
  hand unless you have verified recovery yourself.
- Test the alarm path without an outage: run the workflow manually with input `simulate=down`
  (`gh workflow run mac-liveness.yml -f simulate=down`).
- ops-alert state lives at `~/.config/schnapp-os/state/<key>.state`; Mac-local config
  (NTFY_URL, GH_TOKEN) at `~/.config/schnapp-os/ops.env`.

## 7. Checking the portal (mcp.schnapp.bet)

The portal fronts op-mcp + memory-mcp + mac-mcp + github-mcp (GitHub's official server, ADR 0036)
for claude.ai/iPhone (ADR 0020).
A silently broken portal drops those surfaces to their pasted bootstrap floor, so check it when
claude.ai tools vanish.

- From claude.ai (through the Schnapp Portal connector): call `portal_list_servers`: all four
  servers should show enabled; then `op_health` and `memory_health` should return authenticated.
- From any shell (unauthenticated liveness only; verified 2026-07-17):

```bash
curl -s -o /dev/null -m 20 -w '%{http_code}\n' https://mcp.schnapp.bet/mcp    # 401 = portal up, auth gate intact
curl -s -o /dev/null -m 20 -w '%{http_code}\n' https://mac-mcp.schnapp.bet/mcp # 406 = origin up (no Accept header sent); 000/5xx = tunnel or service down
```

- Portal config lives in the Cloudflare One dashboard (Access controls > AI controls), not in
  this repo. Changing it is an owner-console action; the repo runbook is
  `connectors/op-mcp/DEPLOY.md` steps 4-5.

Trust note: portal-relayed mac-mcp responses are self-identifying (`call_id` + echoed command,
ADR 0034). Confirm the echo matches what you sent before trusting output.

## 8. When NOT to use this skill

- Diagnosing a SYMPTOM (401s, missing tools, crash loops, hung calls): `os-debugging-playbook`.
- One aggregated health view instead of per-service runbooks: the `status` skill (read-only).
- What is loaded on THIS surface: `surface-check`.
- Finding or changing configuration (env vars, hooks wiring, `.mcp.json`, plist knobs):
  `os-config-and-flags`.
- Installing on a fresh machine / environment setup: `os-build-and-env` and `shell/install.sh`.
- Landing a change (commit discipline, gates, ADRs): `os-change-control`.
- Rotating a bearer or leaked credential: `rotate-secret`. Resolving a secret value: `vault-resolve`.
- Why the architecture is shaped this way: `os-architecture-contract`; past incidents:
  `os-failure-archaeology`; component-model theory: `agentic-os-reference`.

## Provenance and maintenance

Drift-prone claims and their re-verification commands (all as of 2026-07-17):

| Claim | Re-verify |
|---|---|
| Service labels + ports 8765/8767 | `grep -n "PORT_CHECKS\|com.schnapp" /Users/schnapp/code/schnapp-os/scripts/check-infra-health.sh` |
| Restart = graceful TERM, never kickstart -k | `sed -n '1,30p' /Users/schnapp/code/schnapp-os/decisions/0010-mcp-graceful-restart-bind-race.md` |
| Render URLs + /health OK | `curl -s https://op-mcp.onrender.com/health; curl -s https://memory-mcp-rtad.onrender.com/health` |
| op-mcp auto-deploy is OFF | `grep autoDeployTrigger /Users/schnapp/code/schnapp-os/render.yaml` |
| mac-mcp log paths + 10 MB rotation | `cat /Users/schnapp/code/schnapp-os/connectors/mac-mcp/rotate_logs.sh` |
| LaunchAgent cadences (1800/300s, WatchPaths) | `grep -A2 "StartInterval\|WatchPaths" /Users/schnapp/code/schnapp-os/scheduled-tasks/*.plist` |
| LaunchAgent log paths | `grep -A1 "StandardOutPath\|StandardErrorPath" /Users/schnapp/code/schnapp-os/scheduled-tasks/*.plist` |
| Cron schedules (08:17 UTC nightly, */30 probes) | `grep -n "cron" /Users/schnapp/code/schnapp-os/.github/workflows/*.yml` |
| Issue title prefixes + simulate input | `grep -n "TITLE=\|simulate" /Users/schnapp/code/schnapp-os/.github/workflows/mac-liveness.yml /Users/schnapp/code/schnapp-os/.github/workflows/render-health.yml` |
| Learning worker queue/gate/clone paths | `sed -n '1,80p' /Users/schnapp/code/schnapp-os/scripts/learning-worker.sh` |
| Portal topology (four slots; github = official server) | `sed -n '1,30p' /Users/schnapp/code/schnapp-os/decisions/0020-portal-front-mac-github-mcp.md; sed -n '1,40p' /Users/schnapp/code/schnapp-os/decisions/0036-github-mcp-official-swap.md` |
| .mcp.json server names + origin URLs | `cat /Users/schnapp/code/schnapp-os/.mcp.json` |

Left unverified in this skill (labeled inline): memory-mcp's Render auto-deploy-on-push setting
(dashboard-only fact); the portal's Cloudflare-side config (console-only).
