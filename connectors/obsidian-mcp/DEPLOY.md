> **SUPERSEDED (2026-06-16) — do not run these steps.** This Render deploy was never executed;
> the off-Mac Obsidian MCP is now the Mac-hosted server at `https://obsidian-mcp.schnapp.bet/mcp`
> (see this connector's `README.md` banner and `schnapp-bet` → `docs/CONNECTIONS.md`). The runbook
> is retained only in case Mac-independent serving is restored later.

# Deploy runbook — obsidian-mcp

Same shape as `connectors/op-mcp/DEPLOY.md`: Render free Blueprint for the origin, Cloudflare MCP
portal as the claude.ai/iPhone OAuth front, bearer for Code/Cowork. Build + local verify are DONE
(see README "Local dev / verify"); the steps below are the owner-gated deploy.

## 0. Prereqs

- A fine-grained GitHub PAT with **Contents: read on `SchnappAPI/obsidian-vault` only** → store as
  `op://web-variables/obsidian-mcp/vault_read_token`.
- A bearer token: `openssl rand -hex 32` → store as `op://web-variables/obsidian-mcp/connector_auth_token`.

## 1. Render (origin)

1. Render → New → **Blueprint**, point at this repo. It picks up `connectors/obsidian-mcp/render.yaml`.
   (With `rootDir` set, `dockerfilePath`/`dockerContext` are rootDir-relative — already correct here.)
2. After the first build, set the two `sync:false` env vars in the dashboard:
   `CONNECTOR_AUTH_TOKEN` and `GITHUB_TOKEN` (from 1Password above). `VAULT_REPO`/`VAULT_BRANCH` are
   baked into the blueprint.
3. Verify: `GET https://<host>/health` → `{"status":"ok",...}`. Then a bearer `POST /mcp` `initialize`
   should return the server info (the local boot test already confirmed this path).

## 2. Code / Cowork (immediate, no portal)

Add the bearer config from README "Use from Code / Cowork". Works as soon as Render is up.

## 3. Cloudflare MCP portal (claude.ai + iPhone)

Same as op-mcp: add an MCP server in the Cloudflare portal pointing at `https://<host>/mcp`, Managed
OAuth to the user, **static bearer** forwarded upstream via the portal's "Custom headers"
(`Authorization: Bearer <CONNECTOR_AUTH_TOKEN>`). The MCP server needs its own Allow policy or you
get "No allowed servers available". Then register the portal URL as a claude.ai custom connector.
(All the Cloudflare Zero-Trust onboarding gotchas are documented once in `connectors/op-mcp/DEPLOY.md`.)

## 4. Verify (PLAN-style)

- `vault_health` from claude.ai (Mac off) → `vaultPresent:true`, a real `noteCount`.
- `vault_search "PLAN"` → returns `claude-archive/repo/PLAN.md` (proves the mirror + search end-to-end).

## Notes

- **Freshness**: the vault is only as current as `obsidian-vault`'s GitHub state. obsidian-git pushes
  the local vault (incl. the `claude-archive/` mirror) on each Obsidian session; this connector pulls
  it. So: run `backup-archive.sh` → obsidian-git pushes → connector serves the update.
- **Free cold start** ~50s; optional UptimeRobot/cron ping to `/health` to keep warm (as with op-mcp).
- **Rotate** `GITHUB_TOKEN` if it ever transits a transcript; it is read-only + repo-scoped to limit blast radius.
