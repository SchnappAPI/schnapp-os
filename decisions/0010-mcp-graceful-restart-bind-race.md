# 0010 — MCP connectors: kill the :8765 restart bind race (graceful TERM + reuse-socket)

Date: 2026-06-16. Status: DECIDED + EXECUTED. Executes handoff 020; written up in handoff 021.

## Context
Restarting `com.schnapp.macmcp` took ~2 min to recover (vs ~3s for github-mcp). Root cause
(confirmed in handoff 020): `launchctl kickstart -k` SIGKILLs the process; the fresh process races
to bind `127.0.0.1:8765` before the OS releases the old listen socket → `[Errno 48] Address already
in use` → exit 1 → ~10s launchd KeepAlive throttle → repeat until the socket frees. Restart hazard
only (a cold boot has no lingering socket).

## Surface correction (logged so it can't recur)
The task prompt asserted this ran "as Claude Code on the Mac — local shell ... normal restart is
safe, no daemon trick needed." False for the surface actually in use: **claude.ai web**, where the
Mac is reached *through* the `mac-mcp` connector (`mac-mcp.schnapp.bet` → `com.schnapp.macmcp`:8765).
A foreground restart of mac-mcp severs the very channel issuing it. Handoff 020 already flagged this
("mac-mcp is the operating channel"). Verified empirically (`shell_exec` is served by mac-mcp), then
restarted mac-mcp via a detached double-fork daemon — exactly as 020 prescribed. github-mcp and
obsidian-mcp are not the operating channel and were restarted in the foreground.

## Decision / fix (two layers, defense-in-depth)
1. **Graceful restart, not SIGKILL.** Restart via `launchctl kill TERM gui/$(id -u)/<label>` so
   uvicorn's signal handler closes the listen socket cleanly before KeepAlive relaunches. Replaced
   the mac-mcp recovery command in `schnapp-bet/docs/CONNECTIONS.md` (was bootout/bootstrap).
   Empirically confirmed `op run` (via op-wrap.sh `exec op run -- python`) **does** forward SIGTERM
   to the python child: obsidian's log showed `Application shutdown complete` before relaunch.
2. **Reuse-tolerant bind (the real guarantee).** In each connector's `__main__`, pre-create the
   listen socket with `SO_REUSEADDR` + `SO_REUSEPORT`, then hand it to uvicorn via
   `uvicorn.Server(uvicorn.Config(app, host, port)).run(sockets=[sock])`. SO_REUSEPORT lets a new
   LISTEN socket bind the port even while an old one lingers, so the race cannot reappear even if a
   future restart is abrupt. Applied uniformly to all three: mac-mcp (:8765), github-mcp (:8766),
   obsidian-mcp (:8767).

## Implementation notes / behavior preservation
- mac-mcp & github-mcp already ended in `uvicorn.run(app, host, port)` → swapped to the explicit
  `Server(Config(...)).run(sockets=[sock])` form (host/port retained for the startup log line).
  Bearer middleware wrappers unchanged (`_BearerAuthMiddleware(app)` / `add_middleware`).
- obsidian-mcp ended in `mcp.run(transport="streamable-http")` (FastMCP's runner), which has no
  socket/fd hook. Its `__main__` was converted to **mirror FastMCP 1.27.2's**
  `run_streamable_http_async()` exactly — same `mcp.streamable_http_app()` (which carries the OAuth
  consent routes from decision 0009) and same `Config(host, port, log_level)` — changing only the
  bind to the pre-bound socket. Verified post-deploy that `/consent` → 200 and `/mcp` → 401 still
  hold (OAuth leg intact), so the conversion did not regress behavior.
- Edited **repo copies only** (`connectors/*/server.py`); each `~/<svc>/server.py` is a symlink to
  the repo (decision 0008), so a restart deploys. Diff is confined to the three `__main__` blocks.
- **Deps untouched** (decisions 0008/0009): mcp/uvicorn/starlette/pydantic not bumped. `Server.run`/
  `Config(fd=)`/`serve(sockets=)` already exist in the pinned uvicorn.

## Evidence (post-deploy, 2026-06-16)
- github-mcp: rebound 2.79s; authed initialize 200 + tools/list 200 (43 tools); 0 new errno-48.
- obsidian-mcp: rebound 2.32s; /mcp 401 + /consent 200; 0 new errno-48; clean graceful shutdown.
- mac-mcp: rebound **2.56s** (was ~2 min); authed CallToolRequest served on the reconnected
  channel; 0 new errno-48. Verified via detached daemon writing ~/mac-mcp/restart_verify.json.

## Follow-ups (optional, not blocking)
- github-mcp / obsidian-mcp recovery commands in CONNECTIONS.md still use bootout/bootstrap (a full
  reload — not the SIGKILL race), and could be simplified to the same graceful TERM for consistency.
- macmcp.plist `ThrottleInterval` left unset; unnecessary now that rebind is ~2.5s.
- Dead OAuth code in obsidian server.py (AuthCode/StoredRefreshToken/_verify_pkce, noted in 0009)
  still present; out of scope here.
