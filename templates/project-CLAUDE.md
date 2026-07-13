<!--
  TEMPLATE - a thin starter for a project's CLAUDE.md. Copy it by hand into a new (or existing)
  project and fill the <PLACEHOLDERS>. Keep it THIN: it REFERENCES canonical rules, never copies
  them (anti-stale: one fact, one source). There is no gallery/preset/composer - modules are a
  plain reference library; @import only the ones a project actually needs.
-->
# <PROJECT NAME>

<!-- One or two lines: what this project is and the objective it serves. -->
<PROJECT PURPOSE>

## Rules in effect

**Global rules**: always on in every project on this machine. They load via `~/.claude/CLAUDE.md`,
which `@import`s schnapp-os's lean global lane (the current set is listed in
`~/code/schnapp-os/CATALOG.md` - generated, never hand-list it here). Do **not** re-import
them in this file - that double-loads. Canonical source: `~/code/schnapp-os/rules/global/`.

**Path-scoped modules**: `@import` only the modules this project needs, directly, from the reference
library `~/code/schnapp-os/rules/modules/`. They are plain rule files; pick by relevance.
Full inventory + scopes: `~/code/schnapp-os/CATALOG.md` (generated). Example:

<!-- Replace with the modules this project actually uses. -->
@~/code/schnapp-os/rules/modules/lang/python.md
@~/code/schnapp-os/rules/modules/lang/sql-server.md
@~/code/schnapp-os/rules/modules/activity/etl-pipeline.md

**Skills in reach**: schnapp-os skills/agents are plugin-global (available everywhere it is
installed); reach for them by name. See `CATALOG.md` for the inventory; name the few most relevant
to this project here.

<!-- e.g. etl-pipeline-build, sql-server-patterns, sql-etl-reviewer, performance-optimizer, notes-lookup -->
- <skill-1>, <skill-2>, ...

## Project lane (project-specific facts - the one place they live)

<!-- Durable context the rules don't carry. Terse and current. Anti-stale: point at the
     canonical source (a schema file, a config, a decision doc) instead of copying its contents.
     Personal/debugging notes go to memory, not here (global/knowledge-capture.md). -->
- **Purpose / objective:** <...>
- **Data / schema:** <reference the schema file or migration, do not restate it>
- **Key services / endpoints:** <...>
- **Performance notes:** project-specific instances only; the general principles live in
  `rules/modules/coding/speed-by-default.md` - link the instance back to the principle
  (dual-altitude promotion).
- **Gotchas:** <...>

<!-- Secrets are `op://` references, never values (global/secrets-as-references.md). New env vars
     go in `.env.template` as `op://` URIs. The GLOBAL memory lane is the vault
     (`~/code/schnapp-vault/memory`, set via user-scope `autoMemoryDirectory`); a project sets its
     own `autoMemoryDirectory` only for a PROJECT lane it wants git-tracked in its own repo. -->
