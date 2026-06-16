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
(2026-06-15)** — the SA token lives in `~/.zshrc` + `~/.zshenv` on the Mac and as
`OP_SERVICE_ACCOUNT_TOKEN` on the Render op-mcp host. It worked earlier 2026-06-16 (the brain
pipeline resolved secrets at 05:12) but **broke after that point** — see the outage below. `gh`
uses its own token and is unaffected (GitHub connector still pushes).

**1Password outage as of 2026-06-16 (after ~05:12)** — secret resolution is failing on the SA
token, apparently on BOTH paths:
- **Hosted op-mcp** (`connectors/op-mcp/`, Render `op-mcp.onrender.com`; claude.ai/iPhone via the
  Cloudflare portal `mcp.schnapp.bet/mcp`; Code/Cowork via `op-mcp.onrender.com/mcp` + bearer):
  `op_health` errors `authentication error … Check OP_SERVICE_ACCOUNT_TOKEN on the host`.
  **CONFIRMED down** (this server doesn't use the Mac token).
- **Mac op path** (`op_run`/`op_inject`/`op_whoami`): the owner's **authenticated** surface-checks
  (claude.ai + Cowork, where `mac_info` worked so the Mac-auth layer was valid) returned
  `op_whoami → unauthorized` — pointing to the SA token itself being revoked/expired, not just the
  host. **Not yet confirmed by an actual secret-resolution test.**
- **Testing caveat (do not repeat this mistake):** a session WITHOUT `MAC_MCP_AUTH_TOKEN` (e.g. the
  Code-web container) gets `unauthorized` from `op_whoami`/`op_run`/`shell_exec` at the **Mac-auth
  layer** — `mac_info` still works because it needs no token. That `unauthorized` says nothing about
  the SA. The definitive test is `op_run` resolving a real `op://` ref from an **authed** session
  (one where `mac_info` works).
- **Impact:** likely no reliable secret path right now; Final-verification #7 **FAILS**; any
  secret-bearing action is blocked until the SA is fixed.
- **Fix (owner) — diagnose before rotating.** The SA worked in a chat session recently and at 05:12
  today, so the SA token itself is probably fine; this looks like a **propagation** problem, not a
  dead SA. Most likely: (a) the **Render op-mcp** env `OP_SERVICE_ACCOUNT_TOKEN` still holds the OLD
  pre-2026-06-15 token → update it + redeploy; and/or (b) a **long-running Mac process** holds a
  pre-rotation token — note a **launchd service does NOT source `~/.zshrc`/`~/.zshenv`**, so confirm
  where the Mac op tooling actually reads `OP_SERVICE_ACCOUNT_TOKEN` and reload/restart that service.
  Confirm secret resolution with `op_run` on a real `op://` ref from an **authed** session; only
  rotate (decision 0001) if the token is genuinely revoked. Re-verify `op_whoami`/`op_run`/`op_health`;
  re-supersede once green.

GitHub Actions: PAT widened to all repos 2026-06-03; `OP_SERVICE_ACCOUNT_TOKEN` secret now set
on all previously-tracked repos incl. `af-invoice-parser` + `af-query-api`. Two repos
(`DB_Storage`, `appfolio-marketing-project`) still lack it — never explicitly scoped; awaiting
owner decision before distributing the master token there.

References only — no token values live in any tracked file
([secrets-as-references](../plugins/core/rules/global/secrets-as-references.md)).
