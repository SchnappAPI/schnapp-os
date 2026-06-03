# 0003 — schnapp-kit is a source repo, not a plugin (2026-06-03)

Decision: treat schnapp-kit as a repo to dissect and migrate from, piece by piece, into
claude-kit. It is no longer an active plugin.

- Disabled `schnapp-kit@schnapp-kit` in `~/.claude/settings.json` (with 12 redundant plugins).
- Repo stays on disk + tag `record-2026-06-03` = the recoverable record.
- Its SessionStart drift/auto-enable guard was a schnapp-kit hook, so disabling the plugin
  stops it; it will not re-enable itself (no global hook in settings.json).
- Migration is deliberate: pull a skill/command/agent across only when you understand it and
  want it, adapting to claude-kit's structure.

Kept enabled (6): caveman, github, superpowers, plugin-dev, pyright-lsp, frontend-design.
Disabled (13): schnapp-kit, claude-mem, remember, commit-commands, code-simplifier,
claude-md-management, session-report, greptile, hookify, skill-creator, feature-dev,
claude-code-setup, compound-engineering.

Reversible: settings.json backup saved at `~/.claude/settings.json.bak-20260603-144320`.
