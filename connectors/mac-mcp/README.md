---
last-verified: 2026-07-16
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
  `launchctl kill TERM gui/$(id -u)/com.schnapp.macmcp` (graceful: KeepAlive relaunches; the entrypoint serves a pre-bound SO_REUSEADDR socket so there is no [Errno 48] race - decision 0010). Do not use `kickstart -k` (SIGKILL skips uvicorn's clean socket close).
- Deps pinned (requirements.txt) + locked (requirements.lock.txt). Bump only after smoke-testing.
- **Responses are self-identifying; portal-side correlation is not trusted.** The portal in front of
  this server was once seen returning one call's stdout against a different call's request
  ([decision 0034](../../decisions/0034-self-identifying-mcp-responses.md)). Every response carries a
  server-generated `call_id` + UTC `ts`; the opaque-output tools (`shell_exec`, `op_run`, `sql_query`)
  also echo the caller's own `command`/`query`. **Confirm the echo is what you sent before trusting
  the payload** - that check is the caller's, not the server's. `mcp.err.log` logs each `call_id`
  with its real input (redacted), so a suspect response traces back to the command that produced it.
- Command timeouts cap at `MAX_COMMAND_TIMEOUT_SECONDS` (90s), below the edge's ~100s origin deadline
  so a long command cannot orphan a response nobody is waiting for. A clamp is reported as
  `timeout_clamped_from`, never applied silently. New tool docstrings reach a client only when it
  reconnects; the envelope is live immediately either way.
- The launchd plist is NOT repo-tracked (same convention as `rotate_logs.sh`'s live copy). Current
  state, for the record: `MaterializeDatalessFiles = true` (added 2026-07-16, backup
  `.bak-20260716`) so `shell_exec` children can hydrate OneDrive Files-On-Demand placeholders;
  `RunAtLoad` + `KeepAlive`; runs via `op-wrap.sh` -> venv python -> `~/mac-mcp/server.py`.
