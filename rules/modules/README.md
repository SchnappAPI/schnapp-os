# rules/modules/ - on-demand reference library

Path-scoped and activity modules. NOT loaded automatically anywhere: a project's CLAUDE.md
`@import`s only the ones it needs (no gallery/preset/composer, per decisions/0011 #4). Per-module
descriptions and scopes: [CATALOG.md](../../CATALOG.md) (generated).

- [lang/](lang/) - per-language/format conventions (python, sql-server, git, github-actions,
  power-query-m, env-vars). `_reference-why-naming-differs.md` explains the casing split.
- [tool/](tool/) - specific tools and services.
- [activity/](activity/) - how to run a class of task (etl-pipeline, ideation-first,
  perspective-research, scaffolding-choice).
- [coding/](coding/) - cross-language coding defaults (design, error handling, input validation).
- [context/](context/) - personal vs work context framing.

Adding a module: write it self-contained, regenerate CATALOG (`scripts/gen-catalog.sh`), do not
wire it anywhere by default.
