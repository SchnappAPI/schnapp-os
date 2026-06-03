# Surface: claude.ai (web + chat)

- **Skills:** added in claude.ai settings (per account; org-provisioned on Team/Enterprise).
  The same SKILL.md files from this repo are used; they do not auto-sync, so enable them here.
- **Tools/credentials:** hosted MCP connectors only (1Password, GitHub, Mac ops), enabled in
  Settings > Connectors. No local filesystem, no shell, no hooks.
- **"Must happen" behavior:** carried by always-loaded instructions + skills, not hooks.
- **Fallback:** for filesystem/shell/git actions, call the Mac via remote MCP, or generate a
  ready-to-run prompt/command for a Code session.
