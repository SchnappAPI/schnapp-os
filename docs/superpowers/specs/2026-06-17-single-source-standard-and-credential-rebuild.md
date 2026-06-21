# Single-Source-of-Truth Standard + Secrets Domain — design

Date: 2026-06-17. Status: **design — pending owner approval.** Surface: Claude Code (Mac).

This is **spec 1 of a program** to end information sprawl/staleness across the whole system.
Approach = hybrid (owner-approved): write a *thin* governing standard now, then prove it on the
**secrets domain** (which is also a live credential-leak incident). Follow-up specs cover the
**rules/knowledge** consolidation and the **repos** consolidation (incl. the `claude-kit → schnapp-os`
rename and the tooling-distribution merge).

Supersedes/extends [2026-06-17-credential-system-design.md](2026-06-17-credential-system-design.md):
keeps its item conventions + target inventory, but **changes the PAT decision** (single shared → two
scoped PATs) and **adds** connector-as-resolver, rotate-on-migrate, and the enforcement skills below.

Incident context: [memory/credential-leak-2026-06-17.md](../../../memory/credential-leak-2026-06-17.md)
(plaintext dump of every vault value, incl. the master SA token, committed + pushed in
`obsidian-vault` exports → all values compromised). Operational state:
[memory/credentials-state.md](../../../memory/credentials-state.md). Map:
[credentials-map.md](../../../credentials-map.md).

---

## Problem (owner's words, distilled)

Every pain — stale values, wrong-value access failures, re-explaining, too many rule/memory
layers, conflicting info across repos/conversations that gets re-fixed forever — is **one disease**:
the same fact lives in many places and nothing stops the copies. Band-aids fail because they fix
*instances*, not the *structure* that allows duplication. The rules already *say* "single source of
truth"; nothing *enforces* it, and the structure still duplicates.

Goal: **set one doctrine — one canonical home per fact, everything else references/generated, drift
impossible or auto-caught — then make everything conform.** Not "start fresh" (loses
indistinguishable-but-valuable work); instead: see the landscape, set the standard, migrate what
matters forward, delete the rest (git is the archive), enforce.

---

## Part 1 — The Standard (thin, permanent)

### 1.1 The Doctrine — five laws

Lives as **one global rule** in `schnapp-os` (loads in every session, every surface). It elevates and
replaces the scattered anti-stale guidance:

1. **One canonical home per fact.** Every fact-type has exactly one home, named in the Registry.
2. **Reference or generate, never copy.** Consumers link to the home or are generated from it and
   stamped "generated — do not edit."
3. **Working tree = current canonical truth only.** Stale/duplicate/superseded gets **deleted**.
   git history is the archive; "just in case" lives in `git log`, not in the tree.
4. **Subtract before you add.** Anything that supersedes another retires the old *in the same change*.
5. **Enforcement is automated.** CI + a standing audit catch drift. Willpower is not the mechanism.

### 1.2 The Registry

One index (in `schnapp-os`) answering "where does this kind of truth live?" for every fact-type, plus
the **non-sources** (things never to treat as truth). Generated/validated where possible. Initial rows:

| Fact-type | Canonical home | Notes |
|---|---|---|
| Secret values | 1Password `web-variables` vault | resolved at runtime; never copied into files/hosts |
| Secret wiring (refs, consumed_by) | `credentials-map.md` | generated from the vault where possible |
| How-to-work rules (global) | `schnapp-os/plugins/core/rules/global/` | the Doctrine lives here |
| Path-scoped rules | `schnapp-os/plugins/core/rules/modules/` | load on matching files |
| Skills / agents / commands / hooks | `schnapp-os` (the one distribution) | CI + all machines point here |
| Project status | per-repo `PLAN.md` + `PROGRESS.md` | |
| Architecture decisions | per-repo `decisions/` | ADRs |
| Durable cross-surface facts | `schnapp-os/memory/` | agent-facing |
| Session handoffs | `schnapp-os/handoffs/` | transient, pruned |
| Personal knowledge / idea-graph | the one Obsidian vault | incl. redacted conversation archive |
| Code | one canonical repo per project | see repos spec |
| **Non-sources** (never truth) | — | raw chat exports, stale clones (`web-bad`), archives, old session logs |

### 1.3 Enforcement model

- **CI drift checks** (fail the build): derived doc older than its source; **literal secret in a
  tracked file**; stale/unresolvable `op://` ref; a fact-home not in the Registry.
- **`cleanse-secrets` skill** — redact secret patterns from content (used 3 ways: pre-export
  redaction, CI scan, retroactive backfill).
- **Standing consolidation skill** — re-runs map→disposition→prune on demand/cadence so accretion is
  caught in weeks, not discovered months later as a stale value.
- **Subtract-before-add** — encoded in the Doctrine; checked where feasible.

---

## Part 2 — Secrets Domain (the proof + the leak fix)

### 2.1 Target architecture — vault is the sole source, connector is the resolver

- **1Password `web-variables` = the sole home of every secret value.**
- **The op-mcp connector = the single resolution surface.** It already resolves `op://` refs and is
  reachable from every surface via the Cloudflare portal. All 5 surfaces (MacBook Pro, HP laptop,
  work desktop, claude.ai, iPhone) resolve through it.
- **`vault-resolve` skill** — surface-agnostic: resolves/uses an `op://` ref via the connector (local
  `op` CLI fallback on the primary Mac), **never storing the value on the client**.
- **Bootstrap minimized — hybrid.** The master `OP_SERVICE_ACCOUNT_TOKEN` lives in **two** places
  only: the **connector host** (the resolver) and the **primary Mac** (local `op` for launchd-service
  startup robustness). HP / work desktop / claude.ai / iPhone hold **no SA token** — only the
  low-privilege **bearer** (or the portal). Bearer leak → rotate the bearer, not the vault.
- **Writes/admin** (creating/splitting/deleting vault items) use a privileged path — primary-Mac `op`
  CLI or the 1Password app. The connector is read/resolve only.

Result: when a secret changes, you update **one** place (the vault); consumers re-resolve. The SA
token's footprint drops from ~5 locations to 2, both rotation-scripted.

### 2.2 Item conventions

Carried from [credential-system-design](2026-06-17-credential-system-design.md): UPPER_SNAKE title =
the consuming env var; one secret per item; single-secret → API Credential category, value in
`credential`; co-required sets stay bundled with env-var-labeled fields; tags group; per-item
operational note; the map is references-only and generated from the vault where possible.

### 2.3 Target inventory — rotate-on-migrate

Every item that is split/renamed gets a **fresh value** (not a copy of the leaked one). From the
target inventory, with this spec's changes:

- `MCP Tokens` → **`MAC_MCP_AUTH_TOKEN`** + **`GITHUB_MCP_AUTH_TOKEN`** (items already created this
  session holding the *leaked* bearer values → **rotate to fresh** `openssl rand -hex 32`).
- Retire `GitHub` bundle → **two PATs**: scoped **`GITHUB_PAT`** (Contents/Actions/PRs/Issues/Checks/
  Statuses/Deployments R/W, Metadata R — no Administration/Webhooks/Deploy-keys) + new
  **`GITHUB_PAT_ADMIN`** (Administration/Webhooks/Deploy-keys/Secrets — owner-held, not distributed).
- `Anthropic` dissolve → **`OBSIDIAN_BRAIN_AGENT`** (the live Anthropic API key) + dedup
  **`CLAUDE_CODE_OAUTH_TOKEN`**; delete `schnapps-mbp-brain-agent` + empty `password`.
- `Web App` split → `ADMIN_PASSCODE`, `ADMIN_REFRESH_CODE`, `AUTH_TOKEN_SECRET`, `ODDS_API_KEY`,
  `RUNNER_API_KEY` + **`WEB_APP_CONFIG`** (non-secrets). **`SQL_CONNECTION_STRING` → dropped**: derive
  the `mssql` config in `schnapp-bet/web/lib/db.ts` from the discrete `DATABASE` fields.
- `Database` → split out **`MSSQL_SA_PASSWORD`**; `DATABASE` keeps the app connection. **Defer** the
  least-privilege app login; document that `username`/`password` are currently `sa`.
- **`OP_MCP_BEARER`** + the two MCP bearers → rotate (`openssl`).
- **`CLOUDFLARE_API_TOKEN`** → **parked** (live connector is OAuth/tokenless; no consumer today).
- **`OP_SERVICE_ACCOUNT_TOKEN`** → **rotate first** (see 2.4).
- Also leaked, rotate even though "keep as-is": `Webshare Proxy`, `Cloudflare Tunnel`.

### 2.4 Rotation order + who-does-what

Order (SA first — it unlocks the whole vault; downstream rotation is pointless until it's cut):

0. **`OP_SERVICE_ACCOUNT_TOKEN`** — owner mints a NEW token alongside the old (zero-downtime). I
   propagate to its 2 bootstrap locations + the connector host + GH Actions repo secrets + Render
   `op-mcp` env; restart launchd services (the rotation gotcha); verify `op whoami`/`op_health`/a real
   `op read` on every surface; owner revokes the old token.
1. **Bearers** (`OP_MCP_BEARER`, `MAC_/GITHUB_MCP_AUTH_TOKEN`) — `openssl`; update vault + connectors
   + Cloudflare portal header + restart. **`GITHUB_PAT` / `GITHUB_PAT_ADMIN`** — owner regenerates on
   github.com with the scopes in 2.3.
2. **`OBSIDIAN_BRAIN_AGENT`** (owner: console.anthropic.com) + **`CLAUDE_CODE_OAUTH_TOKEN`** (owner:
   `claude setup-token`).
3. **Web App** secrets — `ODDS_API_KEY` owner-regen at the provider; passcodes/`AUTH_TOKEN_SECRET`/
   `RUNNER_API_KEY` I generate fresh.
4. **`MSSQL_SA_PASSWORD`** + `DATABASE/password` — `ALTER LOGIN` in the SQL Server container + update.
5. **Webshare** (owner: webshare.io), **Cloudflare Tunnel** (owner).

Owner-only: SA mint, both PATs, Anthropic key, Claude OAuth, Webshare, Cloudflare. Everything else I
drive end-to-end (resolve → update vault via `op` → repoint consumers → restart → verify), surfacing
only the owner-only mints.

### 2.5 The rotation script (one command going forward)

A single script/skill **`rotate-secret <NAME>`**: accept/generate the new value → write the vault item
→ propagate to every consumer in that item's `consumed_by` (map-driven) → restart affected services →
verify resolution. Future rotation = one command, not a hunt. This is the owner's "rotate + update in
one place, everything reads from it" requirement made real.

### 2.6 Leak remediation

- **Rotate** (2.4) — makes every leaked value dead.
- **`cleanse-secrets` retro-scrub** the ~28 `obsidian-vault/Claude Export/Conversations/*.md` +
  `Notes/Credentials CLAUDE.md` — **redact secrets, keep the conversations** (delete-by-default
  applies to the *secrets*, not the owner's idea-graph).
- **Pre-store redaction** going forward — `cleanse-secrets` runs before any conversation is exported,
  so this never recurs.
- **History rewrite** — decision **deferred until after rotation** (then history holds dead values);
  revisit whether a `filter-repo` + force-push is worth it.
- This session's transcript contains the dumped values (a grep surfaced them) → treat the
  2026-06-17 session log as sensitive.

### 2.7 New skills (small, reusable — owner prefs #2/#3)

- **`vault-resolve`** — resolve/use an `op://` ref on any surface via the connector (local `op`
  fallback), never exposing the value.
- **`cleanse-secrets`** — redact secret patterns (`ops_…`, `sk-ant-(api|oat)…`, `github_pat_…`,
  connection strings, etc.) from any content; pre-store + CI scan + backfill.
- **`rotate-secret`** — the rotation runbook (2.5) as a skill.

### 2.8 Secrets-specific enforcement

- CI: scan tracked files for literal secret patterns → fail.
- CI: scan for stale/unresolvable `op://` refs.
- `vault-resolve` is the **only** sanctioned way to bring a value into a task; literal secrets in any
  tracked file are a CI failure (the rule already exists; now it's enforced).

---

## Sequencing (re-sequenced after the 2026-06-17 environment review)

Canonical execution roadmap = the approved plan `~/.claude/plans/i-am-not-sure-fancy-garden.md`.
Re-sequenced so the rename happens before the secrets skills are built (avoid build-then-move):

1. **Phase 0** — fold these review deltas into this spec (done).
2. **Phase 1 — SA-token rotation** (owner mint, zero-downtime). Stop the leak; needs no new skills.
3. **Phase 2 — consolidate to `schnapp-os`** — rename `claude-kit → schnapp-os` (session boundary) +
   harvest `schnapp-kit` + run the consolidation-loop (disposition every skill/agent/plugin/connector,
   incl. `claude-mem`) + build the Registry + elevate the Doctrine.
4. **Phase 3 — secrets domain in schnapp-os** — build `vault-resolve`/`cleanse-secrets`/`rotate-secret`;
   item rotate-on-migrate (connectors → PATs → Anthropic/Claude → Web App → Database); vault-as-sole-source
   via connector; leak scrub; extend the freshness CI with secret-scan.
5. **Phase 4 — rules / knowledge / repos** domains via the same loop.

### Reuse-over-build (2026-06-17 review)

Base = `claude-kit → schnapp-os`; harvest `schnapp-kit` (per `decisions/0003`). Most planned components
already exist — reuse, don't rebuild:
- **Doctrine** ≈ `plugins/core/rules/global/anti-stale.md` (+ `secrets-as-references`, `knowledge-capture`) → elevate.
- **CI drift / secret-scan** ≈ `.github/workflows/freshness.yml` → extend.
- **handoff / agentic-os / cleanse-secrets** (≈ `secrets-hygiene-reviewer` + `opensource-forker`) /
  **consolidation-loop** (≈ `rules-distill` + `skill-stocktake`) → harvest from schnapp-kit/core.
- **BUILD NEW only:** `rotate-secret`, the canonical-home **Registry**, `vault-resolve`.
- Competing systems (`claude-mem` + its live MCP, disabled plugins) → dispositioned **per-item in the consolidation map**.

## In-flight state (this session, before pause)

- Items **created** (hold leaked values → must rotate): `MAC_MCP_AUTH_TOKEN`, `GITHUB_MCP_AUTH_TOKEN`.
- **Repointed** (uncommitted): 6 connector `.env.template` files (repo + deployed) — MCP bearer refs +
  `GH_PAT` ref → the new items / `GITHUB_PAT/token`.
- Nothing committed, deleted, or service-restarted. Fully reversible.
- Memory written: `credential-leak-2026-06-17`, `owner-working-preferences`; `credentials-state`
  banner corrected.
- Spawned background tasks: harden hardcoded auth fallbacks (schnapp-bet); prune stale clones
  (web-bad, sports-modeling worktree).

## Risks

- **SA rotation blast radius** — zero-downtime mint (new alongside old) + verify-before-revoke mitigates.
- **Connector as single resolution point** — hybrid keeps local `op` for Mac launchd; monitor connector uptime.
- **`actions: write` in `GITHUB_PAT`** — intrinsic secret-exfil pivot (web app dispatches workflows);
  not removable without redesigning that feature; admin/destructive moves live only in `GITHUB_PAT_ADMIN`.
- **`SQL_CONNECTION_STRING` drop** — one-file code change in `web/lib/db.ts`; verify the pool connects before deleting the secret.

## Non-goals (this spec)

- Rules/knowledge consolidation; repos consolidation + the rename mechanics (their own specs).
- The least-privilege DB app login (deferred; documented).
- Cloudflare API token (parked).
