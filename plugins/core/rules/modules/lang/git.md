---
module: lang/git
updated: 2026-06-05
---
# Git conventions

- Branch names: lowercase, hyphenated, type-prefixed: `feat/odds-loader`,
  `fix/null-handling`, `chore/repo-sync`. (Only when a branch is warranted; default is to
  work on `main` — see Workflow below.)
- Commit messages: Conventional Commits. Start with a type and colon: `feat: add MLB Statcast
  pull`, `fix: handle empty odds response`, `chore: bump dependencies`. Types: feat, fix,
  chore, docs, refactor, test.

## Workflow (default: simplicity)

- Work on `main`. Commit and push **every** change immediately, so local and GitHub never
  diverge (mechanics: the keep-tracker-current memory + `plugins/core/rules/global/anti-stale.md`
  "Tracker currency" — do not restate them here).
- **No branches** unless there is a strong benefit AND explicit owner approval. Name an approved
  branch per the convention above; integrate it with the `merge-with-discretion` skill.
- Sync: `git pull --ff-only` at session start, and **address unmerged or unpushed work before any
  new work** (surfaced deterministically by the SessionStart gate,
  `plugins/core/hooks/session-start-gate.sh`; never left unpushed past a turn by the Stop push-gate,
  `plugins/core/hooks/session-stop-push-gate.sh`).
- Log decisions to `decisions/` and progress to `PROGRESS.md` as you go.
