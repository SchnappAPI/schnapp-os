# Deploy + register the off-Mac 1Password connector (Part 4.2)

Canonical runbook. The server is built and locally verified; these are the
owner-gated steps (they need your Render + Cloudflare + claude.ai accounts).
Chosen path: **Render** (free host) + **Cloudflare MCP portal** (OAuth front).
Rationale + alternatives: `decisions/0004-off-mac-1password-connector.md`.

Result when done: every surface resolves `op://` references with the Mac off.
- **Claude Code + Cowork** work with just the bearer token (Step 3) — no portal.
- **claude.ai web + iPhone** need the Cloudflare OAuth front (Steps 4–5), because
  claude.ai's custom-connector UI only accepts OAuth 2.1, not a static bearer.

---

## Step 1 — Deploy to Render (free, no CLI)

The repo root has `render.yaml` (a Blueprint). It builds `connectors/op-mcp/Dockerfile`.

1. Render dashboard → **New** → **Blueprint** → connect the `SchnappAPI/claude-kit` repo.
2. Render reads `render.yaml` and proposes one service, `op-mcp` (free, Docker).
3. It prompts for the two secrets (they are `sync: false`, never in the repo):
   - `OP_SERVICE_ACCOUNT_TOKEN` — the 1Password Service Account token
     (`op://<vault>/claude-kit-op-mcp/service-account-token`).
   - `CONNECTOR_AUTH_TOKEN` — a fresh random bearer: `openssl rand -hex 32`.
     **Save this value into 1Password** after — you need it in Step 3.
4. Apply. Render builds the image and gives a URL like `https://op-mcp.onrender.com`.

Free-tier caveat: the service sleeps after ~15 min idle; the first call then
cold-starts in ~30–60s. Fine for an occasional secret resolver.

## Step 2 — Verify the deploy

```bash
curl https://op-mcp.onrender.com/health
# -> {"status":"ok","server":"op-mcp-server","version":"1.0.0"}

# Bearer-gated MCP endpoint (replace TOKEN with CONNECTOR_AUTH_TOKEN):
curl -s https://op-mcp.onrender.com/mcp \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer TOKEN' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | head
# -> lists op_read / op_list_vaults / op_list_items / op_health
# Without the bearer header -> 401.
```

## Step 3 — Wire Claude Code + Cowork (works immediately, no portal)

Add as an HTTP MCP server with a bearer header. Store the token as an `op://`
reference, never a literal (see `credentials-map.md`). Example Claude Code config:

```json
{
  "mcpServers": {
    "op-mcp": {
      "type": "http",
      "url": "https://op-mcp.onrender.com/mcp",
      "headers": { "Authorization": "Bearer ${CONNECTOR_AUTH_TOKEN}" }
    }
  }
}
```

That already satisfies off-Mac secret access for Code and Cowork.

## Step 4 — Cloudflare MCP portal (OAuth front for claude.ai web + iPhone)

claude.ai only accepts OAuth, so put a Cloudflare One **MCP server portal** in
front of the Render origin. The portal handles the OAuth handshake claude.ai
expects — no OAuth code to write. (Free Zero Trust tier; you already run Cloudflare.)

Verified: the MCP portal natively forwards a STATIC bearer to the upstream — add
the server with `Auth type: bearer` and the token; no connector code change.

2a. Add the MCP server (upstream):
   1. Cloudflare dashboard → **Zero Trust** → **Access controls** → **AI controls**
      (first time: pick a team name + the **Free** plan).
   2. **MCP servers** tab → **Add an MCP server**.
   3. Name `op-mcp`; URL `https://op-mcp.onrender.com/mcp`.
   4. **Auth type: bearer** → paste the `CONNECTOR_AUTH_TOKEN` value (exact match to
      Render, or the origin returns 401). Add an Access policy → your email.
      **Save and connect server.**
   - If the dashboard lacks a bearer field (API-only in some versions):
     ```
     curl "https://api.cloudflare.com/client/v4/accounts/{account_id}/access/ai-controls/mcp/servers" \
       --request POST --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
       --json '{"name":"op-mcp","hostname":"https://op-mcp.onrender.com/mcp","auth_type":"bearer","auth_credentials":"<CONNECTOR_AUTH_TOKEN>"}'
     ```
2b. Create the portal:
   1. **AI controls** main → **Add MCP server portal**.
   2. Name it; **Custom domain** = a zone you own + subdomain, e.g. `mcp.schnapp.bet`.
   3. Add the `op-mcp` server; Access policy → your email. **Add MCP server portal.**
   The end-client (claude.ai) URL becomes `https://<subdomain>.<domain>/mcp`. Users
   authenticate to Cloudflare Access; the portal forwards the bearer to Render.

## Step 5 — Register in claude.ai (and iPhone)

1. claude.ai → **Settings → Connectors → Add custom connector**.
2. Paste the **portal URL** from Step 4 (`https://mcp.<yourdomain>`), not the raw
   Render URL.
3. It launches the OAuth login (Cloudflare Access) → approve once.
4. The iPhone app uses the same connector automatically — nothing extra to do.

## Step 6 — Verify the goal (PLAN.md check 7)

**Power the Mac off.** From claude.ai, call `op_read` on a known reference and
confirm the secret resolves. That closes Part 4 (flip 4.2 → done and 4.4 → done,
add PROGRESS lines, push).

---

## Notes

- Secrets live only in Render's env + Cloudflare, never in the repo or image.
- The connector is read-only (`op_read`, `op_list_vaults`, `op_list_items`,
  `op_health`); no command execution, by design.
- Fly.io remains a drop-in alternative (`fly.toml` is still here) if you ever want
  a no-cold-start host; it needs `flyctl` + a card. Render was chosen for $0 + no CLI.
