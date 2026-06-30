# 0020 — Front mac-mcp + github-mcp behind the shared Cloudflare MCP portal

**Status:** accepted (2026-06-30)
**Refines:** 0004 (off-Mac op-mcp via the Cloudflare portal), 0013 / 0014 (Mac shell access for cloud agents)

## Context

claude.ai's custom-connector UI is **OAuth-only**. Of the five connectors, four are static-bearer
servers with no OAuth: op-mcp + memory-mcp (Render) and mac-mcp + github-mcp (Mac-hosted). op-mcp +
memory-mcp were already fronted by the `mcp.schnapp.bet` Cloudflare MCP-server portal (Managed OAuth,
bearer forwarded as a Custom header). mac-mcp + github-mcp were not: claude.ai reached them only via
fragile per-client static bearers — mac-mcp via a custom-header connector that **hung on "checking
connection"** (claude.ai found no OAuth handshake to run), github-mcp via a `?token=` URL. Every
bearer rotation silently broke those client legs (left pending after the 2026-06-23 rotation).
obsidian-mcp already speaks native OAuth 2.1 + PKCE + DCR, so it needs no portal.

## Decision

Add mac-mcp + github-mcp to the existing `mcp.schnapp.bet` portal as Custom-header servers
(`Authorization: Bearer <op://web-variables/{MAC,GITHUB}_MCP_AUTH_TOKEN/credential>`, User-auth OFF),
joining op-mcp + memory-mcp. claude.ai / iPhone reach all four through ONE OAuth connector
("Schnapp Portal"). Retire the standalone "Schnapp Mac" / "Schnapp GitHub" connectors. Keep
obsidian-mcp as a separate native-OAuth connector (not portal-fronted — it has its own OAuth and no
static bearer to forward). Claude Code / Cowork keep reaching the origins directly via `.mcp.json`
bearer headers; the portal is the claude.ai / iPhone path only.

## Consequences

- **No static client bearer to maintain.** A bearer rotation now updates only the Mac service env
  (`op-wrap.sh` → `.env.template`) + the portal Custom header — never a per-client connector. Closes
  the recurring "client leg pending" fragility (see `memory/credentials-state.md`, rotate-secret skill).
- **One connector, all hosted tools.** claude.ai sees `op_*` + `memory_*` + mac + github tools under
  "Schnapp Portal"; obsidian stays separate.
- **No env-file change.** The portal reuses the existing bearers as Cloudflare-side Custom headers.
  Nothing in any `.env.template` or `.mcp.json` changes; the bearer values just gain one more
  consumer location (the portal), recorded in `credentials-map.md`.
- **Security:** with User-auth OFF, anyone who clears the portal's Access policy (owner email + PIN)
  gets the full Mac shell — same grant level as the `.mcp.json` access (0014). The Allow policy
  (owner email only) is the gate; keep it tight.

## Verification

`portal_list_servers` → op-mcp, memory-mcp, mac-mcp, github-mcp all enabled; `op_health` +
`memory_health` authenticated through the portal; mac + github origins return 200 with the current
bearer (header and, for github, `?token=`). Exercise mac/github tools in claude.ai after reconnecting
the "Schnapp Portal" connector (its tool list refreshes on reconnect), then delete the two standalones.
