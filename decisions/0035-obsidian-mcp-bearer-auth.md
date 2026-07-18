# 0035 — obsidian-mcp drops hand-rolled OAuth for fleet-standard static bearer

Date: 2026-07-18. Status: DECIDED and EXECUTED.

## Context
The 2026-06-30 substrate rethink (docs/repo-review-2026-06-30-substrate-rethink.md) greenlit
replacing obsidian-mcp's hand-rolled OAuth 2.1 + PKCE + DCR authorization server with static
bearer auth behind the Schnapp Portal (the ADR 0020 pattern), conditional on zero functionality
loss. It sat unexecuted 18 days. A 2026-07-18 read-only re-assessment strengthened the case: the
auth machinery measured ~335 lines (the doc's ~180 estimate understated it 2x), the code
self-documented two FastMCP private-API breakage traps already hit (the ADR 0009 battleground),
and the bearer pattern was proven twice over in the same fleet (mac-mcp, github-mcp).

## Decision
Replace the OAuth machinery (provider class, consent GET/POST routes, persistent
`oauth_state.json` token store, `AuthSettings` wiring) with the fleet-standard
`BearerAuthMiddleware` (header or `?token=`), reading `OBSIDIAN_MCP_AUTH_TOKEN` resolved via
op-wrap from `op://web-variables/OBSIDIAN_MCP_AUTH_TOKEN/credential`. All 7 tools, `_resolve_note`,
the inbox/brain-agent integration, port 8767, and the decision-0010 socket entrypoint unchanged.

## Consequences
- server.py 505 -> 227 lines (-278). The ADR 0009 failure class (private-attribute route
  mounting) no longer has a surface here.
- All three Mac connectors now share one auth pattern and one rotation procedure (service env +
  portal header, the rotate-secret two-touch), retiring the OAuth-state debugging class.
- Off-Mac clients reach obsidian-mcp only through the portal once the owner adds its slot
  (origin `https://obsidian-mcp.schnapp.bet/mcp`, bearer header, user-auth off); the old
  standalone native-OAuth claude.ai connector can no longer authenticate and is retired. Until
  the slot exists, off-Mac obsidian access is down (Mac-local access unaffected).
- Rollback: `git revert` of the server.py commit + `launchctl kill TERM` restart.

## Verification (2026-07-18, live)
227 lines, zero OAuth references; `com.schnapp.obsidian-mcp` PID live after graceful restart;
`http://127.0.0.1:8767/mcp` no-auth 401, valid bearer MCP initialize 200;
`https://obsidian-mcp.schnapp.bet/mcp` no-auth 401, valid bearer 200; 1Password item created and
byte-verified; writing-style / scan-secrets (0 BLOCK) / freshness / links all green.
