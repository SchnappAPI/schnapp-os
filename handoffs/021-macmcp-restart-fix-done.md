# Handoff 021 — DONE: mac-mcp slow restart fixed (bind race eliminated, all 3 MCPs hardened)

Date: 2026-06-16. Surface: claude.ai web (Schnapp Mac connector + GitHub connector). Status: COMPLETE.
Executes handoff 020. Decision: 0010.

## What shipped
Killed the `[Errno 48]` restart bind race that made `com.schnapp.macmcp` take ~2 min to recover.
Two-layer fix, applied to all three connectors (`connectors/{mac-mcp,github-mcp,obsidian-mcp}/server.py`):
1. **Graceful restart**: `launchctl kill TERM gui/$(id -u)/<label>` (KeepAlive relaunches) replaces
   `kickstart -k` SIGKILL, so uvicorn closes the listen socket cleanly.
2. **Reuse-tolerant bind**: pre-create the socket with SO_REUSEADDR + SO_REUSEPORT and serve it via
   `uvicorn.Server(uvicorn.Config(app, host, port)).run(sockets=[sock])`.

Edited repo copies only (symlinked live per decision 0008 → restart deploys). Deps NOT bumped
(0008/0009). Diff confined to each file's `__main__` block. obsidian-mcp's entrypoint was converted
from `mcp.run(transport="streamable-http")` to an exact mirror of FastMCP 1.27.2's
`run_streamable_http_async()` (same app + log_level) plus the reuse socket — OAuth consent route
preserved (verified).

## Verified (post-deploy)
| connector | port | rebind | authed serving | new errno-48 |
|---|---|---|---|---|
| github-mcp   | 8766 | 2.79s | initialize 200, tools/list 200 (43 tools) | 0 |
| obsidian-mcp | 8767 | 2.32s | /mcp 401 + /consent 200 (OAuth leg intact) | 0 |
| mac-mcp      | 8765 | 2.56s | authed CallToolRequest on reconnected channel | 0 |

mac-mcp was restarted via a **detached double-fork daemon** (it is the operating channel on
claude.ai web; a foreground restart severs the call). The daemon wrote ~/mac-mcp/restart_verify.json.
NOTE: the task prompt said "running as Claude Code on the Mac — local shell, no daemon trick needed";
that was wrong for this surface (claude.ai web → Mac via the mac-mcp connector). Handoff 020 had it
right. See decision 0010 "Surface correction".

## Also changed
- `schnapp-bet/docs/CONNECTIONS.md`: mac-mcp recovery command → graceful TERM (hard reload kept as
  fallback). Pushed to schnapp-bet main.

## Follow-ups (optional, non-blocking)
- Move github/obsidian recovery commands in CONNECTIONS.md to the same graceful TERM for consistency.
- Delete obsidian dead OAuth code (AuthCode/StoredRefreshToken/_verify_pkce — noted in 0009).
- macmcp.plist ThrottleInterval still unset (unnecessary now).

## Next planned work
Part 10 — package + wire surfaces. Part 11 — scheduler, orchestrator, control plane. (PLAN.md.)
