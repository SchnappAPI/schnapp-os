---
scope: global
updated: 2026-06-27
---
# Anti-staleness (single source of truth)

- One fact lives in one canonical file. Elsewhere `@import` it or reference it by path;
  never paraphrase. Duplication is what goes stale.
- Fix the class, not the instance. When something stale, wrong, or duplicated is found or
  pointed out, it is one case of a kind: sweep the whole repo for every sibling of that kind
  and fix them in the same pass. Patching only the flagged example leaves the rest stale and
  repeats the problem. (How-to-work corollary in working-style.md "Generalize corrections".)
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
- Current-state only: a doc shows what IS, never a layered history of what was. When something
  changes, OVERWRITE it — do not leave the old value struck-through, marked "deprecated/old/deleted",
  or sitting beside the new one. The record of the change belongs in `decisions/` (an ADR) or a
  changelog, never inline in the doc it changed. The lone exceptions are the history artifacts
  themselves — `decisions/`, `handoffs/`, and any explicit changelog — which are append-only by design.
