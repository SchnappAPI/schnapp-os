# Surface: claude.ai (web + chat)

- **Skills:** added in claude.ai settings (per account; org-provisioned on Team/Enterprise).
  The same SKILL.md files from this repo are used; they do not auto-sync, so enable them here.
- **Tools/credentials:** hosted MCP connectors only, enabled in Settings > Connectors. The
  **1Password** connector is LIVE: the op-mcp portal `https://mcp.schnapp.bet/mcp` (Cloudflare
  Managed OAuth → Render). Also GitHub + the Mac ops connector ("Schnapp Mac"). No local
  filesystem, shell, or hooks. To USE a secret, call the Mac's `op_run`/`op_inject` (value
  scrubbed); use op-mcp `op_read` only when the Mac is off (it returns the raw value into chat).
- **"Must happen" behavior:** no hooks here — run the [`session-hygiene`](../plugins/core/skills/session-hygiene/SKILL.md)
  skill (freshness gate at start, end-of-session write when wrapping up, on-correction update after a
  correction) plus always-loaded instructions. Persist writes via the GitHub connector or a generated Code prompt.
- **Fallback:** for filesystem/shell/git actions, call the Mac via remote MCP, or generate a
  ready-to-run prompt/command for a Code session.

## Enablement (apply once 10.1 is installed)
1. **Connectors** (Settings > Connectors), confirm enabled: 1Password (op-mcp portal,
   `https://mcp.schnapp.bet/mcp`), Schnapp Mac, Schnapp GitHub, obsidian mcp. (1Password + Schnapp Mac
   + GitHub are already live on this account.)
2. **Skills** (Settings > Capabilities): add the must-have core skills first: `session-hygiene`,
   `surface-check`, `docs-lookup`. They do not auto-sync from the repo, so add the SKILL.md files here.
   Add domain skills on demand: `etl-pipeline-build`, `sql-server-patterns`, `quickbase`, `appfolio`,
   plus the available `data:*` / `pq-flat-map-type` / `sports-data-auditor` skills per the preset.
3. **Always-loaded instructions:** paste [`always-loaded-instructions.md`](always-loaded-instructions.md)
   into this Project's custom-instructions field.
4. **Verify:** run `surface-check`. Expect connectors present, global rules + session-hygiene loaded,
   no hooks (expected here), persist via GitHub connector or a generated Code prompt.
