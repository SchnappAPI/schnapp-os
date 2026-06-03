# Handoff 000 — Part 0 setup

Date: 2026-06-03

## State
- Local repo `~/code/claude-kit` created, branch `main`, remote set to
  `git@github.com:SchnappAPI/claude-kit.git` (SSH).
- Committed: PLAN.md (canonical), PROGRESS.md, README.md, .gitignore, decisions/0001.
- NOT pushed: the remote repo does not exist yet.

## Blocker (owner action)
1Password Service Account is DELETED (decisions/0001). `op`/`gh`/launchd secret resolution
return 403. **Healthy:** git over SSH, GitHub MCP OAuth connector.

Repo creation needs one of:
- Owner creates an empty PRIVATE `SchnappAPI/claude-kit` on github.com, then push over SSH:
  `git -C ~/code/claude-kit push -u origin main`
- Owner rotates the SA, then `gh repo create SchnappAPI/claude-kit --private --source=. --push`

## What works without the blocker
Authoring all kit content locally (Parts 2, 3 rules/surfaces/presets) and committing.

## Next session prompt
"Resume claude-kit PLAN.md. Read PROGRESS.md and handoffs/ first. If
SchnappAPI/claude-kit now exists, push main over SSH. Then continue: either fix the SA
(Part 4 / decisions/0001) or build Part 2 (global lane + surface profiles) locally."

## References
- PLAN.md (master plan), PROGRESS.md (log), decisions/0001 (SA deleted + auth map).
