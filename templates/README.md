# templates/ - canonical copies of files that live outside this repo

- [user-global-CLAUDE.md](user-global-CLAUDE.md) - the canonical `~/.claude/CLAUDE.md` for every
  machine: the explicit `@import` list of [rules/global/](../rules/global/). When the global rule
  SET changes, update this template, then re-run [shell/install.sh](../shell/install.sh) on each
  machine (it renders this template; ADR 0033 replaced the manual copy).
- [project-CLAUDE.md](project-CLAUDE.md) - starter CLAUDE.md for a new project repo: copy, fill,
  `@import` only the [rules/modules/](../rules/modules/) it needs.

These are templates because the live files sit outside git's reach (`~/.claude/`, other repos);
the template here is the source of truth for their content.
