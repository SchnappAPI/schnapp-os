# claude-kit

Central, multi-surface Claude system: skills, commands, hooks, agents, composable rules,
memory, and credential references, usable on Claude Code (all machines), Cowork, and
claude.ai. One source of truth. No duplication. Nothing siloed. References to secrets only,
never values. Private repo.

## Live status — do not duplicate here
This README states no progress/status (status hardcoded in a README is the classic stale doc).
Status lives in one canonical place and is read there:
- **[PLAN.md](PLAN.md)** — master plan; per-step boxes (`[x]` done, `[~]` partial, `[ ]` not started).
- **[PROGRESS.md](PROGRESS.md)** — running execution log, newest at the bottom of each day.

## Map
| Path | What |
|---|---|
| [PLAN.md](PLAN.md) | Master plan + live step status |
| [PROGRESS.md](PROGRESS.md) | Execution log |
| [decisions/](decisions/) | One file per decision (the "why") |
| [handoffs/](handoffs/) | Dated session handoffs; the newest, highest-numbered is the resume point |
| [plugins/core/rules/](plugins/core/rules/) | Rule gallery — `global/` (always-on) + `modules/` (path-scoped lang, tool, activity, context) + `presets/` |
| [plugins/core/CATALOG.md](plugins/core/CATALOG.md) | Generated inventory of rules/skills/commands/hooks (do not edit; `gen-catalog.sh`) |
| [templates/](templates/) | `project-CLAUDE.md` (`/new-project` output) + `user-global-CLAUDE.md` (the `~/.claude/CLAUDE.md` copy) |
| [surfaces/](surfaces/) | One operating profile per surface (Code, Cowork, claude.ai, iPhone) |
| [connectors/op-mcp/](connectors/op-mcp/) | Off-Mac 1Password MCP connector (Node host) |
| [memory/](memory/) | Global memory lane — `MEMORY.md` index + per-fact files ([conventions](memory/README.md)) |
| [credentials-map.md](credentials-map.md) | `op://` reference map (references only) |

## Staying current (anti-stale)
- Docs reference canonical sources for mutable facts; they never copy them. See the
  [anti-stale rule](plugins/core/rules/global/anti-stale.md) and [[keep-tracker-current]] in memory.
- Every state-changing commit updates the affected tracker/doc in the same commit and pushes
  immediately, so GitHub mirrors local.
- A SessionStart hook does `git pull --ff-only` to surface divergence before work (Part 0.3).
- A CI freshness gate ([`.github/workflows/freshness.yml`](.github/workflows/freshness.yml)) fails a
  push if a generated doc (`plugins/core/CATALOG.md`) is stale, or a `last-verified` doc's source
  changed afterward. Regenerate with [`plugins/core/scripts/gen-catalog.sh`](plugins/core/scripts/gen-catalog.sh).

## Install (per surface)
One repo, used across surfaces. These are the install steps; what is already live vs wired at
Part 10 is tracked in [PLAN.md](PLAN.md). Per-surface operating detail lives in
[surfaces/](surfaces/) and is referenced here, not repeated.

### Code — primary Mac
1. Clone to `~/code/claude-kit` (the path the hooks, `~/.claude/CLAUDE.md`, and the backup all assume).
2. Create `~/.claude/CLAUDE.md` by copying the body of
   [templates/user-global-CLAUDE.md](templates/user-global-CLAUDE.md) (that file lives outside the
   repo, so the template is its canonical copy). It `@import`s the 7 global rules from the repo.
3. **Accept the workspace-trust dialog** on first open of the repo. Until accepted, the project hooks
   AND the `autoMemoryDirectory` memory lane silently do nothing — this is the first thing to check if
   the SessionStart gate does not print.
4. Hooks: the repo's `.claude/settings.json` wires the SessionStart freshness gate, the Stop push-gate,
   and the SessionEnd backup (dev-time dogfood). At Part 10 the marketplace **plugin** delivers the
   global gate + push-gate everywhere via `${CLAUDE_PLUGIN_ROOT}`, and the project keeps **only** the
   backup so they do not double-fire — see [decisions/0005](decisions/0005-hook-delivery-split.md).
5. Backup/Obsidian: mirror target is OneDrive `~/Library/CloudStorage/OneDrive-Schnapp/claude-archive`
   (override with `CLAUDE_ARCHIVE_DIR`), opened as an Obsidian vault (Part 6).
6. Credentials: 1Password service-account token in the shell env; the off-Mac op-mcp connector via
   bearer (see below). `op`/`gh` resolve locally.

### Code — other machines (work laptop/desktop)
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
