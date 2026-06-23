# Handoff 030 — Phase 1 SA-token rotation COMPLETE (Mac MCP bearer still pending)

Date: 2026-06-22. Surface: Claude Code (Mac). Status: **Phase 1 DONE.** Next = Phase 2 (rename).
Canonical plan: `~/.claude/plans/i-am-not-sure-fancy-garden.md`. Supersedes the "Phase 1 blocked" framing of handoff 029.

## What got done this session
- **Owner rotated the SA token in place** (replaced the value in 1Password item
  `OP_SERVICE_ACCOUNT_TOKEN/credential`, vault `web-variables`). Old token is **dead**
  (`403 Service Account Deleted`); new token last4 `bSJ9`, `op whoami` integration id `55TZ…`
  (was `VU2RK…`). The rotation **is** the revoke — no separate revoke step.
- **Propagated the new token (no-echo) to every surface:**
  - 11 GH repo secrets `OP_SERVICE_ACCOUNT_TOKEN` (obsidian-vault, schnapp-bet, claude-kit,
    appfolio-quickbase-sync, schnapp-kit, claude-skills, sports-modeling, appfolio-mcp, ref-vault,
    af-invoice-parser, af-query-api) — set via `gh secret set` over stdin.
  - `~/.zshrc`, `~/.zshenv` — **UNQUOTED** (see gotcha below).
  - launchd session env — re-ran `com.schnapp.environment` (it `. ~/.zshenv && launchctl setenv`).
  - Render `op-mcp` env + redeploy — **owner** (I have no Render API key).
  - plist `com.schnapp.environment` holds **no** token (it sources `~/.zshenv`) → no plist edit.
- **Restarted + verified healthy** on the new token: `com.schnapp.{macmcp,githubmcp,obsidian-mcp,brain-watcher}`,
  `bet.schnapp.{web-prod,flask}`. Checks: shell `op whoami`=`55TZ`, Render `op_health`=authenticated,
  web-prod HTTP 200, flask up.
- Cleaned up: `~/.sa_new` shredded.

## Self-inflicted detour (recorded so it can't recur)
First propagation wrote the token **single-quoted**. `op-wrap.sh`
(`~/code/schnapp-bet/services/launchd/op-wrap.sh`, the bootstrap for every launchd service) does NOT
source `~/.zshrc` — it `grep`s the line and strips the prefix literally, so it passed `'ops_…'`
(with quotes) to `op` → all 6 services crash-looped on `unrecognized auth type` (~21:42–21:48).
Fixed by rewriting unquoted. Lesson: `memory/op-wrap-token-unquoted.md`.

## OWNER ACTION ITEMS (explicit — what + where)
1. **Mac MCP connector bearer** (restores off-Mac / no-echo + claude.ai/iPhone access; NOT fixable from
   the Mac). The macmcp server, the Mac env, and the vault all hold the SAME bearer (`…6267`); only the
   **connector config stored in your Claude account is stale**.
   - **What:** set the connector's `Authorization: Bearer <value>` (or its URL `?token=<value>`) to the
     current value of `op://web-variables/MAC_MCP_AUTH_TOKEN/credential` (last4 `…6267`).
   - **Where:** claude.ai → **Settings → Connectors** → the Mac/`op`-style connector → custom headers
     (OR the **Cloudflare One → MCP server portals** entry that fronts it — wherever you set its bearer).
   - Optional: that bearer is itself a leaked value (Phase 3 rotates it). If you'd rather set a fresh
     one, say so — I'll mint it on the Mac/vault side to match in the same motion.
2. **(Optional) GH Actions:** the 11 secrets are set but not yet exercised by a real run. Trigger any
   workflow that uses `OP_SERVICE_ACCOUNT_TOKEN` to confirm end-to-end (or ask me to trigger one).

## Carry forward
- `DB_Storage` + `appfolio-marketing-project` repos still lack the `OP_SERVICE_ACCOUNT_TOKEN` secret
  (owner decision — never explicitly scoped).
- Phase 3 still owes rotation of the other leaked values (MAC_MCP_AUTH_TOKEN `…6267`, OP_MCP_BEARER,
  PATs, Anthropic key, DB/`sa`, Web App, Webshare, Cloudflare) — leak record `memory/credential-leak-2026-06-17.md`.
- Earlier in-flight (handoff 029): vault items `MAC_MCP_AUTH_TOKEN`/`GITHUB_MCP_AUTH_TOKEN` created
  (hold leaked bearer values), 6 connector `.env.template` files repointed. Verify their commit state
  before Phase 3.

## Next = Phase 2: rename `claude-kit → schnapp-os`
Per plan §Phase 2. **Needs a session restart** (moving the dir breaks live rule/plugin paths), so it is
handed off here first. Touches: `gh repo rename`, dir `mv`, git remotes, `~/.claude/settings.json`
(path / marketplace / plugin-enable / `autoMemoryDirectory`), `~/.claude/CLAUDE.md` @imports,
`.claude-plugin/marketplace.json` + `plugin.json`.

## Standing gotchas
- `op-wrap.sh` greps `~/.zshrc` → token line MUST be **unquoted**. [[op-wrap-token-unquoted]]
- After ANY SA rotation: restart launchd services + re-run `com.schnapp.environment` + update Render
  env + redeploy. [[credentials-state]]
- Mac MCP tools (`ec6a9080…`) return `unauthorized` this session = the connector bearer, not the SA.
  Drive Mac work through **local Bash** (it runs on the Mac with `op`).

## Copy-paste primer (new session)
```
Resume the single-source rebuild (claude-kit). Phase 1 (SA-token rotation) is DONE: owner rotated the
SA token in place; new token propagated to 11 GH secrets, ~/.zshrc + ~/.zshenv (UNQUOTED — op-wrap.sh
greps zshrc, do not quote), launchd session env, Render op-mcp; all 6 launchd services restarted +
healthy; old token dead. Read first: handoffs/030-phase1-sa-rotation-complete.md,
~/.claude/plans/i-am-not-sure-fancy-garden.md, memory/credentials-state.md, memory/owner-working-preferences.md.

OPEN owner items: (1) Mac MCP connector bearer is stale in the Claude account connector config — set it
to op://web-variables/MAC_MCP_AUTH_TOKEN/credential (…6267) in claude.ai Settings→Connectors / the
Cloudflare MCP portal (not fixable from the Mac). (2) optional GH Actions smoke run.

NEXT = Phase 2: rename claude-kit -> schnapp-os (needs a session restart). Honor owner prefs:
terse/caveman, automate (do don't tell), surface owner-only steps explicitly with what+where, never
echo a secret value. Mac MCP tools are unauthorized this session — use local Bash for Mac ops.
```
