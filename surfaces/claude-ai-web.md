# Surface: claude.ai (web + chat)

- **Skills:** added in claude.ai settings (per account; org-provisioned on Team/Enterprise).
  The same SKILL.md files from this repo are used; they do not auto-sync, so enable them here.
- **Tools/credentials:** hosted MCP connectors only, enabled in Settings > Connectors. The
  **1Password** connector is LIVE: the op-mcp portal `https://mcp.schnapp.bet/mcp` (Cloudflare
  Managed OAuth → Render). Also GitHub + the Mac ops connector ("Schnapp Mac"). No local
  filesystem, shell, or hooks. To USE a secret, call the Mac's `op_run`/`op_inject` (value
  scrubbed); use op-mcp `op_read` only when the Mac is off (it returns the raw value into chat).
- **"Must happen" behavior:** carried by always-loaded instructions + skills, not hooks.
- **Fallback:** for filesystem/shell/git actions, call the Mac via remote MCP, or generate a
  ready-to-run prompt/command for a Code session.
