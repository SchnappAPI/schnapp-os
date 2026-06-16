# Handoff 018 — Obsidian MCP OAuth repaired (provider realigned to mcp 1.27.2). Part 10 still NEXT.

Date: 2026-06-16. Surface: claude.ai web (edits + diagnosis via Schnapp Mac connector).

## TL;DR
The obsidian mcp connector would not reconnect ("Authorization with the MCP server failed").
The server was healthy the whole time — the hand-rolled OAuth provider in `connectors/obsidian-mcp/
server.py` was written against an older `mcp` and silently broke against the installed `mcp` 1.27.2.
Fixed five distinct version-drift breakages, verified the full flow end-to-end, pinned deps so it
can't recur. Capability layer + Parts 0-9 unchanged. **Part 10 (package + wire surfaces) remains next.**

## Symptom
claude.ai showed "Connection has expired / Authorization with the MCP server failed" and Connect
did nothing. Not an outage: `/mcp` returned 401 (up + auth-required) and the python proc was running.

## Root cause — provider stale vs mcp 1.27.2 (each only surfaced after the prior fix)
1. Consent page mounted via `mcp._custom_routes = [...]`; FastMCP builds its app from
   `_custom_starlette_routes` (populated by the `custom_route()` decorator) → `/consent` 404 →
   no auth code ever minted → token exchange failed → client looped, leaving 12 orphaned DCR clients.
2. `get_client()` reconstructed only 4 fields, dropping `scope` + `token_endpoint_auth_method` →
   `invalid_scope` at /authorize, "Unsupported auth method: None" at /token.
3. `ClientRegistrationOptions` set no scopes → DCR clients never carried `mcp:tools`.
4. `authorize()` read `params.code_challenge_method`, a field removed from `AuthorizationParams`
   in 1.27.2 → AttributeError → `error=server_error` at /authorize.
5. `load_authorization_code` returned a hand-rolled `AuthCode` missing
   `redirect_uri_provided_explicitly` (and `.scope` vs `.scopes`) → token handler 500.

## Fixes (all in connectors/obsidian-mcp/server.py; symlinked live, restart to deploy)
- Consent routes via `mcp.custom_route("/consent", ...)` (supported API).
- get_client/register_client: persist + round-trip the FULL registration (model_dump/model_validate).
- ClientRegistrationOptions: valid_scopes=default_scopes=["mcp:tools"].
- authorize(): hardcode code_challenge_method "S256".
- load_/exchange_authorization_code + load_/exchange_refresh_token: return framework
  AuthorizationCode / RefreshToken models; framework now verifies PKCE (removed hand-rolled PKCE).
- Reset oauth_state.json (cleared 12 orphaned clients + stale refresh token).

## Hardening
- Added `requirements.txt` (mcp==1.27.2, uvicorn, starlette, pydantic pinned) + `requirements.lock.txt`
  (full freeze). Removed unused standalone `fastmcp` 3.4.2 from the venv. Bump only after re-running
  the e2e OAuth test.

## Verified
End-to-end via curl (register → authorize → consent → token → /mcp): token 200, initialize 200,
tools/list returns all 7 tools (read_note, write_note, append_note, search_notes, list_notes,
inbox_drop, get_index). Public health: /.well-known 200, /mcp 401.

## Commits (pushed, main)
- 0ab4316 consent route via custom_route
- eaaec24 align OAuth provider to mcp 1.27.2
- (this session) dep pin + lock + drop fastmcp
- decisions/0009 logged + updated with the full account.

## Remaining
- Owner: click Connect on the obsidian mcp connector to re-establish the live session (server side done).
- Optional cleanup: delete now-dead code (AuthCode class, StoredRefreshToken, _verify_pkce). Cosmetic.
- Part 10 (package + wire surfaces) — still the next planned work, unchanged by this session.
