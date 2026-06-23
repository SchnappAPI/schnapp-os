---
name: rotate-secret
description: Use when a secret value must be replaced everywhere it lives — it leaked or is suspected compromised, it is being renamed/split during the vault reorg (rotate-on-migrate), or it is due for periodic rotation. Symptoms include "rotate the token/key/password", "this credential leaked", "mint a fresh value", a compromised bearer/PAT/API key, the credential-leak remediation list.
---

# rotate-secret

A rotation is not "change the value in 1Password." It is: mint a fresh value, update **every
place the value is set**, restart what caches it, and verify resolution — in lockstep, one item at
a time. Miss a leg and that surface breaks (or keeps serving the dead value). The authoritative
where-to-update list is the item's **`consumed_by`** column in
[credentials-map.md](../../../../credentials-map.md); the rotation is logged in that file's
append-only **changelog**.

> A value that leaked is dead the moment it is exposed. Relocating or redacting it is not enough —
> only rotation makes it safe. [[credential-leak-2026-06-17]]

## Protocol (one item at a time)

1. **List the legs.** Read the item's `consumed_by` in the [map](../../../../credentials-map.md).
   That is the complete checklist for this rotation. If it looks incomplete, fix the map first.
2. **Mint a fresh value** (never reuse the old one):
   | Kind | How | Who |
   |---|---|---|
   | MCP / connector bearer, generic secret | `openssl rand -hex 32` | self-serve (this Bash) |
   | web-app passcodes / token secrets | `openssl rand -hex 32` | self-serve |
   | 1Password SA token | 1Password admin → rotate the service account | **owner** |
   | GitHub PAT | github.com → Developer settings → tokens | **owner** |
   | Anthropic API key | console.anthropic.com | **owner** |
   | Claude Code OAuth token | `claude setup-token` | **owner** (interactive) |
   | Webshare / Cloudflare API token | their consoles | **owner** |
   When a step is owner-only, surface exactly **what + where** and stop on that leg
   ([[owner-working-preferences]] #4); do every self-serve leg yourself. **Generation output must
   never be printed** — use the non-echoing generate-and-store form in step 3, not a bare `openssl`.
3. **Store in 1Password — non-echoing by construction.** Capture the value into a variable (command
   substitution does not print it) and store it by reference; never inline the literal into a command:
   ```bash
   val=$(openssl rand -hex 32)                    # self-serve mint: captured, never printed
   op item edit "<ITEM>" "<field>=$val"           # transcript shows "$val", not the value
   unset val
   op item get "<ITEM>" --vault web-variables     # confirm — concealed fields stay masked (no --reveal)
   ```
   For an owner-minted value (PAT, API key): owner pastes it into 1Password directly, or read it from
   a file into `$val` (`val=$(< ~/.tmp_secret)`) then shred the file — never echo it.
4. **Propagate to every leg** from step 1. Common legs: `~/.zshrc` + `~/.zshenv`, the launchd
   session env, per-repo GitHub Actions secrets (`gh secret set`), Render service env, the
   Cloudflare portal header, connector `.env.template` (as an `op://` ref, not the value),
   deployed connector hosts.
5. **Restart / redeploy what caches it** (the rotation gotcha — long-running services hold the old
   value in-process). The map's `consumed_by` says which apply; the known launchd labels are
   `com.schnapp.macmcp`, `com.schnapp.githubmcp`, `com.schnapp.obsidian-mcp`,
   `com.schnapp.brain-watcher`, `bet.schnapp.web-prod`, `bet.schnapp.flask`. For each affected one:
   `launchctl kickstart -k gui/$(id -u)/<label>`; then re-run `com.schnapp.environment` to refresh the
   launchd session env; and update the Render service env + **redeploy** (owner — no Render API key on
   the Mac). [[credentials-state]]
6. **Verify** on each surface: `op whoami` where the SA changed, `op read` the new ref, connector
   `op_health`, the consuming app (HTTP 200 / job runs). Old value must now fail.
7. **Record** in the map changelog (date · change · every location updated · done ✓) and flip any
   matching tracker box in the same commit ([anti-stale](../../rules/global/anti-stale.md)).

## Gotchas (these break rotations)

- **`op-wrap.sh` requires the SA token UNQUOTED in `~/.zshrc`** — it greps the line and strips the
  prefix literally; quotes get passed to `op` and every launchd service crash-loops on
  `unrecognized auth type`. [[op-wrap-token-unquoted]]
- **In-place rotation has no zero-downtime window** — replacing the value in the existing item kills
  every surface on the old value until propagated. Sequence fast, or mint-alongside where the API
  allows. [[credentials-state]]
- **OAuth token ≠ API key** — never wire a `sk-ant-oat…` where an `sk-ant-api…` is expected (401s).
- **Bootstrap secrets are not `op://`-resolvable** (the SA token, the bearers) — they ARE the keys;
  set them directly in each surface's env, and the map says so.

## The leak remediation list (rotate-on-migrate)

Outstanding from [[credential-leak-2026-06-17]] — rotate each as it is migrated/split, fresh value:
`MAC_MCP_AUTH_TOKEN`, `GITHUB_MCP_AUTH_TOKEN`, `OP_MCP_BEARER` (self-serve `openssl`); `GITHUB_PAT`,
Anthropic key, Claude OAuth, DB `sa`, Web App secrets, Webshare, Cloudflare (owner consoles).
(`OP_SERVICE_ACCOUNT_TOKEN` already rotated 2026-06-22 — [[credentials-state]].)

Related: [vault-resolve](../vault-resolve/SKILL.md) (read the new value) ·
[cleanse-secrets](../cleanse-secrets/SKILL.md) (find what leaked) · the map's `consumed_by` + changelog.
