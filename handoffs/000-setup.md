# Handoff 000 — Part 0 setup

Date: 2026-06-03

## State
- Repo `SchnappAPI/claude-kit` is LIVE and PRIVATE. `main` pushed over SSH (3 commits).
- Committed + pushed: PLAN.md (canonical), PROGRESS.md, README.md, .gitignore, decisions/0001,
  handoffs/000, and Part 2.1 global rules under plugins/core/rules/global/.
- Part 0 done. Sync-hook automation (auto pull/push) deferred to Part 7.

## Remaining owner action (not blocking local authoring)
1Password Service Account is DELETED (decisions/0001). `op`/`gh`/launchd secret resolution
return 403. **Healthy:** git over SSH, GitHub MCP OAuth connector. Fix in Part 4 (recreate
SA, rotate token everywhere). Part 1 (disable plugins) waits on keep-set approval.

## What works without the blocker
Authoring all kit content locally (Parts 2, 3 rules/surfaces/presets) and committing.

## Next session prompt
"Resume claude-kit PLAN.md. Read PROGRESS.md and handoffs/ first. If
SchnappAPI/claude-kit now exists, push main over SSH. Then continue: either fix the SA
(Part 4 / decisions/0001) or build Part 2 (global lane + surface profiles) locally."

## References
- PLAN.md (master plan), PROGRESS.md (log), decisions/0001 (SA deleted + auth map).
