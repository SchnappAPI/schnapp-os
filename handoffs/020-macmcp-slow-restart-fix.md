# Handoff 020 — QUEUED: fix mac-mcp slow/failed restart (bind race on :8765)

Date: 2026-06-16. Surface: claude.ai web (read-only recon via Schnapp Mac connector). Status: NOT STARTED — diagnosed + scoped.

## TL;DR
Restarting com.schnapp.macmcp takes ~2 min to recover (vs seconds for github-mcp). **Root cause is
confirmed**, not hypothetical: `launchctl kickstart -k` SIGKILLs the process, and the fresh process
races to bind 127.0.0.1:8765 before the OS releases the old listening socket → `[Errno 48] Address
already in use` → process exits 1 → launchd KeepAlive throttles the retry (~10s default) → repeat
until the socket frees. mcp.err.log shows **11 errno-48 occurrences** and an intermediate launchd
exit-status 1. It is a RESTART hazard only — a cold reboot has no lingering socket, so boot resilience
is probably fine. Fix = make restarts graceful and/or make the bind reuse-tolerant. Low effort.

## Evidence (gathered 2026-06-16, read-only)
- `grep -c "Address already in use" ~/mac-mcp/mcp.err.log` → **11**.
- launchd entry showed an intermediate `com.schnapp.macmcp` exit status **1** during recovery; the
  detached verifier polled :8765 and saw HTTP 000 for ~100s before it bound, then went stable.
- **Ruled out** op-secret resolution: op-wrap.sh resolves the SAME 21 (global schnapp-bet .env.template)
  + 2 (local) = 23 op:// refs for BOTH mac-mcp and github-mcp; github-mcp restarts fast. Not the cause.
- **Ruled out** a blocking startup probe: every requests.get/post in server.py is inside a tool
  function; the entrypoint is just:
    ```
if __name__ == "__main__":
    app = mcp.streamable_http_app()
    uvicorn.run(_BearerAuthMiddleware(app), host="127.0.0.1", port=8765)
    ```
  No pyodbc, no module-level network/SQL call. Startup is import → build app → uvicorn.run(:8765).
- macmcp.plist: KeepAlive=true, RunAtLoad=true, **no explicit ThrottleInterval** (launchd default ~10s),
  WorkingDirectory ~/mac-mcp, logs to mcp.log / mcp.err.log.

## Fix (recommended order)
1. **Stop SIGKILL-restarting it.** Replace `kickstart -k` with a graceful TERM so uvicorn closes the
   listening socket before launchd KeepAlive relaunches:
   `launchctl kill TERM gui/$(id -u)/com.schnapp.macmcp`  (KeepAlive brings it back on its own).
   Update CONNECTIONS.md (its mac-mcp recovery currently uses bootout/bootstrap, also abrupt).
2. **Make the bind race-proof (belt & suspenders).** In server.py `__main__`, bind a pre-created
   socket with SO_REUSEADDR (and SO_REUSEPORT on macOS) and hand it to uvicorn, so a new process can
   bind even if the old socket lingers in TIME_WAIT. Sketch:
     ```python
     import socket
     sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
     sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
     sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
     sock.bind(("127.0.0.1", 8765)); sock.listen()
     uvicorn.run(_BearerAuthMiddleware(app), fd=sock.fileno())
     ```
   (Edit the repo copy — connectors/mac-mcp/server.py — it is symlinked live; restart to deploy.)
3. Optional: add `ThrottleInterval` (e.g. 3) to macmcp.plist so any residual retry is faster.
4. **Apply the same to obsidian-mcp + github-mcp** for consistency — they share the uvicorn(:port)
   pattern and only avoided this by winning the race. Cheap to harden all three at once.

## Verify (CAUTION: mac-mcp is the operating channel)
Restarting mac-mcp drops the Schnapp Mac connector for the recovery window. Do NOT restart it from a
foreground tool call (the call dies with it, and macOS has no `setsid`). Use a Python double-fork
daemon (os.fork → os.setsid → os.fork → exec) that performs the restart, polls :8765 for LISTEN, and
writes timing to a log; then read the log from a later call. Target: rebind in < ~10s with zero new
errno-48 in mcp.err.log. github-mcp can be tested normally (not the operating channel).

## Pointers
- Cause evidence: ~/mac-mcp/mcp.err.log (errno 48), macmcp.plist, op-wrap.sh.
- Reference: handoff 018/019, decisions 0008 (symlink single-source: edit repo → restart to deploy).
- Infra doc: ~/code/schnapp-bet/docs/CONNECTIONS.md — update mac-mcp recovery command after the fix.
