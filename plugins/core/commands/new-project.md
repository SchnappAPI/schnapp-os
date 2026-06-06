---
description: Compose a project's rule set from the gallery (preset + free pick) and write its CLAUDE.md
argument-hint: "[preset-name] [target-dir]"
---
# /new-project

Set up a new (or existing) project's rules by composing modules from the gallery. Goal:
one choice, never locked in, no rule leakage across languages.

Steps Claude follows:

1. Resolve the target directory (argument, else the current repo root).
2. Pick the preset: use the argument if given; otherwise read
   `plugins/core/rules/presets/presets.md`, list presets, and ask which one. If the project
   type is obvious from the repo (deps, file types, tools), suggest the best-fitting preset
   but let the user confirm. Offer to add or remove individual modules.
3. Create `<target>/.claude/rules/` and symlink each chosen module file from this repo's
   `plugins/core/rules/modules/...` into it. Symlinks keep one source of truth and let
   path-scoped modules load only for matching files. Never symlink modules marked
   `composed: false`.
4. Write `<target>/CLAUDE.md` from `templates/project-CLAUDE.md` (the single source for its
   shape): fill the project name/purpose, replace the composed-module list with the chosen
   preset's modules, and fill the "Skills in reach" list from that preset's `skills:` entry in
   `plugins/core/rules/presets/presets.md` (skills are plugin-global, not symlinked — they are
   named for relevance, not installed per project). Do NOT `@import` the global rules — they
   already load in every project via `~/.claude/CLAUDE.md`, so re-importing double-loads. The
   template references the gallery and the generated `CATALOG.md` (no rule content is copied) and
   leaves a project-lane section for project-specific facts (purpose, schema, endpoints, perf
   notes, gotchas).
5. Print the composed set and how to change it later (re-run `/new-project`, or add/remove a
   symlink in `.claude/rules/`).

If a better-fitting module exists than the preset includes, say so once; do not force extra
choices when the preset is sensible.
