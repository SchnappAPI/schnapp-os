# 0009 — Obsidian MCP: fix dropped consent route breaking OAuth

Date: 2026-06-16. Status: DECIDED + EXECUTED.

## Context
The obsidian mcp connector (Mac-hosted FastMCP, blessed canonical in 0008) showed
"Connection has expired / Authorization with the MCP server failed" on claude.ai and
would not reconnect. Server was up (tunnel returned 401 on /mcp = healthy+auth-required),
so this was an OAuth-flow break, not an outage.

## Diagnosis
Tracing ~/obsidian-mcp/obsidian-mcp.log: every attempt ran POST /register (201) ->
GET /authorize (302) but then token exchange failed (POST /oauth/token 404, POST /token
401), and the client looped -- leaving 12 orphaned client registrations and codes: {} empty
in oauth_state.json. GET /consent returned 404: the interactive consent page was never
mounted, so no auth code was ever minted, so token exchange could not succeed.

Root cause: server.py attached the consent routes via `mcp._custom_routes = [...]`. Under the
installed mcp 1.27.2, FastMCP.streamable_http_app() builds its Starlette route table from
self._custom_starlette_routes (populated only by the custom_route() decorator). The private
_custom_routes attribute is read by nothing -- the assignment was silently ignored and the
routes were dropped. A library version bump moved the internal attribute out from under the
hack. (The fastmcp 3.4.2 package is also installed but unused; the import is mcp.server.fastmcp.)

## Decision / fix
Use the supported public API instead of the private attribute:
    mcp.custom_route("/consent", methods=["GET"])(consent_get)
    mcp.custom_route("/consent", methods=["POST"])(consent_post)
Verified in-process (/consent present in streamable_http_app().routes) before deploy.
Reset oauth_state.json to an empty slate (backed up) to clear the 12 orphaned clients and a
stale refresh token. Restarted via launchctl kickstart -k gui/$UID/com.schnapp.obsidian-mcp.
Post-deploy: public /consent -> 200 (was 404), /mcp -> 401 (healthy).

## Guidance captured
Never attach FastMCP routes by assigning private attributes -- they are version-fragile. Use
@mcp.custom_route(path, methods=[...]). When an MCP OAuth connector "won't reconnect" but the
server answers 401 on /mcp, suspect the authorize->consent->token leg, not the transport: check
that every endpoint in .well-known/oauth-authorization-server actually resolves (esp. any custom
consent page) and that codes/tokens in state are being written.
