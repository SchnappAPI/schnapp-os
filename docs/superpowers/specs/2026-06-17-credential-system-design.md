# Credential system design — one cohesive 1Password layout

Date: 2026-06-17. Status: **design only** — no 1Password item, field, or `op://`
reference changes until the owner schedules the migration. This spec defines the
convention, the target inventory, and the rename/rotation protocol. History and the
verified current-state are in [credentials-archaeology-2026-06-17.md](../../credentials-archaeology-2026-06-17.md).
The living, references-only map is [credentials-map.md](../../../credentials-map.md).

## Problem

The `web-variables` vault (18 items, verified 2026-06-17 via `op item list`) is
inconsistent: secrets are bundled into multi-purpose items (`MCP Tokens`, `Web App`,
`Anthropic`, the old `GitHub`), titles name the category not the thing
(`CONNECTOR_AUTH_TOKEN`), nothing records what consumes a secret or where else its value
is set, and there is no tagging. Result: every return visit means reverse-engineering, and
storing a new key has no template.

## Goals

1. Consistent, descriptively-concise, unambiguous names.
2. One secret per item; group only fields you need *together to authenticate*.
3. Findability via tags, not bundling.
4. Each item self-documents its purpose + rotation in its 1Password note.
5. One references-only map as the system source of truth.
6. A repeatable rename protocol that always knows every place a name is used, with a changelog.

Keep it simple and secure: a solid foundation, not a sprawling one.

---

## Convention

### 1. Naming
- A secret's title = **its canonical env-var name, UPPER_SNAKE**, used *identically* in the
  consuming system, its config/env, and the 1Password title. One name, everywhere.
  Examples: `GITHUB_PAT`, `ANTHROPIC_API_KEY`, `MAC_MCP_AUTH_TOKEN`.
- Where a secret has two names across systems today, pick one canonical name and converge
  the systems to it.
- Names are descriptively concise: maximum clarity in the fewest characters, no ambiguity.
- Co-required **bundles** use a clear system name as the title; each field is labeled by its
  own env var. Example: `DATABASE` with fields `server`, `database`, `username`, `password`,
  `trust_cert`.

### 2. One secret per item
- Split anything bundled only for convenience.
- Keep multiple fields in one item **only** when you need them together to authenticate or
  connect (a login pair; a full DB/proxy/tunnel connection set). Rule of thumb: if rotating
  field X forces you to rotate field Y, they belong together.

### 3. Field convention (predictable refs)
- Single-secret item → 1Password **API Credential** category, secret in the `credential`
  field → `op://web-variables/<TITLE>/credential`.
- Bundle → fields labeled by their env var → `op://web-variables/<TITLE>/<field>`.
- The map records the exact `op_ref` per item; the reference must match the real field
  label (historically `op://web-variables/GITHUB_PAT/credential` did NOT resolve because the
  field is `token` — the map is authoritative on the actual label).

### 4. Tags, not bundling
Group by tag; never merge items to group them.
Taxonomy: `bootstrap, github, mcp, llm, db, etl, config, cloudflare, proxy, personal`.

### 5. Metadata location (avoid the staleness trap)
- **1Password item note** = the operational story for *that* secret: purpose, gotchas, and
  how/where to rotate it (incl. every other place the value is set). Written for a human
  standing in front of the item.
- **The map** ([credentials-map.md](../../../credentials-map.md)) = the references-only
  index of the whole system: title, `op_ref`, type, tags, one-line purpose, `consumed_by`.
  No values. Later it can be **generated** from 1Password (titles + tags + notes) so it
  cannot drift.
- Each fact lives in one place: rotation detail in the note; cross-system wiring in the map.

### Security foundation (lean)
- References only, never values, in any tracked file.
- Bootstrap secrets (`OP_SERVICE_ACCOUNT_TOKEN`, the MCP bearers) are set directly in each
  surface's env — they are NOT `op://`-resolvable, and the map says so.
- Prefer scoped tokens. See the accepted-risk note on the shared GitHub PAT below.
- **OAuth token ≠ API key** — never cross-wire them. A Claude OAuth token injected where an
  `sk-ant-` API key was required 401'd the brain pipeline (2026-06-15). Name/type them distinctly.

---

## Rename / rotation protocol

Every rename or rotation is governed by two artifacts:

1. **`consumed_by` (per item, in the map)** = the authoritative list of every place the
   name/value appears. It is the where-to-change checklist for a rename AND the
   where-to-update checklist for a rotation.
2. **Changelog (in the map, append-only):**

   | date | change | every location updated | done |
   |---|---|---|---|
   | 2026-06-17 | `CONNECTOR_AUTH_TOKEN` → `OP_MCP_BEARER` | repo done (src+dist, render.yaml, Dockerfile, .env.template, DEPLOY.md, README, map); owner-pending: 1P title + Render env key + redeploy | ◑ |

   Any stale reference found later traces back through this log instantly.

**Worked example — `CONNECTOR_AUTH_TOKEN` → `OP_MCP_BEARER`, every place it lives:**
1Password item title · `connectors/op-mcp/` source (`process.env.CONNECTOR_AUTH_TOKEN`) ·
`render.yaml` envVars key · Render dashboard env var on the `op-mcp` service ·
`connectors/op-mcp/.env.template` (also fixes the `connector-bearer` field-name drift) ·
`DEPLOY.md` · `credentials-map.md`. (Cloudflare portal holds the value only, not the name.)

---

## Target inventory (current → action)

`[V]` = verified present in `web-variables` on 2026-06-17.

### Rename
| Current | Target | Why |
|---|---|---|
| `CONNECTOR_AUTH_TOKEN` `[V]` | `OP_MCP_BEARER` | Says what it is: the bearer gating the op-mcp connector. Tag `mcp`. |

### Consolidate (minimize)
| Current | Target | Notes |
|---|---|---|
| `GITHUB_PAT/token` + `GitHub/{pat_git_credentials, pat_web_plist, pat_github_mcp}` `[V]` | **one shared `GITHUB_PAT`** | Owner decision 2026-06-17: single all-repos/all-perms PAT shared by all GitHub consumers (gh CLI, Actions, mac-mcp, github-mcp). See **Accepted risks**. Retire the `GitHub` bundle once consumers point at `GITHUB_PAT`. |
| `Anthropic/CLAUDE_CODE_OAUTH_TOKEN` + `Claude Code/oauth_token` `[V]` | one `CLAUDE_CODE_OAUTH_TOKEN` | Dedup; the token exists in two items today. |

### Split (one secret per item)
| Current bundle `[V]` | Becomes |
|---|---|
| `Web App` (secrets) | `ADMIN_PASSCODE`, `ADMIN_REFRESH_CODE`, `AUTH_TOKEN_SECRET`, `ODDS_API_KEY`, `RUNNER_API_KEY`, `SQL_CONNECTION_STRING` |
| `MCP Tokens` | `MAC_MCP_AUTH_TOKEN`, `GITHUB_MCP_AUTH_TOKEN` |
| `Anthropic` (dissolve) | `api_key` (live — the Obsidian brain key) → `OBSIDIAN_BRAIN_AGENT` (tags `llm`,`obsidian`); `CLAUDE_CODE_OAUTH_TOKEN` → dedup into the one `CLAUDE_CODE_OAUTH_TOKEN` item; `schnapps-mbp-brain-agent` field → **delete** (stale dup of `api_key`); `password` empty → unused, confirm + remove |
| `Database` | split out `MSSQL_SA_PASSWORD` (a different login than the app user); `DATABASE` keeps the app connection |

### Non-secret config — stays in 1Password (owner decision 2026-06-17)
The vault is the owner's source of truth for ports/urls/etc. The `Web App` non-secrets
(`hostname`, `node_env`, `port_prod`, `port_dev`, `runner_url`, `runner_url_dev`) move to a
clearly-named config item `WEB_APP_CONFIG`, tag `config`. Not credentials, but tracked here
deliberately.

### Keep as-is (co-required bundles + already-good), add note + tag
`DATABASE` (db) · `WEBSHARE_PROXY` (proxy) · `CLOUDFLARE_TUNNEL` (cloudflare) ·
`GITHUB_ACTIONS_RUNNER` (github) · `DROPBOX` (config/app) · `GITHUB_PAT` (github) ·
`OP_SERVICE_ACCOUNT_TOKEN` (bootstrap) · `QUICKBASE_EXCEL_SYNC` (etl) · `GITHUB_SSH_KEY` (github).

### Create
| New | Why |
|---|---|
| `CLOUDFLARE_API_TOKEN` | A **scoped** Cloudflare User API Token (My Profile → API Tokens), for the Cloudflare MCP connector. No such item exists today (`Cloudflare Tunnel` is transport creds, not an API token). Scopes TBD from the connector's needs. Tag `cloudflare`. |

### Personal — untouched (optionally tag `personal`)
`Elgato`, `Obsidian`, `Schnapp's MacBook Pro`.

---

## Open verifications (resolve during migration, not now)

1. **`schnapps-mbp-brain-agent` — RESOLVED 2026-06-17.** It is the Obsidian "brain" pipeline's
   dedicated Anthropic API key (console key `schnapps-mbp-brain-agent`, value in `Anthropic/api_key`),
   consumed as `ANTHROPIC_API_KEY` by `com.schnapp.brain-watcher` → `brain_agent.py`. The separate
   field of the same name is a stale dup → delete. Target item: `OBSIDIAN_BRAIN_AGENT`.
2. **`SQL_CONNECTION_STRING` redundancy.** May be the `DATABASE` fields re-encoded as one
   string. If derivable, drop it (minimize); if a genuinely distinct connection, keep.
3. **`Anthropic/password` is empty `[V]`.** The historical `ANTHROPIC_API_KEY` ref pointed
   here. Confirm what (if anything) still reads `Anthropic/password` before migrating, so
   nothing silently resolves to empty.

## Accepted risks

- **Shared all-repos/all-permissions `GITHUB_PAT`** (owner decision 2026-06-17). Chosen for
  minimal credentials / simplest management over a scoped split. Consequence: a leak from any
  consumer — including the off-Mac MCP hosts — exposes full read/write to every repo.
  Mitigation: single rotation point; on any suspected leak, rotate immediately (all consumers
  re-resolve from the vault); revisit scoping if the exposure surface grows.

## Known operational issues to fix as part of execution (from current-state)

- **Off-Mac op-mcp connector is down on auth.** `op_health` → authentication error
  (2026-06-17): the Render `OP_SERVICE_ACCOUNT_TOKEN` is stale after the 2026-06-15 SA
  rotation. Fix per `connectors/op-mcp/DEPLOY.md`: update the Render env var + redeploy. The
  Mac shell SA is valid (`op whoami` works).
- **`credentials-map.md` staleness:** it names the SA item `Service Account Auth Token:
  schnapp-automation`; the real title is `OP_SERVICE_ACCOUNT_TOKEN`. Correct when the map is
  upgraded.

## Source-of-truth structure

- **Map** = upgrade `credentials-map.md` into the canonical references-only inventory
  (item table + `op_ref` + tags + `consumed_by` + the changelog). Do not create a new doc.
- **History** = this session's archaeology doc, linked from the map.
- **This spec** = the convention + target plan.
- **1Password notes** = per-item operational detail.
- All in the private `claude-kit` repo; no values anywhere; never needs to be public.

## Execution (later, owner-scheduled)

Migration is a separate, sequenced effort using the rename protocol above: for each item,
update consumers → 1Password → map + changelog in lockstep, one item at a time, verifying
resolution after each. Not part of this design.
