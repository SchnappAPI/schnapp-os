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
- CI freshness enforcement is added in Part 9.3.

## Install / use
Per-surface install checklist is finalized in Part 9.5 (`README` section). Until then, the
canonical setup steps live in [PLAN.md](PLAN.md) (Parts 2.2, 10) and [surfaces/](surfaces/).
