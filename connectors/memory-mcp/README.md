---
last-verified: 2026-07-13
sources:
  - connectors/memory-mcp/src
---

# memory-mcp

Remote MCP server that fronts the git-tracked **memory lane** (`memory/` in the vault repo
`SchnappAPI/schnapp-vault`, decisions/0023) via the
GitHub Contents API. It is the cross-surface half of the freshness loop: the Code-on-Mac
SessionStart gate reconciles memory through git + hooks, but **hookless surfaces** (claude.ai web,
iPhone, Cowork) have no such path. This server gives them one - every read and write goes straight
to **GitHub origin, the single source of truth** (decisions/0011 #5/#6). No local clone, no Mac
dependency: the Mac can be asleep and the memory is still live everywhere.

## Tools

| Tool | Does | Writes? |
|---|---|---|
| `memory_health` | Wake + verify the GitHub chain (no secrets). | no |
| `memory_index` | Read `MEMORY.md` (the index - read this first). | no |
| `memory_list` | List fact slugs (excludes MEMORY.md / README.md). | no |
| `memory_read` | Read one fact `memory/<slug>.md`. | no |
| `memory_search` | Case-insensitive substring scan across facts. | no |
| `memory_write` | Create/replace a fact + update the index. Enforces the vault memory discipline (`agents.md`). | commits ×2 |
| `memory_delete` | Remove a fact + de-index it (git keeps history). | commits ×2 |

`memory_write` enforces the lane's rules: **one fact per file**, **supersede not append** (writing an
existing slug replaces its body), and the `source` / `updated` frontmatter the freshness gate keys
off. The lane it serves is the vault (`SchnappAPI/schnapp-vault`); the canonical frontmatter schema is
the vault's `agents.md`, and the schnapp-os-side procedures are [`docs/memory-lane.md`](../../docs/memory-lane.md).

## Security model

- **The endpoint can write to the repo**, so `/mcp` is bearer-gated (`MEMORY_MCP_BEARER`); the server
  refuses to start without it. `/health` is open and touches nothing.
- **Secrets are host env vars, never baked into the image** and never in tracked files - only
  `op://` references appear here (`.env.template`). The GitHub token wants least privilege: a
  fine-grained PAT scoped to *only the vault repo's (`SchnappAPI/schnapp-vault`) contents*, the
  lane it writes. See [DEPLOY.md](./DEPLOY.md).
- Stateless Streamable HTTP (new transport per request), same shape as the `op-mcp` connector.

## Run locally

```bash
npm install && npm run build
GITHUB_TOKEN=… MEMORY_MCP_BEARER=… node dist/index.js   # POST /mcp, GET /health on :3000
```

Deploy + connector registration: [DEPLOY.md](./DEPLOY.md).
