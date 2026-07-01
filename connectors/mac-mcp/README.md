---
last-verified: 2026-07-01
sources:
  - connectors/mac-mcp/server.py
---

# mac-mcp

Self-hosted MCP server for Mac operations (shell_exec, op_run, file ops, SQL queries,
service control, live sports). Bearer-token auth (`MAC_MCP_AUTH_TOKEN`); secrets resolved
at launch via `op-wrap.sh` + `~/mac-mcp/.env.template` (op:// refs). Reached off-Mac through the
shared Cloudflare MCP portal (`mcp.schnapp.bet`, the "Schnapp Portal" connector) for claude.ai/iPhone,
and directly via `.mcp.json` (`Schnapp_Mac`, bearer header) for Code/Cowork. Talks to SQL Server via pyodbc.

- URL: https://mac-mcp.schnapp.bet/mcp  (Mac :8765 via the schnapp-mac tunnel)
- Service: launchd `com.schnapp.macmcp` (RunAtLoad, KeepAlive). Log rotation:
  `com.schnapp.macmcp.logrotate` runs `~/mac-mcp/rotate_logs.sh` (mirrored here for the
  record; the live copy stays on the Mac and is NOT symlinked).
- **Single source of truth: this repo.** The Mac runs it via symlink
  `~/mac-mcp/server.py -> connectors/mac-mcp/server.py`. Edit here, then restart:
  `launchctl kill TERM gui/$(id -u)/com.schnapp.macmcp` (graceful: KeepAlive relaunches; the entrypoint serves a pre-bound SO_REUSEADDR socket so there is no [Errno 48] race — decision 0010). Do not use `kickstart -k` (SIGKILL skips uvicorn's clean socket close).
- Deps pinned (requirements.txt) + locked (requirements.lock.txt). Bump only after smoke-testing.
