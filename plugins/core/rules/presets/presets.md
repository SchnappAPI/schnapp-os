---
updated: 2026-06-05
---
# Rule presets

A preset is a named list of modules applied in one choice by `/new-project`. Global rules
always apply and are not listed. You can add or remove any module after applying a preset.

| Preset | Modules |
|---|---|
| work-etl-sql | coding/*, lang/python, lang/sql-server, lang/env-vars, lang/git, lang/github-actions, activity/etl-pipeline, context/work |
| personal-sports-etl | coding/*, lang/python, lang/sql-server, lang/env-vars, lang/git, lang/github-actions, activity/etl-pipeline, context/personal |
| policy-procedure | activity/policy-procedure, context/work |
| web-tool | coding/*, lang/typescript, lang/git, activity/web-tool |
| quickbase | tool/quickbase, context/work |

## Recommended skills per preset

Skills and agents are **plugin-global** (available in every project once schnapp-os is
installed); they are not symlinked like rule modules. This list names the ones most relevant to
each preset so `/new-project` records them in the project's CLAUDE.md and you reach for the
right tool. Names are schnapp-os skills/agents unless tagged with their source plugin (HAVE =
an already-available skill, not built here). Full inventory: [`CATALOG.md`](../../CATALOG.md).

- **work-etl-sql / personal-sports-etl** (the ETL core):
  `etl-pipeline-build`, `sql-server-patterns`, `regex-vs-llm-structured-text`,
  `data-throughput-accelerator`, `benchmark`;
  agents `sql-etl-reviewer`, `performance-optimizer`;
  HAVE: `pq-flat-map-type`, the `data:*` suite (analyze, write-query, explore-data,
  build-dashboard), `xlsx`, `deep-research`, `docs-lookup`.
  - personal-sports-etl also: `sports-data-auditor`, `fish-compare` (HAVE).
  - work-etl-sql also, when the source is that tool: the `quickbase` / `appfolio` skills.
- **quickbase**: `quickbase`; plus the ETL core (`etl-pipeline-build`, `sql-server-patterns`,
  `sql-etl-reviewer`) when loading Quickbase data into SQL Server.
- **policy-procedure**: `deep-research`, `docs-lookup`, `grill-me`, `grill-with-docs`,
  `council` (decision/interrogation + the owner's own knowledge).
- **web-tool**: `frontend-design` (plugin), the `design:*` suite, `performance-optimizer`
  (web mode), `benchmark`, `docs-lookup`.

**Cross-cutting (reach for in any project):** `docs-lookup`, `council`, `grill-me`,
`rules-distill`, `surface-check`, `session-hygiene`, `merge-with-discretion`,
`context-budget`, `clean-gone`, `content-hash-cache-pattern`, `latency-critical-systems`; plus the
keep-set plugins (superpowers brainstorming / TDD / systematic-debugging /
requesting-code-review, `/code-review`, caveman).

```yaml
# machine-readable (consumed by /new-project)
presets:
  work-etl-sql:    [coding/error-handling, coding/input-validation, coding/design-defaults, lang/python, lang/sql-server, lang/env-vars, lang/git, lang/github-actions, activity/etl-pipeline, context/work]
  personal-sports-etl: [coding/error-handling, coding/input-validation, coding/design-defaults, lang/python, lang/sql-server, lang/env-vars, lang/git, lang/github-actions, activity/etl-pipeline, context/personal]
  policy-procedure: [activity/policy-procedure, context/work]
  web-tool:        [coding/error-handling, coding/input-validation, coding/design-defaults, lang/typescript, lang/git, activity/web-tool]
  quickbase:       [tool/quickbase, context/work]
skills:
  work-etl-sql:        [etl-pipeline-build, sql-server-patterns, regex-vs-llm-structured-text, data-throughput-accelerator, benchmark, sql-etl-reviewer, performance-optimizer, pq-flat-map-type, "data:*", xlsx, deep-research, docs-lookup]
  personal-sports-etl: [etl-pipeline-build, sql-server-patterns, data-throughput-accelerator, sql-etl-reviewer, performance-optimizer, sports-data-auditor, fish-compare, pq-flat-map-type, "data:*", xlsx, deep-research, docs-lookup]
  policy-procedure:    [deep-research, docs-lookup, grill-me, grill-with-docs, council]
  web-tool:            [frontend-design, "design:*", performance-optimizer, benchmark, docs-lookup]
  quickbase:           [quickbase, etl-pipeline-build, sql-server-patterns, sql-etl-reviewer, docs-lookup]
```
