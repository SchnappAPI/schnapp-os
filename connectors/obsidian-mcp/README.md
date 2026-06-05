# obsidian-mcp — remote vault MCP

A read-only MCP server that serves the owner's Obsidian vault (`SchnappAPI/obsidian-vault`)
to any surface — claude.ai, iPhone, Code, Cowork — **without the Mac or the Obsidian app
running**. It reads the vault from a git copy, so there is no dependency on Obsidian's Local
REST API plugin (which only works while the desktop app is open).

This is the off-Mac counterpart to the on-Mac path: on Code, the `obsidian-mcp` *npm* package
already reads `~/Documents/Obsidian` directly; this connector covers everywhere else.

## Tools (all read-only)

| Tool | Purpose |
|---|---|
| `vault_search` | Search note contents and/or filenames; returns paths + line + snippet. |
| `vault_read` | Read one markdown note by vault-relative path. |
| `vault_list` | List notes, optionally under a subfolder. |
| `vault_health` | Confirm the vault is present; note count, branch, last sync. |

No write tools by design. Paths that escape the vault root are rejected; only `.md` is served.

## How it gets the vault

On boot it clones `VAULT_REPO` (depth 1) into `VAULT_DIR`, or uses an existing checkout / mounted
vault as-is. Search/read/list trigger a rate-limited `git fetch` + reset (at most once per
`SYNC_TTL_MS`) so content stays current without hammering the remote. A failed refresh is
non-fatal — it serves the last-good copy. The vault content (including `claude-archive/`, mirrored
in by `backup-archive.sh`) is therefore searchable from any surface.

## Configuration (host environment)

| Var | Required | Meaning |
|---|---|---|
| `CONNECTOR_AUTH_TOKEN` | yes | Bearer gate for `/mcp`; server refuses to start without it. |
| `VAULT_REPO` | to clone | `owner/repo` of the vault (e.g. `SchnappAPI/obsidian-vault`). |
| `GITHUB_TOKEN` | private repo | Fine-grained PAT, `Contents:read` on the vault repo **only**. |
| `VAULT_BRANCH` | no | Default `main`. |
| `VAULT_DIR` | no | Clone path. Docker default `/app/vault`; locally point at an existing clone to skip cloning. |

Values are `op://` references in `.env.template` — never commit real ones. The `GITHUB_TOKEN` is
woven into the clone URL at runtime and never logged.

## Use from Code / Cowork (bearer, direct)

```json
{
  "mcpServers": {
    "obsidian": {
      "type": "http",
      "url": "https://<your-render-host>/mcp",
      "headers": { "Authorization": "Bearer <CONNECTOR_AUTH_TOKEN>" }
    }
  }
}
```

claude.ai / iPhone register it through the Cloudflare MCP portal (Managed OAuth) — see `DEPLOY.md`.

## Security

- **Read-only**: no tool mutates the vault. Path-traversal rejected; only `.md` served.
- **Bearer-gated**: `/mcp` returns 401 without a valid token; `/health` is the only open route.
- **No secret in the image**: tokens come from the host env at runtime.
- **Cold start**: the free host sleeps when idle; the first call after idle can take ~50s or
  error once — retry before treating as failure (the tool descriptions say this too).

## Local dev / verify

```bash
npm install && npm run build
VAULT_DIR=/Users/you/code/obsidian-vault node scripts/verify-vault.mjs   # logic, no network
VAULT_DIR=/tmp/obs-test CONNECTOR_AUTH_TOKEN=test PORT=3939 node dist/index.js  # boot
```
