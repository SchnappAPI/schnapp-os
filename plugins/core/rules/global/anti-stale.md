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
