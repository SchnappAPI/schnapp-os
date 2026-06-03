---
module: lang/git
updated: 2026-06-03
---
# Git conventions

- Branch names: lowercase, hyphenated, type-prefixed: `feat/odds-loader`,
  `fix/null-handling`, `chore/repo-sync`. (Only when a branch is warranted; default is to
  work on `main`, see the project's git workflow.)
- Commit messages: Conventional Commits. Start with a type and colon: `feat: add MLB Statcast
  pull`, `fix: handle empty odds response`, `chore: bump dependencies`. Types: feat, fix,
  chore, docs, refactor, test.
