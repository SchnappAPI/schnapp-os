---
module: lang/git
updated: 2026-06-30
---
# Git conventions

- Branch names (manual branches are not part of the workflow — see Workflow; applies only if one
  is ever unavoidable, e.g. a harness-created worktree): lowercase, hyphenated, type-prefixed:
  `feat/odds-loader`, `fix/null-handling`, `chore/repo-sync`.
- Commit messages: Conventional Commits. Start with a type and colon: `feat: add MLB Statcast
  pull`, `fix: handle empty odds response`, `chore: bump dependencies`. Types: feat, fix,
  chore, docs, refactor, test.

## Workflow (main only — ADR 0016 / 0017)

- **Everything commits straight to `main`** — directed work and autonomous self-edits alike, no
  feature branches and no PRs (ADR 0016). Commit and push **every** change immediately so local
  and GitHub never diverge (mechanics: the keep-tracker-current memory +
  `rules/global/anti-stale.md` "Tracker currency" — do not restate them here). Run
  tests + a local review pass before pushing; CI runs on the push to `main`.
- **Autonomous self-edits use a pre-commit gate, not a branch** (`learning-gate.sh`): APPROVE →
  commit to `main`; HOLD → discard and open a review issue (ADR 0016). No `self-edit/*` branches.
- **Stray branches are residue, not a workflow.** A web session's per-session `claude/*` or a
  harness worktree targets `main` directly (ADR 0017). The nightly `sync/unmerged` routine surfaces
  any non-`main` branch; review the unmerged ones and delete the merged residue
  (`git push origin --delete <branch>`, run from the Mac or an approved session).
- Sync: `git pull --ff-only` at session start, and **address unmerged or unpushed work before any
  new work** (surfaced deterministically by the SessionStart gate,
  `hooks/session-start-gate.sh`; never left unpushed past a turn by the Stop push-gate,
  `hooks/session-stop-push-gate.sh`).
- Log decisions to `decisions/` and progress to `PROGRESS.md` as you go.
