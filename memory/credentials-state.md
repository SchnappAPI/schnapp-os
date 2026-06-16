---
name: credentials-state
metadata: 
  node_type: memory
  scope: global
  source: "decisions/0001, decisions/0004, handoffs/004, handoffs/016"
  updated: 2026-06-16
  supersedes: ""
  originSessionId: 33c726f1-b86d-4a93-8586-061ec9ca3f3e
---

1Password Service Account was deleted, then **rotated** (2026-06-03) and **rotated again
(2026-06-15)** — the token now lives in both `~/.zshrc` and `~/.zshenv`. Verified live
2026-06-16: `op whoami` resolves the SA identity and `gh` is authenticated on the Mac (and
in-session). The SA token resolves `op://` references.

The hosted **op-mcp connector** (`connectors/op-mcp/`, Render `https://op-mcp.onrender.com`,
bearer-gated; claude.ai/iPhone via the Cloudflare portal `https://mcp.schnapp.bet/mcp`, Managed
OAuth; Code/Cowork via `https://op-mcp.onrender.com/mcp` + bearer) was LIVE 2026-06-05 but is
**DOWN as of 2026-06-16**: `op_health` fails with `authentication error … Check
OP_SERVICE_ACCOUNT_TOKEN on the host` from two independent surfaces (a Claude Code session +
Cowork) — a **host-side SA-token / permissions problem**, not a per-surface connector issue.
- **Working route meanwhile:** the Mac `op_run` / `op_inject` (its local op identity is
  unaffected). Resolve every secret through the Mac until the host is fixed.
- **Impact:** Final-verification #7 (creds resolve with the Mac off) currently **FAILS**.
- **Fix (host-side, owner):** check/rotate `OP_SERVICE_ACCOUNT_TOKEN` on the Render op-mcp service,
  confirm the SA still has vault-read perms, then re-verify `op_health`. Runbook:
  `connectors/op-mcp/DEPLOY.md`. Re-supersede this fact once green.

GitHub Actions: PAT widened to all repos 2026-06-03; `OP_SERVICE_ACCOUNT_TOKEN` secret now set
on all previously-tracked repos incl. `af-invoice-parser` + `af-query-api`. Two repos
(`DB_Storage`, `appfolio-marketing-project`) still lack it — never explicitly scoped; awaiting
owner decision before distributing the master token there.

References only — no token values live in any tracked file
([secrets-as-references](../plugins/core/rules/global/secrets-as-references.md)).
