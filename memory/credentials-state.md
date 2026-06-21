---
name: credentials-state
metadata: 
  node_type: memory
  scope: global
  source: "decisions/0001, decisions/0004, handoffs/004, handoffs/016"
  updated: 2026-06-17
  supersedes: ""
  originSessionId: 33c726f1-b86d-4a93-8586-061ec9ca3f3e
---

> 🔴 **CONFIDENTIALITY BREACH 2026-06-17 — supersedes the "healthy" framing below for secret SECRECY (not availability).**
> A plaintext dump of every vault value (incl. the master SA token, all PATs, API keys, DB/`sa`
> passwords) is committed + pushed in `obsidian-vault` Claude Export files and synced to OneDrive →
> all values compromised, **rotation required** (rotate-on-migrate). See [[credential-leak-2026-06-17]].
> The availability/auth notes below remain accurate.

1Password Service Account was deleted, then **rotated** (2026-06-03) and **rotated again
(2026-06-15)** — the SA token lives in `~/.zshrc` + `~/.zshenv` on the Mac and as
`OP_SERVICE_ACCOUNT_TOKEN` on the Render op-mcp host. It worked earlier 2026-06-16 (the brain
pipeline resolved secrets at 05:12) but **broke after that point** — see the outage below. `gh`
uses its own token and is unaffected (GitHub connector still pushes).

**RESOLVED 2026-06-17.** Both fixes applied: (1) `com.schnapp.macmcp` restarted
(`launchctl kill TERM gui/$(id -u)/com.schnapp.macmcp`) → re-read the current `~/.zshrc` token via
`op-wrap.sh`; shell `op whoami` confirms SA valid, sees `web-variables`. (2) Render `op-mcp`
`OP_SERVICE_ACCOUNT_TOKEN` updated to the current SA + redeployed → `op_health` returns
`authenticated` (integration `claude-kit-op-mcp`, 1 vault). Off-Mac path green end-to-end. The
ROTATION GOTCHA below stays in force for every future rotation. Map: [credentials-map](../credentials-map.md).

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
- **ROOT CAUSE (confirmed 2026-06-16):** the SA is fine (`op whoami` works in a fresh shell;
  `~/.zshrc` has the current token). The launchd services start via
  `~/code/schnapp-bet/services/launchd/op-wrap.sh`, which greps `OP_SERVICE_ACCOUNT_TOKEN` out of
  `~/.zshrc` **at process start** then `exec op run`. The running `com.schnapp.macmcp` process
  predates the 06-15 rotation, so it is `op run`-ing with the **old, revoked** token held in-process.
  No rotation, no file edits needed.
- **FIX (no rotation):**
  1. **Mac:** `launchctl kill TERM gui/$(id -u)/com.schnapp.macmcp` — graceful restart (decision
     0010); KeepAlive relaunches via op-wrap.sh, which re-reads the current `~/.zshrc` token. Then
     verify `op_run`/`op_whoami` through the connector. (github-mcp/obsidian-mcp resolve their static
     secrets only at startup and don't re-invoke `op` at runtime, so they're unaffected.)
  2. **Render op-mcp:** update the `OP_SERVICE_ACCOUNT_TOKEN` env var to the current token + redeploy
     (`connectors/op-mcp/DEPLOY.md`) — clears the `op_health` host error / the Mac-off path.
- **ROTATION GOTCHA (capture for decision 0001 runbook):** after ANY SA rotation, the long-running
  launchd MCP services keep the OLD token in-process — they MUST be restarted, AND the Render env var
  updated, or `op_*` keeps failing even though `~/.zshrc` is correct. Re-verify
  `op_whoami`/`op_run`/`op_health` and re-supersede this note once green.

GitHub Actions: PAT widened to all repos 2026-06-03; `OP_SERVICE_ACCOUNT_TOKEN` secret now set
on all previously-tracked repos incl. `af-invoice-parser` + `af-query-api`. Two repos
(`DB_Storage`, `appfolio-marketing-project`) still lack it — never explicitly scoped; awaiting
owner decision before distributing the master token there.

References only — no token values live in any tracked file
([secrets-as-references](../plugins/core/rules/global/secrets-as-references.md)).
