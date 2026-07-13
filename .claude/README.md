# .claude/ - Claude Code project wiring only

This directory carries WIRING, not components. The canonical component roots live at the
repo top level - [skills/](../skills/), [agents/](../agents/), [commands/](../commands/) -
and are delivered to every session at USER scope by the portable shell's symlinks
(`shell/install.sh`, ADR 0033). Keeping them out of `.claude/` makes the installer the
single registrar: a schnapp-os session no longer loads every skill twice (user scope +
project scope). Inventory with descriptions: [CATALOG.md](../CATALOG.md) (generated -
regenerate via `scripts/gen-catalog.sh` after adding/renaming anything).

- [settings.json](settings.json) - tracked project settings: hook wiring (scripts in
  [hooks/](../hooks/)), `autoMemoryDirectory` (points at the vault memory lane). The `$comment`
  field documents every hook. `settings.local.json` = untracked local overrides.
- `worktrees/` - local git worktrees from web/desktop sessions; untracked, safe to prune.

Machine-wide behavioral hooks (standing-rules, capture-nudge) are wired at USER scope in
`~/.claude/settings.json`, not here - see the `$comment` in settings.json for the split.
