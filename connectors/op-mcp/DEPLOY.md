# Deploy + register the off-Mac 1Password connector

Canonical runbook - **DONE + WORKING (2026-06-05)**, kept as the reproducible record / re-deploy
reference. Path: **Render** (free host) + **Cloudflare MCP portal** (OAuth front).
Rationale + alternatives: `decisions/0004-off-mac-1password-connector.md`.

Result (achieved): every surface resolves `op://` references with the Mac off.
- **Claude Code + Cowork** work with just the bearer token (Step 3) - no portal.
- **claude.ai web + iPhone** need the Cloudflare OAuth front (Steps 4–5), because
  claude.ai's custom-connector UI only accepts OAuth 2.1, not a static bearer.

---

## Step 1 - Deploy to Render (free, no CLI)

The repo root has `render.yaml` (a Blueprint). It builds `connectors/op-mcp/Dockerfile`.

1. Render dashboard → **New** → **Blueprint** → connect the `SchnappAPI/schnapp-os` repo.
2. Render reads `render.yaml` and proposes one service, `op-mcp` (free, Docker).
3. It prompts for the two secrets (they are `sync: false`, never in the repo):
   - `OP_SERVICE_ACCOUNT_TOKEN` - the 1Password Service Account token
     (`op://web-variables/OP_SERVICE_ACCOUNT_TOKEN/credential`).
   - `OP_MCP_BEARER` - a fresh random bearer: `openssl rand -hex 32`.
     **Save this value into 1Password** after - you need it in Step 3.
4. Apply. Render builds the image and gives a URL like `https://op-mcp.onrender.com`.

Free-tier caveat: the service sleeps after ~15 min idle; the first call then
cold-starts in ~30–60s. Fine for an occasional secret resolver.

## Step 2 - Verify the deploy

```bash
curl https://op-mcp.onrender.com/health
# -> {"status":"ok","server":"op-mcp-server","version":"1.0.0"}

# Bearer-gated MCP endpoint (replace TOKEN with OP_MCP_BEARER):
curl -s https://op-mcp.onrender.com/mcp \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer TOKEN' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | head
# -> lists op_read / op_list_vaults / op_list_items / op_health
# Without the bearer header -> 401.
```

## Step 3 - Wire Claude Code + Cowork (works immediately, no portal)

Add as an HTTP MCP server with a bearer header. Store the token as an `op://`
reference, never a literal (see `credentials-map.md`). Example Claude Code config:

```json
{
  "mcpServers": {
    "op-mcp": {
      "type": "http",
      "url": "https://op-mcp.onrender.com/mcp",
      "headers": { "Authorization": "Bearer ${OP_MCP_BEARER}" }
    }
  }
}
```

That already satisfies off-Mac secret access for Code and Cowork.

## Step 4 - Cloudflare MCP portal (OAuth front for claude.ai web + iPhone) - DONE, WORKING

claude.ai only accepts OAuth, so a Cloudflare One **MCP server portal** fronts the Render
origin: it does the OAuth handshake claude.ai needs and forwards a **static bearer** to the
connector (the live UI's "Custom headers" auth type - which the docs did not surface). Verified
working 2026-06-05 on the owner's account (`schnapp.bet` is a zone in it). Exact steps that worked:

1. **Activate Zero Trust (hard gate).** Zero Trust → Get started → set a **team name** → choose
   **Free** plan → enter payment details (required even for Free; $0). NOTE: activation may throw
   "An unexpected error occurred while processing your payment" - it was **transient** here
   (succeeded on retry; the audit log showed "Create Zero Trust account - success"). After
   activating, reach the real dashboard at `one.dash.cloudflare.com` (the `dash.cloudflare.com`
   "Zero Trust" nav item is just a splash).
2. **Add the MCP server** (Access controls → AI controls → **MCP servers** → Add an MCP server):
   name `op-mcp`, Server ID `op-mcp`, HTTP URL `https://op-mcp.onrender.com/mcp`,
   **Authentication type = Custom headers** → header `Authorization: Bearer <OP_MCP_BEARER>`
   (exact match to Render). **Attach an Allow policy to the SERVER** (Emails = your login email);
   skipping this causes "No allowed servers available" after login. Save → status goes **Ready**,
   4 tools synced.
3. **Create the portal** (MCP server portals → Add): name `op-mcp-portal`; **Custom domain** =
   subdomain `mcp` on `schnapp.bet` → `mcp.schnapp.bet`; add the `op-mcp` server (leave its **User
   auth required = OFF** so the portal uses the bearer); attach the same Allow policy; **Managed
   OAuth = ON**, and under **Allowed redirect URIs** add `https://claude.ai/api/mcp/auth_callback`
   and `https://claude.com/api/mcp/auth_callback`. Create → portal URL `https://mcp.schnapp.bet/mcp`.

## Step 5 - Register in claude.ai (and iPhone) - DONE

1. claude.ai → **Settings → Connectors → Add custom connector** (needs Pro/Max).
2. URL = the **portal** URL `https://mcp.schnapp.bet/mcp`. Leave **OAuth Client ID/Secret BLANK**
   (Managed OAuth does dynamic client registration; claude.ai self-registers).
3. Add → redirected to **Cloudflare Access** → enter the policy email → one-time PIN to that inbox
   → approve. Connector connects, 4 `op_*` tools appear (plus Cloudflare `portal_*` tools - ignore).
4. iPhone uses the same connector automatically.

## Step 6 - Verify the goal - op_health PASS

From claude.ai, `op_health` returned **authenticated** (Integration `claude-kit-op-mcp`, vault
visible) - the full path resolves with no Mac involvement (connector is on Render). To make 4.4
airtight, run one `op_read` of a real `op://` value from claude.ai and confirm the value returns.

---

## Notes

- Secrets live only in Render's env + Cloudflare, never in the repo or image.
- The connector is read-only (`op_read`, `op_list_vaults`, `op_list_items`,
  `op_health`); no command execution, by design.
- Fly.io remains a drop-in alternative (`fly.toml` is still here) if you ever want
  a no-cold-start host; it needs `flyctl` + a card. Render was chosen for $0 + no CLI.
