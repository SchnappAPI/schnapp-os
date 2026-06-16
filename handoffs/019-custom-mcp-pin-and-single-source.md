# Handoff 019 — QUEUED: single-source + pin the other custom MCP servers

Date: 2026-06-16. Surface: claude.ai web (recon via Schnapp Mac connector). Status: NOT STARTED — scoped only.

## Why this exists
Handoff 018 fixed the Obsidian MCP, which broke because its venv deps were unpinned and an `mcp`
minor bump shifted the auth-provider API. That prompted a recon of the other custom MCP servers to
see if they carry the same latent risk. They partly do — plus a separate gap (not version-controlled).
This is the scoped follow-up; nothing here is executed yet.

## Recon findings (2026-06-16)
Custom MCP servers on Schnapps-MBP (all reached via the `schnapp-mac` cloudflared tunnel):

| Server      | Path / venv                         | Port | Auth          | In repo? | Deps pinned? | Installed (mcp/fastmcp/starlette/uvicorn/pydantic) |
|-------------|-------------------------------------|------|---------------|----------|--------------|----------------------------------------------------|
| obsidian-mcp| ~/obsidian-mcp (symlink -> repo)    | 8767 | OAuth2.1+PKCE | YES      | YES (this wk)| 1.27.2 / (removed) / 1.3.1 / 0.49.0 / 2.13.4       |
| mac-mcp     | ~/mac-mcp/server.py + venv          | 8765 | Bearer token  | **NO**   | **NO**       | 1.27.0 / 3.2.4 / 1.0.0 / 0.46.0 / 2.13.3           |
| github-mcp  | ~/github-mcp/server.py + venv       | 8766 | Bearer token  | **NO**   | **NO**       | 1.27.0 / 3.2.4 / 1.0.0 / 0.46.0 / 2.13.3           |
| op-mcp (1P) | repo connectors/op-mcp/; runtime=?  | n/a  | CF Access     | YES(src) | unknown      | different stack — see below                        |

Two distinct gaps for mac-mcp + github-mcp:
1. **Not single-sourced.** `server.py` is a plain on-Mac file, NOT symlinked into `claude-kit`
   (obsidian-mcp was fixed this way in decision 0008). No version-controlled copy — if the Mac is
   lost, the source is gone. This is arguably the bigger risk than pinning.
2. **Unpinned deps.** No requirements.txt; currently on fastmcp 3.2.4 / mcp 1.27.0 (note: DIFFERENT
   from obsidian-mcp's 1.27.2 — each venv drifted independently). A `pip install -U` or venv rebuild
   pulls latest and could break them the way Obsidian broke.

Severity note: both use **Bearer-token auth, not the hand-rolled OAuth provider** that implements
mcp's auth interface, so they do NOT carry the specific provider-API-drift that bit Obsidian. The
exposed surface (tool defs + streamable-http transport) is more stable across mcp versions. Real
risk, lower blast radius. They are working today on 1.27.0.

op-mcp / 1Password (`mcp.schnapp.bet`): source exists in repo at `connectors/op-mcp/`, but the
running thing is an MCP *portal/gateway* behind Cloudflare Access (tools `portal_list_servers`,
`portal_toggle_servers`, `op-mcp_*`), not a simple Mac python venv. The 1Password *desktop app*
processes on the Mac are unrelated. Its runtime/host and dep-management need separate investigation
before any pinning — do not lump it in with mac/github.

## Recommended plan (when picked up)
Mirror the obsidian-mcp pattern, per server, lowest-risk order (github-mcp first — least critical):
1. Import `~/<svc>/server.py` into `connectors/<svc>/` in the repo; replace the on-Mac file with a
   symlink to the repo copy (launchd plist untouched). Add `.env.template` + `.gitignore` + README,
   matching connectors/obsidian-mcp/.
2. Add `requirements.txt` (pin mcp/uvicorn/starlette/pydantic to the currently-installed, working
   versions — 1.27.0 etc., NOT obsidian's 1.27.2 unless you also retest) + `requirements.lock.txt`
   (pip freeze). Remove standalone `fastmcp` if unused (check `grep -E "import fastmcp|from fastmcp"`
   — obsidian didn't use it; verify per server).
3. Restart each via `launchctl kickstart -k gui/$UID/<label>` (labels: com.schnapp.macmcp,
   com.schnapp.githubmcp) and smoke-test: tunnel 200 on /.well-known or a Bearer-authed tool call.
4. Log decision (single-source + pin rationale) and update CONNECTIONS.md if paths change.
5. Separately: investigate op-mcp's actual deployment before deciding if/how to pin it.

Effort: ~30–45 min for mac+github together (no OAuth complexity). op-mcp is a separate, larger unknown.

## Pointers
- Reference implementation: connectors/obsidian-mcp/ (requirements.txt, .env.template, README, symlink).
- Decision 0008 (single-source rationale), 0009 (the dep-drift failure mode), handoff 018 (full repair).
- Infra doc: ~/code/schnapp-bet/docs/CONNECTIONS.md (service labels, ports, recovery commands).

## EXECUTED 2026-06-16 (same day)
Both servers single-sourced + pinned, mirroring connectors/obsidian-mcp/.
- **github-mcp** (commit 0e6a04f): repo copy + symlink + requirements.txt (mcp==1.27.0, requests/
  starlette/uvicorn) + lock + .env.template + README + .gitignore. Restarted clean (fast), authed
  smoke OK: initialize 200, tools/list 200, **43 tools**.
- **mac-mcp** (commit 85fc26e): same treatment (+ rotate_logs.sh mirrored, NOT symlinked). Booted
  from the symlink and is stable + listening on 127.0.0.1:8765, serving live connector traffic.
- fastmcp standalone was unused in both; left installed (not uninstalled) on these live venvs to
  minimise mutation — captured in each lock. Dead-code: none to remove (these weren't OAuth servers).

### Operational finding — mac-mcp restart is SLOW (~2 min), not instant
Restarting com.schnapp.macmcp via `kickstart -k` took ~2 min to return to a listening state (25×
~4s polls of HTTP 000 before it bound :8765), with one intermediate launchd exit-status 1. It
recovered to a stable process and has stayed up. Cause not definitively pinned; consistent with
launchd restart-throttle (kickstart racing KeepAlive) + op-wrap secret resolution on each boot.
Implication: do NOT expect mac-mcp back in seconds after a restart/reboot — budget ~1-2 min, and if
automating, poll for :8765 LISTEN rather than assuming. github-mcp did NOT show this (came back fast).
Worth a follow-up if reboot resilience matters: check the macmcp plist ThrottleInterval and whether
startup does any blocking network/SQL probe. Logged as a watch-item, not fixed.

### Testing note
Could not run a nested authed tools/list against mac-mcp from inside a mac-mcp tool call — the server
is single-worker and was busy serving that very call (self-deadlock → ReadTimeout). Health is instead
proven by (a) all shell_exec/op_run calls succeeding through it and (b) lsof showing it stably LISTEN
on :8765. github-mcp's authed check worked because it is not the operating channel.

Status: **DONE.** op-mcp/1Password (different portal stack) remains the only unaddressed item — separate investigation. Part 10 still NEXT.
