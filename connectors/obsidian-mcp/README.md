# obsidian-mcp — vault MCP (canonical source)

This is the **source of truth** for the live Obsidian MCP. It is a Python FastMCP server that
serves the owner's Obsidian vault to every surface (claude.ai, iPhone, Cowork, Code).

## Deployment (single source of truth)

- **Source lives here**: `server.py` (this file is canonical).
- **The Mac runs it from here**: `~/obsidian-mcp/server.py` is a **symlink** to this file, launched by
  launchd agent `com.schnapp.obsidian-mcp` via `op-wrap.sh` (secrets injected from `.env.template`).
  Edit `server.py` here, push, then restart the service to deploy:
  `launchctl kickstart -k gui/$UID/com.schnapp.obsidian-mcp`.
- **Authoritative runtime/infra detail** (port, OAuth, tunnel, recovery): `schnapp-bet`
  `docs/CONNECTIONS.md` → "Obsidian MCP" / "Obsidian Brain Agent". Do not duplicate it here.

Local-only runtime artifacts (`venv/`, `oauth_state.json`, `*.log`, `__pycache__/`) stay on the Mac
and are gitignored — they are not source.

## Tools (7)

`search_notes`, `read_note`, `list_notes` (read); `write_note`, `append_note` (write);
`inbox_drop` (drops a note into `Inbox/`, which the **brain agent** classifies via FSEvents);
`get_index` (brain agent index: notes, clusters, pending actions).

## Mac-dependency note (decisions/0008)

The server is **Mac-hosted**, so off-Mac vault access requires the Mac powered on. This was a
deliberate, logged choice (`decisions/0008`): the brain/inbox integration is inherently Mac-resident,
and the plan permits "always-complete via fallback" for knowledge. **Fallback when the Mac is off**:
the GitHub `obsidian-vault` mirror (kept current by obsidian-git) and this repo's own
`memory/` + `decisions/`. See the `docs-lookup` skill for the usage entry point.

## Secrets

`.env.template` holds only `op://` references (never values); `op-wrap.sh` resolves them at launchd
start. `MAC_MCP_AUTH_TOKEN` = `op://web-variables/MCP Tokens/schnapp_mac`.
