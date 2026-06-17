# MEMORY — global lane index

Thin index for the cross-everything memory lane. One line per fact, newest-relevant
first. Conventions: [memory/README.md](README.md). Per-fact files live beside this one.

Not a dumping ground: behavioral preferences live as rules
([working-style](../plugins/core/rules/global/working-style.md)), not here. This lane
holds durable cross-surface facts and context.

## Index
- [Keep tracker current](keep-tracker-current.md) — flip PLAN box + PROGRESS line in the same commit as the deliverable; never claim verified before the verify ran.
- [Credentials state](credentials-state.md) — **Re-verified 2026-06-17: root cause CONFIRMED = stale in-process/Render token after the 06-15 SA rotation (NOT a dead SA). Mac shell SA valid; off-Mac op-mcp STILL down (Render token pending owner update+redeploy); Mac MCP restart pending. gh/GitHub unaffected.** Map: [credentials-map](../credentials-map.md).
- [Mac connector tooling](mac-connector-tooling.md) — Schnapp Mac `write_file` OVERWRITES (no append; use `shell_exec` `cat >>` / python rmw); `shell_exec` strips op identity (use `op_run` for secrets).
- [Obsidian state](obsidian-state.md) — vault canonical at OneDrive (symlink at ~/Documents/Obsidian); off-Mac obsidian = Mac-hosted server obsidian-mcp.schnapp.bet (search_notes/read_note/...), Mac-dependent; the Render connectors/obsidian-mcp is superseded.
