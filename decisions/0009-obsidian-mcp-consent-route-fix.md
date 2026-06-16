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

## Update — consent fix was necessary but not sufficient
End-to-end testing (curl driving register->authorize->consent->token->/mcp) revealed the entire
OAuth provider was written against an older mcp and broke against 1.27.2's stricter validation.
Full set of fixes applied in the same file:
- get_client/register_client: persist and round-trip the COMPLETE client registration
  (model_dump/model_validate). Previously dropped scope + token_endpoint_auth_method ->
  `invalid_scope` at /authorize and "Unsupported auth method: None" at /token.
- ClientRegistrationOptions: set valid_scopes/default_scopes=["mcp:tools"] so DCR clients
  actually carry the scope the authorize step checks.
- authorize(): AuthorizationParams no longer has `code_challenge_method` -> hardcode "S256"
  (the AttributeError surfaced as error=server_error at /authorize).
- load_authorization_code/exchange_authorization_code: return the framework AuthorizationCode
  model (fields: scopes[list], redirect_uri_provided_explicitly, resource, subject) instead of a
  hand-rolled AuthCode; the missing `redirect_uri_provided_explicitly` 500'd the token handler.
  PKCE is now verified by the framework before exchange — removed the dead hand-rolled PKCE.
- load_refresh_token/exchange_refresh_token: return framework RefreshToken model; look up the
  prior access token from state rather than a custom attribute.
Verified: token 200, initialize 200, tools/list returns all 7 tools.

## Follow-ups (not yet done)
- Pin `mcp` in the venv (currently floating; a future bump can break the provider again). fastmcp
  3.4.2 is installed but unused.
- Dead code left in place (AuthCode class, StoredRefreshToken, _verify_pkce) — safe to delete.
