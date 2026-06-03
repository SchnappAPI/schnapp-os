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
4. Write a thin `<target>/CLAUDE.md` that:
   - `@import`s the always-on global rules (or notes they load via `~/.claude/rules/global`),
   - lists the composed modules,
   - leaves a project-lane section for project-specific facts (schema, endpoints, purpose).
5. Print the composed set and how to change it later (re-run `/new-project`, or add/remove a
   symlink in `.claude/rules/`).

If a better-fitting module exists than the preset includes, say so once; do not force extra
choices when the preset is sensible.
