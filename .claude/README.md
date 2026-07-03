# .claude/ - Claude Code project surface

Native Claude Code components for this repo (plugin packaging was flattened away, decisions/0024).
Inventory with descriptions: [CATALOG.md](../CATALOG.md) (generated - regenerate via
`scripts/gen-catalog.sh` after adding/renaming anything here).

- [skills/](skills/) - one directory per skill (`SKILL.md`). Invoked by name or via `/do`.
- [commands/](commands/) - slash commands.
- [agents/](agents/) - specialized subagent definitions (dispatched via the Agent tool).
- [settings.json](settings.json) - tracked project settings: hook wiring (scripts in
  [hooks/](../hooks/)), `autoMemoryDirectory` (points at the vault memory lane). The `$comment`
  field documents every hook. `settings.local.json` = untracked local overrides.
- `worktrees/` - local git worktrees from web/desktop sessions; untracked, safe to prune.

Machine-wide behavioral hooks (standing-rules, capture-nudge) are wired at USER scope in
`~/.claude/settings.json`, not here - see the `$comment` in settings.json for the split.
