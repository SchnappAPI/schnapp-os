---
name: os-cross-surface-campaign
description: Use to run or resume the cross-surface enablement campaign - "make my rules/skills/memory work on every surface", "is the second brain fully enabled on claude.ai / iPhone / Cowork / a fresh Mac", "verify the web environment wiring (ADR 0033)", "did web-setup.sh take", "the portal might be down / PAT expired / bootstrap floor stale", "does memory persist from this surface", "what drift is monitored vs not", "audit surface enablement end to end", or when the owner signs in somewhere and something that works on the Mac is missing there. The executable, gate-by-gate campaign: baseline audit per surface, web user-scope verification, portal and bootstrap-floor health, memory continuity, proactive drift alerts, and validation criteria.
---

# os-cross-surface-campaign

Goal: the owner signs in on ANY surface and rules, skills, memory, and connectors are present,
current, and self-healing, with drift detected before the owner notices. This skill is the
campaign runbook: numbered phases, exact commands, the EXPECTED observation at every gate, and
the branch to take when you see something else.

Run phases in order on a first full pass. On a targeted complaint ("memory is dead on Cowork"),
jump to the matching phase but still run Phase 1 for that one surface first: never fix what you
have not baselined.

Paths below are this machine's clones (`/Users/schnapp/code/schnapp-os`,
`/Users/schnapp/code/schnapp-vault`); on another machine substitute that machine's clone paths
(default `~/code/...`).

## Definitions (once)

| Term | Meaning |
|---|---|
| Surface | A place the owner runs Claude: Claude Code on a Mac (hooked), Claude Code on the web (container), claude.ai chat, iPhone app, Cowork |
| Hooked vs hookless | Code on a Mac runs lifecycle hooks automatically; claude.ai, iPhone, and Cowork run none, so must-happen steps go through the `session-hygiene` skill |
| Portable shell | User-scope wiring (`shell/install.sh`, ADR 0033) that symlinks `~/.claude` to the two live clones; no snapshots, nothing copied |
| Schnapp Portal | One Cloudflare OAuth MCP connector at `https://mcp.schnapp.bet/mcp` fronting op-mcp, memory-mcp, mac-mcp, github-mcp; the claude.ai/iPhone tool path |
| Bootstrap floor (CORE) | The self-contained rules block pasted into claude.ai Preferences and Cowork instructions, canonical in `surfaces/always-loaded-instructions.md`; the fallback when the portal is down |
| Memory lane | The vault repo (`SchnappAPI/schnapp-vault`) `memory/` directory; schema in the vault's `agents.md`; supersede in place, never append |

## Phase 1: baseline audit per surface

Run `surface-check` (what is loaded HERE) on the surface under test, and `status` (whole-system
view) once per campaign. Do not restate those skills; this phase adds the per-surface gates and
expected observations.

### 1a. Hooked Mac (Claude Code, primary)

```bash
cd /Users/schnapp/code/schnapp-os
bash scripts/check-freshness.sh          # expect exit 0, no STALE lines
bash scripts/check-infra-health.sh       # Mac only; expect all green rows, exit 0
git -C /Users/schnapp/code/schnapp-os status -sb
git -C /Users/schnapp/code/schnapp-vault status -sb
```

Gate: at session start in ANY repo on the machine, a `[shell]` line appears (from
`hooks/global-session-gate.sh`, format `[shell] <os_status> | <vault_status> | <wiring>`), plus a
`[shell] memory: read .../MEMORY.md` line.

- See the `[shell]` line: wiring live. Proceed.
- No `[shell]` line: user-scope hooks not wired. Branch: run `bash /Users/schnapp/code/schnapp-os/shell/install.sh`, restart the session (hooks load at session start).
- `[shell] vault BACKLOG:` line: autocommit blocked. Branch: `bash /Users/schnapp/code/schnapp-os/scripts/vault-autocommit.sh` and read its error.
- `check-infra-health.sh` red rows: a LaunchAgent or port is down. Branch: `os-debugging-playbook` (launchd section); restart with `launchctl kill TERM gui/$(id -u)/<label>`, never `kickstart -k` (ADR 0010).

### 1b. Fresh Mac (or repair)

Owner block (needs GitHub auth on that machine):

```bash
mkdir -p ~/code && cd ~/code
git clone https://github.com/SchnappAPI/schnapp-os
git clone https://github.com/SchnappAPI/schnapp-vault
bash ~/code/schnapp-os/shell/install.sh
# verify:
grep -c schnapp-os ~/.claude/CLAUDE.md && ls -l ~/.claude/skills | head -3
```

Expected: installer ends `[shell-install] done. Wiring targets: OS=... VAULT=... CONFIG=...`;
symlinks in `~/.claude/skills` point into the clone; `~/.claude/CLAUDE.md` @imports the repo
rules. Then start a Claude Code session, accept the workspace-trust dialog (prerequisite, per the
installer's final line), and confirm the `[shell]` line per 1a.

- `WARN: no vault clone found`: memory Link B degraded. Branch: clone the vault, re-run the installer (it also sets the vault's `core.hooksPath` so memory commits are gated).
- `WARN: <kind>/<name> exists and is not our symlink`: a foreign file shadows a component. Resolve manually; never overwrite blind.
- Full Mac provisioning (LaunchAgents, tunnels): `shell/mac-setup.sh`, and `os-build-and-env` for the wider environment.

### 1c. Claude Code on the web (container)

Expected environment: the setup script (Phase 2) has run; both clones exist under `~/code`;
the network allowlist includes the hosts in `docs/environment-and-access.md` §1. Probe:

```bash
ls ~/code/schnapp-os/rules/global/ ~/code/schnapp-vault/memory/MEMORY.md
command -v op && op --version
```

- Clones missing: Phase 2 setup never ran or its ~7-day cache predates the paste. Branch: Phase 2.
- `schnapp-vault` missing but `schnapp-os` present: the web environment's GitHub access does not cover the vault repo; memory lane is silently dead there. Owner grants the env access to `SchnappAPI/schnapp-vault`, then re-run setup.
- MCP tools absent (mac-mcp etc.): almost always the network allowlist, not the connector; missing `mac-mcp.schnapp.bet` makes the proxy 403 CONNECT and tools silently vanish. Add the host per `docs/environment-and-access.md`. First call after Render idle can take ~50s: wait before declaring dead.
- Session arrives on a `claude/*` branch: the environment still carries a "Develop on branch" directive; work per ADR 0017 (merge to main the moment checks are green) and flag the config to the owner.

### 1d. claude.ai chat + iPhone (hookless)

Enablement checklist is `surfaces/claude-ai-web.md`; iPhone inherits the account-wide
Preferences paste. Probes to run IN that surface:

1. Portal live-read: through the Schnapp Portal connector, read
   `SchnappAPI/schnapp-os/rules/global/working-style.md`. Expected: current file content.
   Failure: Phase 3.
2. Memory: call the portal's `memory_health` tool. Expected: healthy response. Failure: Phase 4.
3. Floor currency: confirm the pasted CORE matches the current `## CORE` section of
   `surfaces/always-loaded-instructions.md` (read it live). Mismatch: Phase 3 re-paste block.
4. Never paste static skill copies; skills are read live via the connector
   (`surfaces/claude-ai-web.md` §2, thin stubs only).

### 1e. Cowork (hookless, agentic)

Same portal probes as 1d, plus:

- Seed currency: the per-session CLAUDE.md is auto-generated from
  `surfaces/always-loaded-instructions.md` by `scripts/sync-cowork-seed.sh` on every Claude Code
  SessionStart on the Mac. On the Mac:
  `bash /Users/schnapp/code/schnapp-os/scripts/sync-cowork-seed.sh` (silent = current;
  `resynced` = it was stale; `seed not found` = app reinstalled, set `SCHNAPP_COWORK_SEED`).
- Run `session-hygiene` at start and end of every Cowork session; connector writes are
  read-modify-write (whole-file replace).

## Phase 2: web user-scope wiring verification (ADR 0033's open question)

Status: VERIFIED YES 2026-07-18. First web session after the owner pasted the setup script showed
`[shell] schnapp-os: fresh | vault: fresh | wiring intact` plus the memory-orient line: the web
container honors `~/.claude` user-scope wiring; hooks, rules, and the memory gate are live on web.
Observed detail: the shell clones land under `$HOME/code` for the INIT user (`/root/code`), while
the session's working clone sits at `/home/user/<repo>`; the gate resolved wiring anyway. Residual
open item: the session's working clone still arrived pinned to a `claude/*` branch (no upstream),
so the ADR 0017 "Develop on branch" owner action stands. The procedure below is retained for
re-verification after any platform change (the result is an observation, not a guarantee).

1. Owner pastes the WHOLE of `shell/web-setup.sh` into the web environment's setup script
   (canonical copy lives in the repo; the paste is a projection, re-paste when the file changes).
   Requirements (verified against the script header): env vars `OP_SERVICE_ACCOUNT_TOKEN`,
   `MAC_MCP_AUTH_TOKEN`, `OP_MCP_BEARER`, `MEMORY_MCP_BEARER`; allowlist includes
   `my.1password.com`, `cache.agilebits.com`, `github.com`, `api.github.com`, and the
   schnapp/Render MCP hosts (`docs/environment-and-access.md` §1).
2. Start a fresh web session AFTER environment re-init (the setup result is cached ~7 days; a
   paste alone does not re-run it).
3. Read the gate: the decisive observation is a `[shell]` announce line at session start.

| Observation | Meaning | Branch |
|---|---|---|
| `[shell] ...` line present | Web honors user-scope wiring: hooks, rules, memory gate all live on web | Record the answer (Phase 6); ADR 0033's open question closes |
| `[web-setup]` output in init logs but no `[shell]` line in session | Setup ran; user scope is ignored on web | The documented boundary stands: web gets account-scope MCP + the container clones only. Record the answer; treat web as hookless for must-happen steps (`session-hygiene`) |
| `[web-setup] WARN: schnapp-os clone failed` | Env GitHub access misses the repo | Owner widens env repo access; re-init |
| `[web-setup] WARN: op CLI install failed` | Allowlist misses `cache.agilebits.com` | Non-fatal (op-mcp still resolves remotely); add the host to fix in-container `op://` |
| No `[web-setup]` output anywhere | Script not saved, or cache not refreshed | Re-paste, force env re-init, retry |

Either verdict is a result: land it as a dated memory fact plus a handoff line, and overwrite
any live doc that calls the question open (route via `os-change-control`). Past ADRs are frozen:
if the outcome changes a decision, that is a NEW ADR, never an edit or appended note on 0033.

## Phase 3: portal and bootstrap-floor health

The hookless surfaces' entire live layer hangs on the portal. A silent 403 or an expired PAT
does not error loudly: the surface just quietly falls back to the pasted floor, which then
slowly goes stale. Guarantee both legs.

### 3a. Detect portal failure

From any shell (both verified returning 200 on 2026-07-17):

```bash
curl -s -m 20 -o /dev/null -w '%{http_code}\n' https://op-mcp.onrender.com/health
curl -s -m 20 -o /dev/null -w '%{http_code}\n' https://memory-mcp-rtad.onrender.com/health
```

From the surface itself: the Phase 1d live-read probe. Discriminate:

| Symptom | Likely cause | Branch |
|---|---|---|
| Health URLs 200 but portal tools absent in claude.ai | Connector disabled or OAuth expired at the Cloudflare portal layer | Re-enable / re-auth Schnapp Portal in Settings > Connectors |
| github-mcp reads fail while other portal tools work | The all-repo PAT behind github-mcp expired or was revoked | `rotate-secret` for that PAT; update the Mac service env |
| memory-mcp tools fail | Its Render `GITHUB_TOKEN` PAT, or Render itself | `curl` its /health; then `connectors/memory-mcp/DEPLOY.md` |
| Health URLs non-200 | Render service down | `render-health` workflow already pages via GitHub issue; check the Render dashboard |
| First call hangs ~50s then works | Render free-tier cold start | Not a failure; the 30-min render-health cron doubles as keep-warm |
| A tool response looks like someone else's output | Known Cloudflare-layer misdelivery (ADR 0034), detection-only | `os-debugging-playbook`; evidence is the call_id echo + `mcp.err.log` |

### 3b. Re-paste triggers for the floor (CORE)

The pasted settings boxes are projections of `surfaces/always-loaded-instructions.md` and go
stale the moment that file changes. Deterministic trigger check:

```bash
git -C /Users/schnapp/code/schnapp-os log -1 --format='%h %ci' -- surfaces/always-loaded-instructions.md
```

If that commit is newer than the last known paste, the owner re-pastes: CORE into claude.ai
Settings > Profile > Preferences (account-wide, covers iPhone), CORE + Cowork block into Cowork
instructions. Cowork's seed leg self-heals via `sync-cowork-seed.sh`; the claude.ai Preferences
box has NO auto-sync and is the drift point. The trigger command above is the authority on the
last change. Last known paste: 2026-07-18, verified by quote-back of the live-read clause in a
fresh chat (matched the 6f74078 text incl. the repo-root skills path); any commit to the file
newer than that date means re-paste.

## Phase 4: memory continuity per surface

The guarantee: a fact written on any surface is readable on every other, and superseded facts
are replaced, never duplicated (vault `agents.md` schema; `rules/global/anti-stale.md`).

| Surface | Write path | Probe | Failure branch |
|---|---|---|---|
| Code Mac | autoMemoryDirectory + vault-autocommit (5 min) + SessionEnd vault push | `[shell] memory:` line at start; `git -C /Users/schnapp/code/schnapp-vault status -sb` clean and pushed | BACKLOG line: run `scripts/vault-autocommit.sh`, read the schema-gate error |
| Code web | Container vault clone + git push | `ls ~/code/schnapp-vault/memory/MEMORY.md` | Missing: Phase 1c vault-access branch |
| claude.ai / iPhone / Cowork | memory-mcp via portal (write path fixed 2026-07-13; full owner round-trip clean 2026-07-18: health, write, faithful read-back, delete incl. index line) | `memory_health`, then a round-trip: `memory_write` a scratch fact, `memory_read` it back, delete it | Tool absent: Phase 3a; write corrupts frontmatter: regression of the 2026-07-13 fix, treat as a bug not a config issue. Non-bug lookalike: the `supersedes` WRITE ARG (folded into `source:`) vs the `superseded:` frontmatter key are two different things; not a schema mismatch |
| Any Mac writing byte-exact | Shell redirect only | n/a | Edit/Write into the vault memory dir gets re-serialized by the harness in ~2s (ADR 0029); the vault pre-commit flattener contains it, but byte-exact writes go via `cat >` |

Supersede discipline is checked deterministically: `scripts/check-supersede-orphans.sh
/Users/schnapp/code/schnapp-vault/memory` prints one record per orphan (a fact whose
`supersedes:` target still exists), nothing when clean. It is frontmatter-aware and unit-tested
(the earlier column-0 version matched zero files; that class is fixed).

## Phase 5: proactive drift detection

What already alerts before the owner notices, and what does not. Wire nothing new without
Phase 6.

Monitored today (as of 2026-07-17):

| Probe | Cadence | Alert path |
|---|---|---|
| `mac-liveness.yml` (Mac platform reachable, Mac-independent) | 30 min cron | GitHub issue assigned to owner, auto-closes on recovery; test with `workflow_dispatch simulate=down` |
| `render-health.yml` (op-mcp + memory-mcp /health, doubles as keep-warm) | 30 min cron | Same issue mechanism |
| `com.schnapp.infra-health` (LaunchAgents, ports, backup age; pure bash by design) | Every 30 min + at load (StartInterval 1800) | GitHub issue via `scripts/ops-alert.sh` + ntfy (best-effort) |
| `scheduled-routines.yml` -> `scheduled-tasks/run-ci-routines.sh` (freshness hard gate, sync/unmerged, stale facts, learning eval, open owner items) | Nightly 08:17 UTC | Red workflow on hard-gate failure; Step Summary otherwise |
| `freshness.yml` + `ci-lint.yml` | Every push/PR | Red CI |
| `sync-cowork-seed.sh` | Every Mac Code SessionStart | Self-heals silently |

NOT monitored: candidates only, all OPEN, none built. Take each through Phase 6 before wiring:

- The portal layer itself (`mcp.schnapp.bet`): render-health probes the Render origins directly, so a Cloudflare-portal or OAuth failure is invisible until a surface probe fails.
- claude.ai Preferences CORE currency: no monitor compares the pasted box to the source file (the schnapp-console Surfaces tab was planned for this; never recorded shipped).
- Web environment wiring freshness: the ~7-day setup cache can outlive a `web-setup.sh` change with no signal.
- PAT expiry horizons: memory-mcp's Render `GITHUB_TOKEN`, github-mcp's all-repo PAT, and the ~2027-05 learning-worker OAuth re-mint have no dated alert beyond notes in `credentials-map.md`.
- `VAULT_READ_TOKEN` on the schnapp-os repo: possibly unset; the nightly sweep SKIPs its leg silently.
- Cowork seed drift on a machine where no Code session runs for days (the SessionStart sync never fires).
- obsidian-mcp's external endpoint: infra-health checks local port 8767 only; no off-Mac probe hits `obsidian-mcp.schnapp.bet`.

## Phase 6: validation and promotion

Nothing in this campaign is "done" by eye. Every claim of enablement gets a measurable check,
and every change lands through `os-change-control` (main-only, same-commit plan-box flip +
PROGRESS.md line, push immediately, `[~]` for partial).

Per-surface success criteria (the campaign is complete when all pass on the same day):

| Surface | Criterion (command or probe, must pass) |
|---|---|
| Hooked Mac | `[shell]` line at session start; `check-freshness.sh` exit 0; `check-infra-health.sh` exit 0 |
| Fresh Mac | 1b block runs clean end to end; first session shows the `[shell]` line |
| Code web | Phase 2 verdict recorded (either answer counts); both clones present; MCP tools listed |
| claude.ai chat | Live-read probe returns current rule text; `memory_health` OK; CORE paste date >= source's last commit date |
| iPhone | Same as claude.ai chat (shared account paste + portal) |
| Cowork | Seed sync reports current; memory round-trip passes; `session-hygiene` run recorded in the session's handoff |

Promotion of a Phase 5 candidate to a live monitor: state the drift it catches, the alert path,
and its own failure mode (a monitor that can die silently repeats the silent-stop class), then
land per `os-change-control` with a verify command in the same commit. Record campaign verdicts
as a dated vault memory fact (supersede the prior one) plus a handoff open-items update, so
`scripts/check-open-questions.sh` keeps surfacing what remains.

## Solution menu, ranked (with obligations)

For any "surface X lacks capability Y" gap, prefer in this order:

1. **Live read from the clone or connector** (symlink, @import, portal read). Obligation: none; live by construction. This is the default and the reason the shell exists.
2. **Auto-synced projection** (Cowork seed pattern: generated from the canonical file by a script a hook runs). Obligation: the sync script plus a currency check; acceptable only when the surface cannot read live.
3. **Manual paste with a deterministic re-paste trigger** (claude.ai CORE). Obligation: the Phase 3b trigger check every campaign pass; the paste must carry its own "read live first" clause.
4. **Generated owner prompt** (always-complete floor): hand a ready-to-run Code block. Obligation: verify the block before delivering.

Fenced off (do not re-litigate; evidence in `os-failure-archaeology`):

- **Plugin packaging of the shell/skills**: rejected twice on live evidence (snapshot pinning goes stale; ADRs 0024 and 0033). Any plugin-shaped delivery reintroduces the stale-pin class by construction.
- **Static pasted copies of rules or skills**: rejected; they drift and a small diff can flip a negation. The pasted CORE floor is the ONE sanctioned exception, and only because it carries the live-read clause.
- **`.claude/skills/` in the repo**: banned. Components live at repo root `skills/`, `agents/`, `commands/`; `.claude/` is wiring-only (single-registrar decision; a `.claude/skills/` copy double-loads).

## When NOT to use

- "What is loaded on THIS surface right now": `surface-check`.
- Whole-system health snapshot without an enablement campaign: `status`.
- Start/end/on-correction procedures on a hookless surface: `session-hygiene`.
- A specific broken thing (401, missing tools, dead hook, crash-looping service): `os-debugging-playbook`.
- Landing the changes this campaign produces: `os-change-control`; config locations and knobs: `os-config-and-flags`.
- Why the architecture forbids an approach you are tempted by: `os-architecture-contract`; whether it was already tried and failed: `os-failure-archaeology`.
- Concepts (how skills/hooks/MCP load at all): `agentic-os-reference`.
- Rotating a credential the campaign finds expired: `rotate-secret`.

## Provenance and maintenance

Drift-prone claims and their one-line re-verification (all verified 2026-07-17):

| Claim | Re-verify |
|---|---|
| `[shell]` announce-line format | `grep -n '\[shell\]' /Users/schnapp/code/schnapp-os/hooks/global-session-gate.sh` |
| web-setup env vars, allowlist, ~7-day cache, `[web-setup]` lines | `sed -n 1,20p /Users/schnapp/code/schnapp-os/shell/web-setup.sh` |
| Installer output lines, trust-dialog prerequisite, vault hooksPath | `grep -n 'done. Wiring\|trust dialog\|hooksPath' /Users/schnapp/code/schnapp-os/shell/install.sh` |
| Portal host + origin map | `grep -n 'mcp.schnapp.bet' /Users/schnapp/code/schnapp-os/docs/environment-and-access.md` |
| Render health URLs | `grep -n onrender /Users/schnapp/code/schnapp-os/.github/workflows/render-health.yml` |
| Health endpoints answer 200 | `curl -s -o /dev/null -w '%{http_code}\n' https://op-mcp.onrender.com/health` |
| Monitor cadences (30-min crons, nightly routines) | `grep -n cron /Users/schnapp/code/schnapp-os/.github/workflows/*.yml` |
| infra-health cadence + alert path | `plutil -p /Users/schnapp/code/schnapp-os/scheduled-tasks/com.schnapp.infra-health.plist \| grep -iE 'interval\|runatload'` and `grep -n 'ops-alert' /Users/schnapp/code/schnapp-os/scripts/check-infra-health.sh` |
| Cowork seed sync behavior | `sed -n 1,16p /Users/schnapp/code/schnapp-os/scripts/sync-cowork-seed.sh` |
| Supersede-orphan check is frontmatter-aware | `sed -n 1,18p /Users/schnapp/code/schnapp-os/scripts/check-supersede-orphans.sh` |
| Phase 2 verdict (web user scope VERIFIED YES 2026-07-18) still current | re-run the Phase 2 probe after any claude.ai platform change; vault fact `web-user-scope-verified` |
| memory-mcp write path fixed | vault memory fact `surfaces-live-read-default` + `git -C /Users/schnapp/code/schnapp-os log --oneline --grep=memory-mcp -5` |

Unverified or open, labeled as such above: Phase 2's verdict (unexecuted); whether the CORE was
re-pasted after its last change; `VAULT_READ_TOKEN` set or not; memory-mcp's PAT scope; every Phase 5
candidate. When Phase 2 executes, update Phase 2 and the Phase 6 table here in the same commit
that records the verdict.
