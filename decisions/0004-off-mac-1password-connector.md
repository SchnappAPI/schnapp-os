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

### Auth choice for claude.ai (still owner-gated)
claude.ai's "Add custom connector" expects OAuth. Two paths: (1) front the Node
host with **Cloudflare Access** / an OAuth proxy (recommended — owner already runs
Cloudflare), or (2) add an OAuth wrapper to the server. Bearer header works as-is
for Claude Code / Cowork mcp config.

## Status
Connector BUILT + locally verified. Remaining = owner-gated deploy:
1. Pick Node host (default Fly.io) and deploy (`fly deploy`); set the two host secrets.
2. Decide claude.ai auth front (Cloudflare Access vs OAuth wrapper); register the URL.
3. Verify PLAN check 7: resolve a secret from claude.ai with the Mac OFF.
Until deployed, claude.ai/iPhone secret access still routes through the Mac connector.
