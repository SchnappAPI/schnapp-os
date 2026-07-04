# schnapp-os

Central, multi-surface Claude system: skills, commands, hooks, agents, composable rules,
memory, and credential references, usable on Claude Code (all machines), Cowork, and
claude.ai. One source of truth. No duplication. Nothing siloed. References to secrets only,
never values. Private repo.

## Live status - do not duplicate here
This README states no progress/status (status hardcoded in a README is the classic stale doc).
Status lives in one canonical place and is read there:
- **[PLAN.md](PLAN.md)**: pointer to where live planning now lives (per-initiative under
  `docs/superpowers/plans/`, each with its own step boxes) plus the archived original build plan.
- **[PROGRESS.md](PROGRESS.md)**: running execution log, newest at the bottom of each day.

## Map
| Path | What |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Agent front door for working in this repo (thin, reference-only; global rules load separately) |
| [PLAN.md](PLAN.md) | Pointer to the archived build plan + where live planning now lives |
| [PROGRESS.md](PROGRESS.md) | Execution log |
| [decisions/](decisions/) | One file per decision (the "why") |
| [handoffs/](handoffs/) | Dated session handoffs; the newest, highest-numbered is the resume point |
| [rules/](rules/) | Rules - `global/` (always-on) + `modules/` (path-scoped lang, tool, activity, context - a plain reference library) |
| [CATALOG.md](CATALOG.md) | Generated inventory of rules/skills/commands/hooks (do not edit; `gen-catalog.sh`) |
| [templates/](templates/) | `project-CLAUDE.md` (manual project starter) + `user-global-CLAUDE.md` (the `~/.claude/CLAUDE.md` source, rendered by the shell installer) |
| [shell/](shell/) | The portable shell: wiring-only installer linking every session to the two live repos (ADR [0033](decisions/0033-portable-shell-user-scope-wiring.md)) |
| [surfaces/](surfaces/) | One operating profile per surface (Code, Cowork, claude.ai, iPhone) |
| [connectors/](connectors/) | Remote MCP connectors - `op-mcp` (1Password resolver), `memory-mcp` (cross-surface memory), `mac`/`github`/`obsidian-mcp` |
| [hooks/](hooks/) | Claude Code lifecycle hooks (wiring documented in `hooks/README.md`) |
| [scripts/](scripts/) | Checks, generators, learning loop, ops (`scripts/README.md`) |
| [scheduled-tasks/](scheduled-tasks/) | Scheduled-routine specs: CI crons vs Mac LaunchAgents |
| [docs/](docs/) | Durable docs vs frozen dated snapshots (`docs/README.md`) |
| [.github/](.github/) | CI gates + Mac-independent crons (`.github/README.md`) |
| [docs/memory-lane.md](docs/memory-lane.md) | Memory procedures (freshness gate, end-of-session write, on-correction routing). Global lane lives in the vault `SchnappAPI/schnapp-vault`, not here; schema in the vault's `agents.md` |
| [credentials-map.md](credentials-map.md) | `op://` reference map (references only) |
| [docs/environment-and-access.md](docs/environment-and-access.md) | Never-blocked config: required network allowlist, git-write path, per-surface delivery (ADR 0018) |

## Staying current (anti-stale)
- Docs reference canonical sources for mutable facts; they never copy them. See the
  [anti-stale rule](rules/global/anti-stale.md) and [[keep-tracker-current]] in memory.
- Every state-changing commit updates the affected tracker/doc in the same commit and pushes
  immediately, so GitHub mirrors local.
- A SessionStart hook does `git pull --ff-only` to surface divergence before work.
- A CI freshness gate ([`.github/workflows/freshness.yml`](.github/workflows/freshness.yml)) fails a
  push if a generated doc (`CATALOG.md`) is stale, or a `last-verified` doc's source
  changed afterward. Regenerate with [`scripts/gen-catalog.sh`](scripts/gen-catalog.sh).

## Install (per surface)
One repo, used across surfaces. These are the install steps; the original build (the 11-Part plan) is
complete, archived in [docs/archive/PLAN-archive-2026-07-01.md](docs/archive/PLAN-archive-2026-07-01.md).
Per-surface operating detail lives in [surfaces/](surfaces/) and is referenced here, not repeated.

### Code - any Mac / machine
1. Clone both repos: `~/code/schnapp-os` + `~/code/schnapp-vault`.
2. Run `bash ~/code/schnapp-os/shell/install.sh` (idempotent; `--dry-run` previews). It writes ALL
   the user-global wiring - `~/.claude/CLAUDE.md` (`@import`s of the global rules),
   `autoMemoryDirectory` -> the vault memory lane, the user-scope hooks (standing-rules,
   capture-nudge, any-repo session gate, session-end vault push, the two guards), and the
   skill/agent/command symlinks - so every repo on the machine gets the shell
   (ADR [0033](decisions/0033-portable-shell-user-scope-wiring.md); procedures:
   [docs/memory-lane.md](docs/memory-lane.md)).
3. **Accept the workspace-trust dialog** on first open of the repo. Until accepted, the project hooks
   silently do nothing - this is the first thing to check if the SessionStart gate does not print. (The
   user-scope memory lane from step 2 loads regardless of trust; trust gates the *project* hooks/settings.)
4. Hooks: the repo's `.claude/settings.json` wires the SessionStart freshness gate, the Stop push-gate,
   and the SessionEnd backup (dev-time dogfood), plus the edit-time PostToolUse guards (secret-scan,
   shellcheck, length-advisory). All are wired directly against live `${CLAUDE_PROJECT_DIR}` paths, not
   delivered by a plugin: the flatten removed the marketplace plugin ([decisions/0024](decisions/0024-flatten-plugin-native-claude.md)).
5. Backup/Obsidian: mirror target is OneDrive `~/Library/CloudStorage/OneDrive-Schnapp/claude-archive`
   (override with `CLAUDE_ARCHIVE_DIR`), opened as an Obsidian vault.
6. Credentials: 1Password service-account token in the shell env; the off-Mac op-mcp connector via
   bearer (see below). `op`/`gh` resolve locally.

### Code - other machines (work laptop/desktop)
Same as the primary Mac; put per-machine overrides (paths, `CLAUDE_KIT_REPO`) in
`.claude/settings.local.json` (gitignored). See [surfaces/code-work-machines.md](surfaces/code-work-machines.md).

### Cowork
Connect the repo. Do not assume hooks run (treat as hookless until verified) → run the must-happen
session procedures via the **session-hygiene** skill. Secrets via the op-mcp connector (bearer).
See [surfaces/cowork.md](surfaces/cowork.md).

### claude.ai web
Add op-mcp as a custom connector (OAuth portal `https://mcp.schnapp.bet/mcp`); add the
**session-hygiene** and **surface-check** skills. Connector setup:
[connectors/op-mcp/DEPLOY.md](connectors/op-mcp/DEPLOY.md); surface detail:
[surfaces/claude-ai-web.md](surfaces/claude-ai-web.md).

### iPhone
Uses the same claude.ai connector + skills; no filesystem, so the OneDrive backup runs from a shell
surface, not here. See [surfaces/iphone.md](surfaces/iphone.md).
