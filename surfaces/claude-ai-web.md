# Surface: claude.ai (web + chat)

- **Skills:** added in claude.ai settings (per account; org-provisioned on Team/Enterprise).
  The same SKILL.md files from this repo are used; they do not auto-sync, so enable them here.
- **Tools/credentials:** hosted MCP connectors only, enabled in Settings > Connectors. One
  **Schnapp Portal** connector is the Cloudflare MCP portal `https://mcp.schnapp.bet/mcp` (Managed
  OAuth → origins); it fronts the four static-bearer servers - **op-mcp** (secrets), **memory-mcp**,
  **mac-mcp** (shell/SQL/files), **github-mcp**: so one OAuth connector exposes all their tools.
  **obsidian-mcp** is a separate connector (its own native OAuth, not portal-fronted). Connector/auth
  topology + health: [`memory/credentials-state.md`](../memory/credentials-state.md) (canonical). No
  local filesystem, shell, or hooks. To USE a secret, call the Mac's `op_run`/`op_inject` (value
  scrubbed); use op-mcp `op_read` only when the Mac is off AND the portal is healthy (returns the raw
  value into chat).
- **"Must happen" behavior:** no hooks here - run the [`session-hygiene`](../.claude/skills/session-hygiene/SKILL.md)
  skill (freshness gate at start, end-of-session write when wrapping up, on-correction update after a
  correction) plus always-loaded instructions. Persist writes via the GitHub connector or a generated Code prompt.
- **Fallback:** for filesystem/shell/git actions, call the Mac via remote MCP, or generate a
  ready-to-run prompt/command for a Code session.

## Enablement (apply once 10.1 is installed)
1. **Connectors** (Settings > Connectors), confirm enabled: **Schnapp Portal**
   (`https://mcp.schnapp.bet/mcp` - fronts op-mcp + memory-mcp + mac-mcp + github-mcp) and
   **obsidian mcp** (native OAuth). The old standalone "Schnapp Mac" / "Schnapp GitHub" connectors
   are retired - the portal carries those tools now.
2. **Skills** (Settings > Capabilities): add the must-have core skills first: `session-hygiene`,
   `surface-check`, `notes-lookup`. They do not auto-sync from the repo, so add the SKILL.md files here.
   Add domain skills on demand: `etl-pipeline-build`, `sql-server-patterns`, `quickbase`, `appfolio`,
   plus the available `data:*` / `pq-flat-map-type` / `sports-data-auditor` skills per the preset.
3. **Always-loaded instructions:** paste [`always-loaded-instructions.md`](always-loaded-instructions.md)
   into **Settings > Profile > Preferences** (account-wide / global - owner's choice 2026-06-16, so
   it applies to every chat and to iPhone on the same account). Use a dedicated Project's
   instructions instead only if you later want it scoped to schnapp-os work.
4. **Verify:** run `surface-check`. Expect connectors present, global rules + session-hygiene loaded,
   no hooks (expected here), persist via GitHub connector or a generated Code prompt.
