---
last-verified: 2026-07-18
sources:
  - connectors/obsidian-mcp/server.py
---

# obsidian-mcp - vault MCP (canonical source)

This is the **source of truth** for the live Obsidian MCP. It is a Python FastMCP server that
serves the owner's Obsidian vault to every surface (claude.ai, iPhone, Cowork, Code).

## Deployment (single source of truth)

- **Source lives here**: `server.py` (this file is canonical).
- **The Mac runs it from here**: `~/obsidian-mcp/server.py` is a **symlink** to this file, launched by
  launchd agent `com.schnapp.obsidian-mcp` via `op-wrap.sh` (secrets injected from `.env.template`).
  Edit `server.py` here, push, then restart the service to deploy:
  `launchctl kill TERM gui/$(id -u)/com.schnapp.obsidian-mcp` (graceful: KeepAlive relaunches; pre-bound SO_REUSEADDR socket - decision 0010). Do not use `kickstart -k`.
- **Authoritative runtime/infra detail** (port, tunnel, recovery): `schnapp-bet`
  `docs/CONNECTIONS.md` → "Obsidian MCP" / "Obsidian Brain Agent". Do not duplicate it here.

Local-only runtime artifacts (`venv/`, `*.log`, `__pycache__/`) stay on the Mac and are
gitignored - they are not source.

## Auth (static bearer)

Same pattern as mac-mcp: every request must carry the bearer, either
`Authorization: Bearer <token>` or `?token=<token>`; anything else gets
`401 {"error": "unauthorized"}`. The server reads the token from `OBSIDIAN_MCP_AUTH_TOKEN`
(`op://web-variables/OBSIDIAN_MCP_AUTH_TOKEN/credential`, resolved by `op-wrap.sh` from
`~/obsidian-mcp/.env.template`). The client leg is the Cloudflare portal (`mcp.schnapp.bet`)
with the same value as a Custom `Authorization` header - adding the obsidian-mcp slot to the
portal is an owner step (claude.ai's connector UI is OAuth-only, so no direct-bearer
standalone connector). The former hand-rolled OAuth 2.1/PKCE/DCR machinery (ADR 0009's
subject) was removed 2026-07-18; `oauth_state.json` is gone with it.

## Tools (7)

`search_notes`, `read_note`, `list_notes` (read); `write_note`, `append_note` (write);
`inbox_drop` (drops a note into `Inbox/`, which the **brain agent** classifies via FSEvents);
`get_index` (brain agent index: notes, clusters, pending actions).

## Mac-dependency note (decisions/0008)

The server is **Mac-hosted**, so off-Mac vault access requires the Mac powered on. This was a
deliberate, logged choice (`decisions/0008`): the brain/inbox integration is inherently Mac-resident,
and the plan permits "always-complete via fallback" for knowledge. **Fallback when the Mac is off**:
the GitHub `schnapp-vault` mirror (kept current by obsidian-git) and this repo's own
`memory/` + `decisions/`. See the `notes-lookup` skill for the usage entry point.
