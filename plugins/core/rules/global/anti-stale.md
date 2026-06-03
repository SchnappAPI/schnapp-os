---
scope: global
updated: 2026-06-03
---
# Anti-staleness (single source of truth)

- One fact lives in one canonical file. Elsewhere `@import` it or reference it by path;
  never paraphrase. Duplication is what goes stale.
- `@import` live files instead of describing them. Import only small, always-needed files;
  large or occasional content loads on demand (skills, path-scoped rules).
- Generate anything derivable (catalogs, command lists, env docs); mark output
  "generated, do not edit". The source is canonical; the doc is a projection.
- Memory: supersede, do not append. When a fact changes, replace it; do not leave a
  contradicting copy. Every memory carries `source:` and `updated:`.
- Tracker currency: every commit that changes state also flips the matching PLAN.md box and
  appends a PROGRESS.md line in the SAME commit, and is **pushed immediately** so GitHub always
  mirrors local — never let the remote go stale. Partial work is `[~]`, not `[x]`. Never mark a
  step done/verified before its verify command has run. See [[keep-tracker-current]] in memory.
- Doc currency (applies to ALL docs, not just the tracker): a doc never hardcodes a mutable fact
  it does not own — it references the canonical source (PLAN.md / PROGRESS.md for status,
  decisions/ for choices, the code/config for behavior). A commit that changes state updates every
  doc whose claim changed, in that same commit. README carries no status string; it points to the
  live trackers. CI freshness enforcement is wired in Part 9.3.
