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

## Step 4 — Cloudflare MCP portal (OAuth front for claude.ai web + iPhone) — NEEDS REWORK

claude.ai only accepts OAuth, so the plan was a Cloudflare One **MCP server portal**
in front of the Render origin. Two hard realities surfaced (verified against
Cloudflare docs 2026-06-05) that this step still has to solve:

1. **Zero Trust onboarding is a hard gate.** It REQUIRES team name + plan + payment
   details even for the Free plan; the dashboard stays locked until that completes.
   On the owner's `austinschnapp@1st-lake.com` (company) account, activation failed on
   two cards with "unexpected error processing payment" — likely org-locked billing.
   Confirm: is this a work-managed account? Is `schnapp.bet` a zone IN this account?
2. **No static-bearer upstream.** The earlier "Auth type: bearer / auth_credentials"
   claim was WRONG (not in authoritative docs). The portal's supported upstream auth is
   **unauthenticated** or **OAuth**; the recommended self-hosted path fronts the origin
   with a **Cloudflare Access app** and has the connector validate the
   `Cf-Access-Jwt-Assertion` header (a `src/auth.ts` change), then forward
   `Cf-Access-Token` downstream. So this is NOT no-code, and the Render origin must sit
   behind an Access app on a Cloudflare zone hostname.

Until both are solved, this step is parked. Re-entry options:
- **Personal Cloudflare account** (billing not org-locked) → complete ZT onboarding →
  front the origin with an Access self-hosted app → add Access-JWT validation to the
  connector → portal + claude.ai registration.
- **Stytch** (free MCP-OAuth) baked into the connector — no Cloudflare, but a new account
  + OAuth glue in the server.
Refs: cloudflare-one/access-controls/ai-controls/{mcp-portals,linked-apps,secure-mcp-servers}.

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
