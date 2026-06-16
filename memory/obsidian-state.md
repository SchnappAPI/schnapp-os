---
name: obsidian-state
metadata:
  node_type: memory
  scope: global
  source: "schnapp-bet docs/CONNECTIONS.md (Obsidian MCP / Brain Agent); handoffs/016"
  updated: 2026-06-16
  supersedes: ""
  originSessionId: claude-ai-web-2026-06-16-stale-review
---

Obsidian vault + MCP topology (the off-Mac path was previously documented wrong; this is the
verified state as of 2026-06-16). Authoritative infra detail lives in `schnapp-bet`
`docs/CONNECTIONS.md` ("Obsidian MCP", "Obsidian Brain Agent") — reference it, do not duplicate.

- **Canonical vault:** `~/Library/CloudStorage/OneDrive-Schnapp/Obsidian` (OneDrive-synced).
  `~/Documents/Obsidian` is now a **symlink** to it (back-compat — old paths still resolve).
- **On the Mac (Code):** the npm `obsidian` stdio MCP (`search-vault`, `read-note`,
  `list-available-vaults`) pointed at `~/Documents/Obsidian`. Works as-is.
- **Off-Mac (claude.ai, iPhone, Cowork):** the **Mac-hosted FastMCP server**
  `~/obsidian-mcp/server.py` (port 8767, OAuth 2.1 + PKCE + DCR) at
  `https://obsidian-mcp.schnapp.bet/mcp`. Tools (7): `search_notes`, `read_note`, `list_notes`,
  `write_note`, `append_note`, `inbox_drop`, `get_index`. Connected + verified in claude.ai.
- **Canonical source IN REPO:** `connectors/obsidian-mcp/server.py` is the source of truth; the Mac
  runs it via symlink (`~/obsidian-mcp/server.py` -> repo), plist unchanged (decisions/0008). The old
  Render/TS implementation was retired. Off-Mac access is Mac-dependent; fallback = GitHub mirror +
  this repo's `memory/`+`decisions/`.
- The `docs-lookup` skill is the usage entry point (corrected to these tool names 2026-06-16).
