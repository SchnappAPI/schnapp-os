<!--
  TEMPLATE — written into a project by /new-project (schnapp-os). It is the single source for
  the shape of a composed project CLAUDE.md. Keep it THIN: it REFERENCES canonical rules, it
  never copies them (anti-stale: one fact, one source). Replace <PLACEHOLDERS>; /new-project
  fills the composed-module list from the chosen preset. Edit the project lane freely; re-run
  /new-project to recompose the module set.
-->
# <PROJECT NAME>

<!-- One or two lines: what this project is and the objective it serves. -->
<PROJECT PURPOSE>

## Rules in effect

**Global rules** — always on in every project on this machine. They load via `~/.claude/CLAUDE.md`,
which `@import`s schnapp-os's lean global lane. They are **not** re-imported here: that would
double-load. Canonical source (working-style, knowledge-capture, naming-discipline,
secrets-as-references, verify-before-asserting, anti-stale, speed-by-default):
`~/code/schnapp-os/plugins/core/rules/global/`.

**Composed modules** — this project's chosen modules load from `./.claude/rules/`, which holds
symlinks into the schnapp-os gallery (one source of truth; language modules are path-scoped via
`paths:` frontmatter, so they load only for their own file types). Composed set:

<!-- /new-project replaces the lines below with the preset's modules (example shown). -->
- preset: `<preset-name>`
- `lang/python` — `**/*.py`
- `coding/error-handling`, `coding/input-validation`, `coding/design-defaults`
- `activity/<...>`, `context/<work|personal>`

Full gallery + scopes: `~/code/schnapp-os/plugins/core/CATALOG.md` (generated). Change the set
anytime: re-run `/new-project`, or add/remove a symlink in `./.claude/rules/`.

**Skills in reach** — plugin-global skills/agents (available everywhere schnapp-os is installed,
not symlinked) most relevant to this project. `/new-project` fills these from the preset's
`skills:` list in `presets/presets.md`; reach for them by name.

<!-- /new-project replaces the line below with the preset's recommended skills. -->
- <skill-1>, <skill-2>, ... (see `presets/presets.md` "Recommended skills per preset")

## Project lane (project-specific facts — the one place they live)

<!-- Durable context the rules don't carry. Terse and current. Anti-stale: point at the
     canonical source (a schema file, a config, a decision doc) instead of copying its contents.
     Personal/debugging notes go to memory, not here (global/knowledge-capture.md). -->
- **Purpose / objective:** <...>
- **Data / schema:** <reference the schema file or migration, do not restate it>
- **Key services / endpoints:** <...>
- **Performance notes:** project-specific instances only; the general principles live in
  `global/speed-by-default.md` — link the instance back to the principle (dual-altitude promotion).
- **Gotchas:** <...>

<!-- Secrets are `op://` references, never values (global/secrets-as-references.md). New env vars
     go in `.env.template` as `op://` URIs. Project auto-memory writes to the repo memory lane if
     this project is schnapp-os; other projects use their own configured memory directory. -->
