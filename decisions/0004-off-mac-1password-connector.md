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

## Status
DECISION PENDING: host choice. Deploy needs the owner's Cloudflare (or chosen host) account.
Until built, claude.ai/iPhone secret access routes through the Mac connector.
