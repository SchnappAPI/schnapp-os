---
name: credentials-state
metadata: 
  node_type: memory
  scope: global
  source: "decisions/0001, decisions/0004; SA rotation 2026-06-22; Phase 3B bearer rotations 2026-06-23"
  updated: 2026-06-23
  supersedes: "2026-06-17 outage-resolved note; pre-3B 'Mac MCP client bearer PENDING' framing"
  originSessionId: 33c726f1-b86d-4a93-8586-061ec9ca3f3e
---

> 🔴 **Leak still in force for SECRECY:** every PRE-2026-06-22 vault value was dumped in
> `obsidian-vault` Claude-export files + synced to OneDrive → compromised. **Rotated so far:** the
> **SA token** (2026-06-22, below) and **all 3 MCP bearers** (`MAC_MCP_AUTH_TOKEN`,
> `GITHUB_MCP_AUTH_TOKEN`, `OP_MCP_BEARER` — 2026-06-23, Phase 3B). **Still compromised → owner-console
> rotation outstanding:** `GITHUB_PAT`, Anthropic API key, Claude OAuth, DB `sa`, Web App secrets
> (incl. `RUNNER_API_KEY`), Webshare, Cloudflare. See [[credential-leak-2026-06-17]].

**SA TOKEN ROTATED 2026-06-22 (Phase 1 done).** Old SA `VU2RKR2IDZB6TCAKQRK7J2W5EE` is **deleted**
(any old token now returns `403 Forbidden — Service Account Deleted`). New SA integration
`55TZDNGRIFGMBPALL6ZEWLH7Q4`, vault `web-variables`, token len 852 / last4 `bSJ9`. Note: owner
rotated the SA token **in place** (replaced the value in the existing 1Password item), not an additive
"mint alongside". The prior token now returns `403 Service Account Deleted` and `op whoami`'s
integration id changed (`VU2RK…`→`55TZ…`). So there was **no zero-downtime window**: every surface on
the old token broke the moment the rotation took effect, until propagated. The rotation *is* the
revoke — there is no separate revoke step.

Propagated to: `~/.zshrc`, `~/.zshenv` (**UNQUOTED** — see op-wrap gotcha), the launchd session env
(via the `com.schnapp.environment` run-once agent, which `. ~/.zshenv && launchctl setenv …`),
**11 GH repo secrets** (obsidian-vault, schnapp-bet, schnapp-os, appfolio-quickbase-sync, schnapp-kit,
claude-skills, sports-modeling, appfolio-mcp, ref-vault, af-invoice-parser, af-query-api), and the
**Render `op-mcp`** env + redeploy (owner). All 6 launchd services restarted and **healthy** on the
new token: macmcp / githubmcp / obsidian-mcp / brain-watcher + bet.schnapp web-prod (HTTP 200) / flask.
Verified: shell `op whoami` = 55TZ; Render `op_health` = authenticated. The plist
`com.schnapp.environment` holds **no** token (it sources `~/.zshenv`), so rotation needs no plist edit.

**🔑 op-wrap UNQUOTED gotcha (new 2026-06-22):** `~/code/schnapp-bet/services/launchd/op-wrap.sh`
(every launchd service boots through it) does **not** source `~/.zshrc` — it `grep`s the
`export OP_SERVICE_ACCOUNT_TOKEN=` line and strips the prefix **literally**
(`${LINE#export OP_SERVICE_ACCOUNT_TOKEN=}`). So the token in `~/.zshrc` MUST be **unquoted**.
Writing it quoted (`='ops_…'`) makes op-wrap export the value WITH the quote chars → every service
fails op-client init with `failed to DeserializeServiceAccountAuthToken, unrecognized auth type` and
crash-loops (exit 1). Sourcing readers (zsh, the env agent) strip the quotes fine, so the shell +
session env look healthy while services die — misleading. Keep the token unquoted in both files.
[[op-wrap-token-unquoted]]

**ROTATION GOTCHA (still in force):** after ANY SA rotation the long-running launchd services cache
the old token in-process → restart them (`launchctl kickstart -k gui/$(id -u)/<label>`), re-run
`com.schnapp.environment` to refresh the launchd session env, AND update Render `op-mcp` env +
redeploy. Else `op_*` keeps failing though `~/.zshrc` is correct.

**MCP bearers ROTATED 2026-06-23 (Phase 3B).** All three leaked bearers minted fresh
(`openssl rand -hex 32`, non-echoing) and verified on the Mac side:
- `MAC_MCP_AUTH_TOKEN` → restarted `com.schnapp.macmcp`; `:8765` new bearer 200 / bogus 401. (The old
  `…6267` value — the one this/earlier sessions' Mac MCP tools presented as `unauthorized` — is now dead.)
- `GITHUB_MCP_AUTH_TOKEN` → restarted `com.schnapp.githubmcp`; `:8766` new bearer 200 / bogus 401.
- `OP_MCP_BEARER` → owner propagated Render env (+redeploy) + Cloudflare portal Custom header; `op_health`
  authenticated; origin `/mcp` new bearer 200 / bogus 401. (Clients reach the portal over **OAuth** — no
  static client bearer to rotate on Mac/claude.ai/iPhone.)

**Owner CLIENT legs still pending (don't break anything; just refresh the client to the new value):**
- claude.ai connector `mac-mcp.schnapp.bet` Authorization Bearer = `op://web-variables/MAC_MCP_AUTH_TOKEN/credential`.
- Copilot / github-mcp client bearer = `op://web-variables/GITHUB_MCP_AUTH_TOKEN/credential`.

**Found mid-3B (Mac infra, not the SA):** (a) deployed `~/{mac,github,obsidian}-mcp/server.py` symlinked
the **dead** `~/code/claude-kit/*` path (Phase 2 rename residual) — repointed to `~/code/schnapp-os/*`
before any restart (else all three crash-loop). (b) `com.schnapp.macmcp.plist` had been clobbered to a
bare JSON array (no `Label`/`WorkingDirectory`) → reboot would run macmcp **unauthed/exposed** — rewrote
as a proper secrets-free op-wrap `<dict>` (not reloaded; running job healthy). (c) plaintext-secrets
backup `…macmcp.plist.bak.20260524` holds the dead MAC bearer + live `GH_PAT`/`RUNNER_API_KEY` → owner
`rm` + those two join the console-rotation set. `gh`/GitHub auth is independent of the SA and unaffected.

GitHub Actions: `OP_SERVICE_ACCOUNT_TOKEN` set on all 11 repos 2026-06-22 (not yet exercised by a real
run post-rotation). `DB_Storage` + `appfolio-marketing-project` still lack it (owner decision pending).

References only — no token values in any tracked file
([secrets-as-references](../plugins/core/rules/global/secrets-as-references.md)). Map:
[credentials-map](../credentials-map.md). Links: [[credential-leak-2026-06-17]],
[[owner-working-preferences]], [[mac-connector-tooling]].
