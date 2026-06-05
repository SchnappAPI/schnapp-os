# 0004 — Off-Mac 1Password connector: design + host decision (2026-06-03)

Goal: claude.ai and iPhone resolve 1Password secrets without the Mac, via a hosted remote
MCP connector.

## Verified
- claude.ai accepts **custom remote MCP connectors** (Settings > Connectors > Add custom,
  HTTPS, OAuth). So a self-hosted connector works once deployed.
- Cloudflare supports **remote MCP servers** (Cloudflare Agents, `workers-oauth-provider`).
- BUT `@1password/sdk` (JS) is **Node-only**; not supported on the Workers edge runtime.
  So a plain Worker likely cannot run the 1Password SDK. Do not ship that unverified.

## Reliable host options (pick one)
1. **Cloudflare Container (Node)** — runs the MCP server + @1password/sdk in Node, on
   Cloudflare. Reliable; depends on Containers being available on the account/plan.
2. **Worker + nodejs_compat** — try the SDK under Node-compat. Cheapest, but UNVERIFIED; may
   fail on WASM/Node deps. Only worth it as a quick experiment.
3. **Small Node host** (Fly.io / Render / Railway) — reliable, simplest Node deploy; not
   Cloudflare. Off-Mac, which is what matters.

## Auth
MCP endpoint must be protected (OAuth via workers-oauth-provider, or Cloudflare Access /
bearer). The 1Password Service Account token is stored as a host secret, never in the repo.

## Resolution (2026-06-03) — host fork closed; connector built + verified

Inspected `@1password/sdk-core@0.4.0`: it ships ONLY the wasm-bindgen **Node**
target (`nodejs/core.js` + `core_bg.wasm`; no `web`/`bundler` build). The loader
ends with `fs.readFileSync(__dirname+'/core_bg.wasm')` then synchronous
`new WebAssembly.Module(bytes)` at import time. Cloudflare Workers (even
`nodejs_compat`) has no runtime filesystem and blocks sync WASM compiles from
runtime buffers. **Worker + nodejs_compat is ruled out** (would require hacking
the SDK loader — fragile, unsupported). **Decision: Node host.**

Built `connectors/op-mcp/` — a Node streamable-HTTP MCP server (TypeScript, MCP
SDK + express + `@1password/sdk`). Read-only tools: `op_read`, `op_list_vaults`,
`op_list_items`, `op_health`. `op_run`/`op_inject` deliberately omitted (no remote
command execution). Bearer-token gate; server refuses to start without both
`OP_SERVICE_ACCOUNT_TOKEN` and `CONNECTOR_AUTH_TOKEN`. Portable `Dockerfile`;
`fly.toml` for the recommended Fly.io host (Render/Railway/Cloudflare
Containers/Cloud Run also work from the Dockerfile).

VERIFIED locally against the live SA: `npm run verify` (SDK runs in Node, SA
authenticates, 1 vault visible); full HTTP path green — `tools/list`, `tools/call`
for all four tools, 401 without bearer, clean input-validation + resolve errors,
`op_read` resolve path exercised end-to-end.

### Host + auth-front: RESOLVED 2026-06-03 (owner-chosen)
Priorities: free, simple, cross-surface.

- **Host = Render free tier** (over Fly.io). No CLI, no Docker knowledge: the root
  `render.yaml` Blueprint builds `connectors/op-mcp/Dockerfile` straight from the
  repo; owner sets the two secrets in the dashboard. $0. Caveat: free tier sleeps
  after ~15 min idle (~30–60s cold start) — fine for an occasional resolver. Fly.io
  kept as a drop-in alternative (`fly.toml`) for a no-cold-start host (needs CLI + card).
- **Auth front = Cloudflare MCP server portal** (Cloudflare One). Verified the portal
  fronts an *external* HTTPS MCP origin (not Workers-only) and provides the OAuth flow
  claude.ai requires — no OAuth code to write/maintain. Free Zero Trust tier; owner
  already runs Cloudflare. Chosen over hand-writing an OAuth 2.1+PKCE wrapper (option 2
  — more code to maintain, against "simple").
- **Verified constraint:** claude.ai custom connectors accept **only OAuth 2.1 + PKCE**;
  the web UI has no static-bearer/custom-header field (anthropics/claude-ai-mcp#112). So
  the bearer connector serves Claude Code + Cowork directly; claude.ai web + iPhone need
  the portal.
- **Origin auth: CORRECTION (2026-06-05).** Earlier note ("portal forwards a static bearer,
  no code change") was WRONG — not in Cloudflare's authoritative docs. Verified: the portal's
  upstream auth is **unauthenticated** or **OAuth**; the recommended self-hosted path fronts the
  origin with a **Cloudflare Access app** and the connector validates `Cf-Access-Jwt-Assertion`
  (a `src/auth.ts` change). So NOT no-code. Plus Zero Trust onboarding is a hard gate (plan +
  payment even for Free), which blocked the owner's company account. See DEPLOY.md Step 4.
- **Deploy status (2026-06-05):** connector LIVE on Render free tier at
  `https://op-mcp.onrender.com` (Blueprint deploy; `/health` returns ok). Render free spins
  down after ~15 min idle (~50s cold start) — optional free fix: an UptimeRobot/cron-job.org
  ping to `/health` every ~10 min. Cloudflare portal + claude.ai registration in progress.

Full turnkey steps: `connectors/op-mcp/DEPLOY.md` (canonical).

## Status
**RESOLVED 2026-06-03** — host = **Node host**; Cloudflare Worker **ruled out** (the SDK wasm
loads via `fs.readFileSync` + synchronous `new WebAssembly.Module`, impossible on the Workers
edge). Connector BUILT + locally verified (`npm run verify` PASS). Host + auth-front now
chosen (Render + Cloudflare MCP portal, above). Deploy + claude.ai registration are
**owner-gated** (need owner's Render/Cloudflare/claude.ai logins). Turnkey runbook
prepared: root `render.yaml` Blueprint + `connectors/op-mcp/DEPLOY.md`. Remaining owner steps:
1. Render: New → Blueprint → set the two secrets (DEPLOY.md Step 1).
2. Cloudflare MCP portal in front of the Render origin; register the portal URL in
   claude.ai (DEPLOY.md Steps 4–5).
3. Verify PLAN check 7: resolve a secret from claude.ai with the Mac OFF (closes 4.2 + 4.4).
Until deployed, claude.ai/iPhone secret access still routes through the Mac connector.
