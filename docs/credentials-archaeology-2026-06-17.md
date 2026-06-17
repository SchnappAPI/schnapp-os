# Credentials archaeology — how the 1Password / secrets setup was built

Reconstructed 2026-06-17 from Claude Code session transcripts across three repos
(`schnapp-bet`, `schnapp-kit`, `claude-kit`) plus the `/private/tmp` daily memory-log
summaries. Method: pattern-grep every `*.jsonl`, extract only matching messages
(assistant text + tool commands + tool results), redact secret values before reading,
sort chronologically, dedupe. **No secret value appears in this document.**

This is a *history* document: how the setup came to be and why. The live, canonical
"how it resolves now" map is **[credentials-map.md](../credentials-map.md)** — do not
duplicate it; this doc references it. Decision records: `decisions/0001`, `0002`, `0004`.
Current operational state + the active outage runbook: `memory/credentials-state.md`.
Target redesign + naming convention: [docs/superpowers/specs/2026-06-17-credential-system-design.md](superpowers/specs/2026-06-17-credential-system-design.md).

**Evidence reliability.** Two tiers are kept distinct throughout:
- **[T]** = from a transcript. Point-in-time; reflects what was true (or believed) when
  written. Several **[T]** claims have since been superseded — flagged inline.
- **[V]** = verified against a live file or endpoint on 2026-06-17 during this analysis.

---

## 1. Timeline per repo (sessions that touched secrets)

Times UTC. "units" = redacted matching message-fragments extracted from that session
(a rough density signal, not message count). Only secrets-relevant sessions are listed.

### schnapp-bet  (`~/.claude/projects/-Users-schnapp-code-schnapp-bet`)
| Date | Session (8-char) | units | What happened |
|---|---|---|---|
| 2026-05-18 | `447d945d` | 235 | **Genesis.** Ported `sports-modeling` → `schnapp-bet`; established 1Password as the secrets source (ADR-20260517-5); built `.env.template` (op:// URIs), `op-wrap.sh`, launchd plists, 27 GH workflows on `load-secrets-action`. Migrated plaintext-secret plists → vault. Rotated the SA token + `ADMIN_PASSCODE` (token had transited the transcript). |
| 2026-05-24 | `12694fc6` | 40 | mac-mcp `server.py` SQL creds moved from a hardcoded DB name / `~/sql-server.env` to vault-backed env via `op-wrap`; plist wrapped. |
| 2026-05-24 | `69fcfc74`, `3e86ae6f`, `89486cc2`, `135b274d`, `5c8968de`, `66cf6d22` | — | Cutover follow-ups; dev `launch.json` wrapped in `op run`. |
| 2026-05-27 | `d5ee7e37` | 52 | **PAT clarification.** Distinguished `pat_git_credentials` (live) vs `pat_web_plist` (then-"dead"); wired `gh` to the 1Password biometric plugin (`op plugin init gh`, item `GITHUB_PAT`); removed old `~/.config/gh/hosts.yml`; confirmed Claude Code auth via `settings.json` op:// URIs. |
| 2026-05-27 | `c919979f`/`2f2b3760` | 32 | Continuation of the PAT/gh work. |
| 2026-05-27 → 05-29 | `82ec7b42` | 77 | Secrets-architecture **docs** pass; flagged unused `Anthropic/api_key`, dead `pat_web_plist`; mac-mcp bearer (`schnapp_mac`) hardened for `claude.yml`. |
| 2026-06-05 | `d5ee7e37` (cont.) | — | (see kit) |

### schnapp-kit  (`~/.claude/projects/-Users-schnapp-code-schnapp-kit`)
| Date | Session (8-char) | units | What happened |
|---|---|---|---|
| 2026-05-27 | `1d252415` | 53 | Mapped the full vault + Claude Code wiring; drew the first architecture summary (`settings.json` env, `~/.claude.json` mac-mcp stdio wrapper). |
| 2026-05-27 | `fdb1820a` | 53 | **MCP plist de-secreting.** Stripped hardcoded `EnvironmentVariables` from `com.schnapp.macmcp.plist` + `com.schnapp.githubmcp.plist`; added `GitHub/pat_github_mcp` to the vault; extended `op-wrap.sh` with **per-service `.env.template` layering**; created per-service templates. |
| 2026-05-27 | `f5e5380f` | 50 | Doc-update pass (ground-truth consumer map) across bet + kit. |
| 2026-06-01 | `57af349a` | 150 | Cross-surface MCP work; **removed the broken `ANTHROPIC_API_KEY` op:// from `settings.json`**; confirmed `${OP_SERVICE_ACCOUNT_TOKEN}` interpolation in `.mcp.json` for stdio servers. |
| 2026-06-01 | `f4ba5a04` | 41 | Mac MCP hardened to 5 `op_*` JIT tools; public `mac-mcp.schnapp.bet` bearer path proven (PR #20). |
| 2026-06-03 | `47d0d075` | 185 | claude-kit bootstrap; SA "rotated and working everywhere `op` runs". |

### claude-kit  (`~/.claude/projects/-Users-schnapp-code-claude-kit`)
| Date | Session (8-char) | units | What happened |
|---|---|---|---|
| 2026-06-03 | `882e703d` | 225 | **Off-Mac connector born.** Scaffolded `connectors/op-mcp/` (Node streamable-HTTP MCP, read-only, bearer). Worker ruled out (1Password SDK needs Node `fs`+sync WASM). Wrote `.env.template`. |
| 2026-06-03 → 06-05 | `33c726f1` | 219 | **Deploy gauntlet.** Render Blueprint (`render.yaml`); fixed `rootDir` path-doubling bug; Cloudflare MCP portal (`mcp.schnapp.bet`) with Managed OAuth + static-bearer Custom-header upstream; registered in claude.ai as connector "1Password". `op_health`/`op_read` verified end-to-end. |
| 2026-06-05 | `a96082a8`, `fb64c1f0`, `a830ca15`, `055fcd36` | — | Connector cold-start tolerance text; modeled `connectors/obsidian-mcp/` on op-mcp; user rotated the GitHub PAT + updated `GITHUB_PAT` in 1Password. |
| 2026-06-16 | `dcac4f65` | 10 | Plugin-packaging session; confirmed `mcp.schnapp.bet` is the OAuth front (not Mac-hosted; `/health` 404 is expected); flagged `connectors/op-mcp/fly.toml` as unused. (This is the day of the outage in `memory/credentials-state.md`.) |

---

## 2. The vault and the bootstrap secret

**Single source of truth: 1Password vault `web-variables`** (id `o3rjqrgvascutyedbmuzfl4yzu`). **[T][V]**

**Bootstrap secret: `OP_SERVICE_ACCOUNT_TOKEN`** — the 1Password **Service Account**
token (account name `schnapp-automation`). It resolves every other `op://` reference, so
it can never itself be an `op://` lookup. It is set directly in each surface's environment.
The SA-token item in the vault is titled **`Service Account Auth Token: schnapp-automation`**
(category ApiCredentials). **[V]** (`credentials-map.md`)

Where the bootstrap token is set (this is the "where else" axis for the one secret that
isn't an op:// reference):

| Surface | Where the SA token lives |
|---|---|
| Mac login shell | `~/.zshrc` **and** `~/.zshenv` (export line) |
| Mac launchd services | `com.schnapp.environment` LaunchAgent reads it from `~/.zshenv` at login and `launchctl setenv`s it into the global launchd env |
| Mac launchd services (belt-and-suspenders) | `op-wrap.sh` *also* greps it straight out of `~/.zshrc` at process start |
| GitHub Actions | repo secret `OP_SERVICE_ACCOUNT_TOKEN`, set per repo (`gh secret set`) |
| Off-Mac connector | Render env var `OP_SERVICE_ACCOUNT_TOKEN` on the `op-mcp` service, sourced from a **separate** vault item `claude-kit-op-mcp` / field `service-account-token` |

---

## 3. What was created vs edited vs only read

### Created (this lineage)
- **`schnapp-bet/.env.template`** — canonical env-var → op:// URI map (created 2026-05-18, `447d945d`; grew from ~9 to ~20 URIs). **[V]**
- **`schnapp-bet/services/launchd/op-wrap.sh`** — launchd bootstrap wrapper (2026-05-18). Per-service layering added 2026-05-27 (`fdb1820a`). **[V]**
- **`services/launchd/rotate-op-token.sh`** — re-runnable SA-rotation script (moved into repo 2026-05-18). **[T]**
- **Vault field `GitHub/pat_github_mcp`** — added 2026-05-27 (`fdb1820a`) for the github-mcp server's `GH_PAT` (`op item edit "GitHub" … 'pat_github_mcp[password]=…'`). This is the **only** vault *write* in the entire transcript set. **[T]**
- **Per-service `.env.template`s** under `~/mac-mcp/` and the github-mcp dir (2026-05-27). **[T]**
- **`connectors/op-mcp/`** (claude-kit) — the off-Mac Node connector + `Dockerfile` + `.env.template` + `render.yaml` Blueprint + `DEPLOY.md` (2026-06-03→05). **[V]**
- **Vault item `claude-kit-op-mcp`** (fields `service-account-token`, `connector-auth-token`) — created via the 1Password app during the Render deploy (2026-06-05); never via CLI in-transcript. **[T]**
- **GH Actions repo secret `OP_SERVICE_ACCOUNT_TOKEN`** — set per repo (2026-05-18 onward). **[T]**

### Edited
- `~/Library/LaunchAgents/com.schnapp.macmcp.plist` + `com.schnapp.githubmcp.plist` — hardcoded `EnvironmentVariables` stripped, `ProgramArguments` wrapped with `op-wrap.sh` (2026-05-24 + 2026-05-27). **[T]**
- `~/.claude/settings.json` — env block with op:// URIs added, **then the `ANTHROPIC_API_KEY` op:// removed** as broken (2026-06-01). **[V: the whole op:// env block is gone today.]**
- `schnapp-bet/.env.template` — `ANTHROPIC_API_KEY` field pinned, dead-field notes added (2026-05-29); GitHub ref later consolidated to `GITHUB_PAT/token`. **[V]**
- `docs/CONNECTIONS.md` — removed misleading `GITHUB_TOKEN` repo-secret row, added `CLAUDE_CODE_OAUTH_TOKEN` (2026-05-29). **[T]**

### Only read / inspected (never written)
Bulk `op item get` / `op item list` calls in `447d945d` (2026-05-18) and `1d252415` /
`fdb1820a` (2026-05-27) walked the vault by item id and by title to map fields and confirm
which token matched which service. No `op item create` appears anywhere in the transcripts —
**every item except `GitHub/pat_github_mcp` and `claude-kit-op-mcp` pre-existed** the captured
sessions or was made in the 1Password GUI off-transcript.

---

## 4. The bundled-item structure (and why)

Items in `web-variables` hold **multiple fields grouped by the system they belong to**,
rather than one item per secret. Rationale, from the transcripts: a consumer (a service, a
workflow) needs a *set* of related values at once; bundling keeps one item per consumer-system
so a `.env.template` block maps cleanly to one item, and rotation touches one place.

| Item | Fields (transcript-era) | Why bundled |
|---|---|---|
| **Database** | `server`, `database`, `username`, `password`, `trust_cert`, `mssql_sa_password` | One SQL Server connection. Consumed together by every ETL/grading script, Flask, the web app, and mac-mcp's `sql_query`. |
| **Web App** | `hostname`, `node_env`, `port_prod`, `runner_url`, `runner_url_dev`, `runner_api_key`, `sql_connection_string`, `auth_token_secret`, `admin_passcode`, `admin_refresh_code`, `odds_api_key` | One Next.js production app's entire env. |
| **GitHub** | `password`, `pat_git_credentials`, `pat_web_plist`, `pat_github_mcp`, `owner`, `repo` | Multiple GitHub PATs for different consumers (web routes, mac-mcp, github-mcp) under one roof. **See §7 — this item is now superseded by `GITHUB_PAT`.** |
| **MCP Tokens** | `schnapp_mac`, `schnapp_github` | The two MCP-connector **bearer** tokens (auth *to* the servers), distinct from the GitHub PATs the servers use. |
| **Anthropic** | `password` (live), `api_key` (dead) | Anthropic API key. `api_key` was added by an `op plugin init claude` wizard and never wired. |
| **Claude Code** | `oauth_token` | `CLAUDE_CODE_OAUTH_TOKEN`, separate from the Anthropic API key. |
| **Webshare Proxy** | `username`, `password`, `proxy_url` | NBA scraping proxy. |
| **obsidian-mcp** | `connector_auth_token`, `vault_read_token` | The (Render-era) Obsidian connector. |
| **claude-kit-op-mcp** | `service-account-token`, `connector-auth-token` | The off-Mac connector's two host secrets (a *separate* item from the system bundles). |

---

## 5. Why each major choice was made (from the transcripts)

- **1Password as the single source (ADR-20260517-5, 2026-05-18).** The migration found
  plaintext secrets in launchd plists and `~/sql-server.env`. Consolidating to a vault +
  op:// references removed plaintext from disk and gave one rotation point.
- **`op-wrap.sh` instead of plist `EnvironmentVariables`.** launchd does not source
  `~/.zshrc`, so the SA token isn't in a plist's inherited env. The wrapper sources the
  token, then `op run --env-file=.env.template` resolves the rest at command time — so no
  secret (not even resolved values) is written to any plist.
- **Per-service `.env.template` layering (2026-05-27).** `GH_PAT` meant *different* tokens
  for mac-mcp vs github-mcp. Rather than rename globally, `op-wrap.sh` layers a local
  `$(pwd)/.env.template` over the global one (`op run --env-file=global --env-file=local`),
  resolving the name collision without polluting the shared file. Backward-compatible (no-op
  if no local file).
- **`gh` via the 1Password biometric plugin (2026-05-27).** `op plugin init gh` made `gh`
  authenticate through Touch ID / 1Password unlock against the `GITHUB_PAT` item, removing the
  stored `~/.config/gh/hosts.yml` credential.
- **Off-Mac connector on a Node host, not a Cloudflare Worker (2026-06-03, decisions/0004).**
  `@1password/sdk` ships only the Node wasm target and loads it via `fs.readFileSync` + a
  synchronous `new WebAssembly.Module` at import — impossible on the Workers edge. So a Node
  host was required.
- **Render + Cloudflare MCP portal, not a hand-written OAuth wrapper (2026-06-05).** Render's
  free tier builds the Dockerfile from the repo with no CLI. Real MCP OAuth (2.1 + PKCE +
  Dynamic Client Registration) would have meant a new Auth0/Stytch-style dependency; the
  Cloudflare portal reuses the Cloudflare account already in use and fronts the existing
  bearer connector with Managed OAuth — zero OAuth code. claude.ai's connector UI accepts
  **only** OAuth (no static-bearer field), which is exactly why the portal is needed for
  claude.ai/iPhone while Code/Cowork hit the Render bearer directly.
- **Connector is read-only (`op_read`, `op_list_vaults`, `op_list_items`, `op_health`).**
  `op_run`/`op_inject` were deliberately omitted so the public host can't execute commands.

---

## 6. How it works now — resolution chain per consumer

Canonical surface map: **[credentials-map.md](../credentials-map.md)**. Expanded per consumer:

**A. Mac launchd services (Flask, Next.js web-prod, mac-mcp, github-mcp)**
```
login → com.schnapp.environment reads OP_SERVICE_ACCOUNT_TOKEN from ~/.zshenv
       → launchctl setenv (global launchd env)
service start → op-wrap.sh greps the token from ~/.zshrc (independent of the above)
              → exec op run --env-file=<repo>/.env.template [--env-file=$(pwd)/.env.template] -- <cmd>
              → op resolves each op://web-variables/<item>/<field> at command time
```
Key consequence (see §8): `op run` resolves the token **held at process start**. A
long-running service keeps its token in-process and does not re-read after a rotation.

**B. Claude Code (Mac)** **[V, changed from transcript-era]**
- Transcript-era **[T]**: `~/.claude/settings.json` `env` block held
  `GITHUB_TOKEN`/`ANTHROPIC_API_KEY` as op:// URIs "resolved natively."
- Current **[V]**: `settings.json` `env` is `{ "ECC_GATEGUARD": "off" }` only — **no op://
  refs remain.** The native-op:// path was found broken and stripped (2026-06-01). Claude
  Code auth today does not flow through that block. `.mcp.json` still interpolates
  `${OP_SERVICE_ACCOUNT_TOKEN}` (from the launchd/host env) for stdio MCP children.
- Mac `op_*` MCP tools (`op_read`, `op_run`, `op_inject`, `op_whoami`, `op_list_items`) are the
  in-session resolution path, gated by the `MAC_MCP_AUTH_TOKEN` bearer (`MCP Tokens/schnapp_mac`).

**C. GitHub Actions**
```
repo secret OP_SERVICE_ACCOUNT_TOKEN → 1password/load-secrets-action@v2
  → op:// URIs declared per workflow → step env
```
The "Load secrets from 1Password" step is the canary used to validate every rotation.

**D. `gh` CLI (terminal)** — `~/.zshrc` sources `~/.config/op/plugins.sh`;
`gh` is aliased to `op plugin run -- gh`; biometric unlock via the 1Password desktop app,
backed by the `GITHUB_PAT` item.

**E. Off-Mac (claude.ai web + iPhone)** **[V endpoint live 2026-06-17]**
```
claude.ai → OAuth (Cloudflare Access / Managed OAuth, dynamic client registration)
          → Cloudflare MCP portal  https://mcp.schnapp.bet/mcp
          → portal forwards static bearer (Custom header) = CONNECTOR_AUTH_TOKEN
          → Render connector  https://op-mcp.onrender.com/mcp
          → @1password/sdk in Node, authed by the Render OP_SERVICE_ACCOUNT_TOKEN
          → op_read / op_list_* against web-variables (1 vault visible)
```
Code/Cowork can skip the portal and hit `https://op-mcp.onrender.com/mcp` with the bearer
directly. Integration name in 1Password/claude.ai: `claude-kit-op-mcp`.

---

## 7. Consumer map — op:// reference → consumer → where else set

All refs are `op://web-variables/…` unless noted. "Env var" is the name the consumer sees
after resolution.

| op:// reference | Env var | Primary consumer | Also set / notes |
|---|---|---|---|
| `Database/server`,`/database`,`/username`,`/password`,`/trust_cert` | `SQL_SERVER` etc. | ETL, grading, Flask, web, mac-mcp `sql_query` | `schnapp-bet/.env.template` |
| `Database/mssql_sa_password` | `MSSQL_SA_PASSWORD` | SQL Server (Docker/Colima) bootstrap | — |
| `Webshare Proxy/proxy_url` | `NBA_PROXY_URL` | NBA ETL | (item also has username/password) |
| `Web App/odds_api_key` | `ODDS_API_KEY` | odds ETL | — |
| `Web App/runner_api_key`,`/runner_url`,`/runner_url_dev` | `RUNNER_API_KEY`,`RUNNER_URL`(`_DEV`) | web ↔ Flask runner dispatch | `runner_api_key` was once hardcoded in `com.schnapp.macmcp.plist` |
| `Web App/sql_connection_string`,`/auth_token_secret`,`/admin_passcode`,`/admin_refresh_code` | resp. | Next.js web app | — |
| `GITHUB_PAT/token` **(current)** | `GITHUB_PAT` | Next.js API routes dispatching GH Actions; also the `gh` biometric plugin item | `schnapp-bet/.env.template` line 63; comment claims it's also the `settings.json` `GITHUB_TOKEN` — **but that block is gone (§8)** |
| `GitHub/pat_git_credentials` **(transcript-era)** | `GITHUB_PAT` | (same web-route role, pre-consolidation) | **Superseded by `GITHUB_PAT/token` — see §8** |
| `GitHub/pat_web_plist` | `GH_PAT` | mac-mcp server (kit session wired it) | **Contradiction: bet session called it dead — §8** |
| `GitHub/pat_github_mcp` | `GH_PAT` | github-mcp server | created 2026-05-27 |
| `Anthropic/password` | `ANTHROPIC_API_KEY` | Claude Code (historically `settings.json`) | sibling `api_key` field is dead |
| `Claude Code/oauth_token` | `CLAUDE_CODE_OAUTH_TOKEN` | Claude Code OAuth | distinct from Anthropic API key |
| `MCP Tokens/schnapp_mac` | `MAC_MCP_AUTH_TOKEN` | mac-mcp **bearer gate** (`mac-mcp.schnapp.bet`) | most-referenced secret in the corpus |
| `MCP Tokens/schnapp_github` | `GITHUB_MCP_AUTH_TOKEN` / `GITHUB_COPILOT_TOKEN` | github-mcp / Copilot MCP bearer, via `~/.claude.json` `github-schnappapi` stdio wrapper | — |
| `obsidian-mcp/connector_auth_token`,`/vault_read_token` | resp. | Obsidian connector (Render-era) | superseded by a Mac-hosted obsidian-mcp (memory: `obsidian-state`) |
| `claude-kit-op-mcp/service-account-token` | `OP_SERVICE_ACCOUNT_TOKEN` | op-mcp Render host | **not** op://-resolvable — it IS the key; set in Render dashboard |
| `claude-kit-op-mcp/connector-auth-token` | `CONNECTOR_AUTH_TOKEN` | op-mcp bearer gate + Cloudflare portal Custom header | doc `.env.template` calls the field `connector-bearer` — **name drift, §8** |

---

## 8. Inconsistencies, dead weight, and drift (called out explicitly)

1. **`GitHub` item vs `GITHUB_PAT` item — the biggest reconciliation gap.** The May-2026
   transcripts wire GitHub secrets through a bundled **`GitHub`** item
   (`pat_git_credentials`, `pat_web_plist`, `pat_github_mcp`, `password`, `owner`, `repo`).
   The current canonical files reference a **single `GITHUB_PAT` item, field `token`**
   (`schnapp-bet/.env.template:63` = `op://web-variables/GITHUB_PAT/token`; `credentials-map.md`
   lists `GITHUB_PAT`, not `GitHub`). `credentials-map.md` even warns
   `op://web-variables/GITHUB_PAT/credential` does **not** resolve (field label differs).
   **Open question:** does the old `GitHub` bundle item still exist (now dead weight), or was
   it renamed/folded into `GITHUB_PAT`? Resolve with `op_list_items` + `op_read` before
   trusting any `op://web-variables/GitHub/…` reference. **The four `pat_*` fields are the
   prime dead-weight suspects.**

2. **`pat_web_plist` — "dead" vs "wired" contradiction (same day, two repos).** On
   2026-05-27 the bet session (`82ec7b42`) declared `pat_web_plist` "unused dead weight — can
   be deleted," while the kit session (`fdb1820a`) **wired it as mac-mcp's `GH_PAT`**
   (`mac-mcp/.env.template` → `op://web-variables/GitHub/pat_web_plist`). The two sessions
   reasoned from different repos and reached opposite conclusions. Its real status is unknown
   today and depends on item #1.

3. **`settings.json` op:// env block is gone.** Transcripts (2026-05-27) present
   `GITHUB_TOKEN`/`ANTHROPIC_API_KEY` op:// URIs in `settings.json` as a working native-resolve
   path. The `ANTHROPIC_API_KEY` one was removed as **broken** on 2026-06-01, and the current
   file **[V]** has no op:// env at all. Any doc/comment still pointing Claude Code auth at
   `settings.json` op:// (e.g. the comment block in `schnapp-bet/.env.template:16-22`) is stale.

4. **`Anthropic/api_key` dead field.** Added by an `op plugin init claude` wizard; nothing
   references it (`settings.json` used `password`). Deletable.

5. **Connector field-name drift.** The Render deploy created the bearer as
   `claude-kit-op-mcp/connector-auth-token` **[T]**, but `connectors/op-mcp/.env.template`
   documents it as `…/connector-bearer` **[V]**. Same secret, two names — pick one.

6. **`connectors/op-mcp/fly.toml` is unused.** Render won; Fly.io was kept "as a drop-in
   alternative" but is not deployed. Flagged as a cleanup candidate in `dcac4f65` (2026-06-16);
   still present on disk **[V]**. Minor.

7. **Duplicate SA token storage complicates rotation.** The SA value exists in `~/.zshrc`,
   `~/.zshenv`, every GH Actions repo secret, **and** the `claude-kit-op-mcp/service-account-token`
   item feeding Render. A rotation must touch all of them. This is the mechanism behind the
   2026-06-16 outage (#8 below).

8. **GH Actions secret not on every repo.** `OP_SERVICE_ACCOUNT_TOKEN` is set per-repo
   (decisions/0002 chose the user-account + per-repo-script path). `DB_Storage` and
   `appfolio-marketing-project` were never scoped — left unset pending an owner decision about
   spreading the master token. (Not a bug; a deliberate hold.)

---

## 9. Current-state reconciliation (op-mcp connector, host, portal, SA token)

Verified during this analysis (2026-06-17):

- **Render connector — UP.** `GET https://op-mcp.onrender.com/health` → `200`
  `{"status":"ok","server":"op-mcp-server","version":"1.0.0"}`, ~0.17s (warm). An initial probe
  returned `000` (transient/DNS); the retry was clean. **Caveat:** `/health` proves the process
  is alive; it does **not** prove the in-Render `OP_SERVICE_ACCOUNT_TOKEN` still authenticates to
  1Password. That requires `op_health`/`op_read` *through* the chain (not exercised here).
- **Cloudflare portal — front responding.** `GET https://mcp.schnapp.bet/health` → `404`. This
  is the **expected** behavior: `mcp.schnapp.bet` is the OAuth front, not Mac-hosted and not in
  the cloudflared config; only `/mcp` is served. (Confirmed by `decisions/0004` and `dcac4f65`.)
- **Host / topology:** connector = Node (TypeScript, MCP SDK + express + `@1password/sdk`) on
  **Render free tier** (sleeps ~15 min idle, ~30–60s cold start; optional UptimeRobot/cron ping
  to keep warm). Fronted by a **Cloudflare MCP portal** (Cloudflare One, Managed OAuth +
  static-bearer Custom header). Registered in claude.ai as connector **"1Password"**, Integration
  `claude-kit-op-mcp`, **1 vault visible** (`web-variables`).
- **The SA token it uses:** Render env `OP_SERVICE_ACCOUNT_TOKEN`, sourced from
  `claude-kit-op-mcp/service-account-token`. The same `schnapp-automation` SA was **rotated
  2026-06-03 and again 2026-06-15** (`memory/credentials-state.md`).
- **The 2026-06-16 outage and its root cause** (from `memory/credentials-state.md`, the current
  authority): the SA itself was fine; resolution broke on **stale in-process tokens** after the
  06-15 rotation. (a) The long-running `com.schnapp.macmcp` process predated the rotation and was
  `op run`-ing with the old token (fix: `launchctl kill TERM gui/$(id -u)/com.schnapp.macmcp` —
  KeepAlive relaunches via `op-wrap.sh`, re-reading the current `~/.zshrc` token). (b) The Render
  env still held the old token (fix: update `OP_SERVICE_ACCOUNT_TOKEN` on the Render service +
  redeploy, per `DEPLOY.md`). Today's `/health` `200` is consistent with the Render service
  having been redeployed, but the SA-auth half is unverified here — confirm with one `op_health`
  through the connector and one Mac `op_run` from an authenticated session, then supersede the
  memory note.
- **Rotation gotcha (institutionalize):** after ANY SA rotation, restart the long-running
  launchd MCP services AND update the Render env var, or `op_*` keeps failing even though
  `~/.zshrc` is correct. (github-mcp/obsidian-mcp resolve static secrets only at startup and
  don't re-invoke `op` at runtime, so they survive a rotation until next restart.)

---

## 10. Provenance

Built by grep+extract+redact over the JSONL transcripts in the four scoped folders:
`-Users-schnapp-code-schnapp-bet`, `-Users-schnapp-code-schnapp-kit`,
`-Users-schnapp-code-claude-kit`, `-private-tmp`. 1,784 deduped, redacted message
fragments across 83 sessions fed the history sections; current-state claims were
re-verified against live files (`settings.json`, `render.yaml`, `op-wrap.sh`,
`.env.template`s, `credentials-map.md`, `decisions/000{1,2,4}`, `memory/credentials-state.md`)
and two live HTTP probes. The `/private/tmp` daily summaries were used only for dates/context.
No secret value was written to this file or to any intermediate artifact.
