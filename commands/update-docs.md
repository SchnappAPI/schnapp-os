---
description: Regenerate a repo's derived docs (schema dumps, env-var lists, route/endpoint or pipeline catalogs) from their canonical sources, and flag any doc whose source changed after its last-verified date. Derived catalogs + staleness only; for a synthesized architecture map use /update-codemaps.
argument-hint: "[target-dir]"
---
# /update-docs

Regenerate the **derived** docs in the target repo so no doc hand-lists a mutable fact and
goes stale. This is the generic form of schnapp-os's own `gen-catalog.sh`, run against the
owner's *other* ETL repos. Honors [`global/anti-stale`](../rules/global/anti-stale.md)
("Doc currency": generate anything derivable; mark output generated).

Steps Claude follows:

1. Resolve the target directory (argument, else the current repo root). This command is for
   the owner's downstream repos, NOT schnapp-os (schnapp-os uses `gen-catalog.sh` directly).
2. Discover the doc generators already in the repo (a `scripts/` generator, a Makefile/`just`
   target, an `npm run docs`, a `gen-*.sh`). If one exists, run it - do not invent a parallel
   generator.
3. If none exists, regenerate the common derivable docs from their canonical sources:
   - **Schema doc** from the live DB / migration files (tables, columns, keys).
   - **Env-var list** from `.env.template` / workflow `env:` blocks (names only, `op://`
     refs, never values - see [`secrets-as-references`](../rules/global/secrets-as-references.md)).
   - **Pipeline / job catalog** from the scheduled scripts (GitHub Actions cron, LaunchAgents).
   - **Route/endpoint index** for a web tool, from the route definitions.
4. Mark every generated file with a `generated - do not edit` header so it is never hand-edited.
5. **Drift check**: for any doc carrying `last-verified:` frontmatter with a `sources:` list,
   flag it if a `sources:` path changed in git after that date. Report the stale docs.
6. Show what regenerated and what drifted; commit only the regenerated outputs (push per the
   git workflow).

If a doc cannot be derived from a canonical source, say so - do not fabricate content; surface
it as a doc that needs a human owner or a real generator.
