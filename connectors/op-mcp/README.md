# op-mcp — off-Mac 1Password connector

A small remote MCP server that resolves 1Password secrets through a **Service
Account**, so claude.ai, the iPhone app, Cowork, and Claude Code can read
`op://` references **without the Mac being on**. (PLAN.md Part 4.2;
decisions/0004.)

## Why a Node host (not a Worker)

`@1password/sdk` depends on `@1password/sdk-core`, whose only published build is
the wasm-bindgen **Node target**. It loads its WASM with
`fs.readFileSync(__dirname + '/core_bg.wasm')` and a synchronous
`new WebAssembly.Module(bytes)` at import time. Cloudflare Workers (even with
`nodejs_compat`) has no runtime filesystem and blocks synchronous WASM compiles
from runtime buffers, so a plain/`nodejs_compat` Worker cannot run the SDK
without hacking the loader. **Verdict: run on a Node host.** This resolves the
host fork left open in `decisions/0004`.

Portable: the `Dockerfile` builds on Fly.io (recommended, `fly.toml` included),
Render, Railway, Cloudflare Containers, or Cloud Run.

## Tools (all read-only — no command execution, no writes)

| Tool | Purpose | Returns |
|---|---|---|
| `op_read` | Resolve one `op://vault/item/field` reference | `{ reference, value }` |
| `op_list_vaults` | Discover vaults the SA can see | `{ count, vaults[] }` |
| `op_list_items` | List active items in a vault | `{ count, items[] }` |
| `op_health` | Confirm the SA authenticates (no secrets) | `{ authenticated, integration, vaultCount }` |

The Mac connector's `op_run` (execute a command with injected secrets) and
`op_inject` (template fill) are deliberately **omitted** — remote command
execution is not safe to expose. This connector only reads.

## Security

- Endpoint is **bearer-protected** (`Authorization: Bearer <CONNECTOR_AUTH_TOKEN>`).
  The server refuses to start if `CONNECTOR_AUTH_TOKEN` or
  `OP_SERVICE_ACCOUNT_TOKEN` is unset — it never runs open.
- Secrets live only in the host environment (Fly secrets, etc.), never in the
  repo or image. `.env` is gitignored; only `.env.template` is tracked.
- `op_read` returns secret values by design — only reachable past the bearer gate.

## Local run + verify

```bash
cd connectors/op-mcp
npm install
npm run build

# Prove the SDK runs and the SA authenticates (reads no secret values):
OP_SERVICE_ACCOUNT_TOKEN="$(op read op://<vault>/claude-kit-op-mcp/service-account-token)" \
  npm run verify

# Run the HTTP server locally:
OP_SERVICE_ACCOUNT_TOKEN=... CONNECTOR_AUTH_TOKEN="$(openssl rand -hex 32)" npm start
# Smoke test (in another shell), list tools:
curl -s localhost:3000/mcp -H 'content-type: application/json' \
  -H "authorization: Bearer $CONNECTOR_AUTH_TOKEN" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | head
```

## Deploy (owner step — needs your host account)

See `fly.toml` header for the exact Fly.io commands. In short:
1. `fly launch --no-deploy --copy-config`
2. Set `OP_SERVICE_ACCOUNT_TOKEN` and `CONNECTOR_AUTH_TOKEN` as `fly secrets`.
3. `fly deploy`; confirm `GET /health` returns `{"status":"ok"}`.

## Register in claude.ai / Cowork / Code (owner step)

The endpoint is `https://<app>.fly.dev/mcp`.

- **Claude Code / Cowork**: add to mcp config as an HTTP server with an
  `Authorization: Bearer <token>` header.
- **claude.ai (custom connector)**: the Add-custom-connector UI expects OAuth.
  Two options:
  1. Front the server with **Cloudflare Access** (you already run Cloudflare for
     the Mac) or an OAuth proxy, which handles the claude.ai auth handshake; or
  2. Add an OAuth wrapper to this server.
  This is the one remaining design choice for full claude.ai registration; the
  server + bearer auth + deploy are done.

## Verify the goal (PLAN.md check 7)

With the **Mac powered off**, call `op_read` from claude.ai and confirm a secret
resolves. That closes Part 4.
