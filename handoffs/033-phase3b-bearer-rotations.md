# Handoff 033 — Phase 3B: MCP-bearer rotations (3/3 done) + rename-residual fixes

Date: 2026-06-23. Surface: Claude Code (Mac). Status: **Phase 3B self-serve + owner-coordinated
rotations DONE + verified.** Open as PR `chore/phase3b-bearer-rotations` (commits below). Prior:
`handoffs/032-phase3a-secrets-skills.md`. Canonical plan: `~/.claude/plans/i-am-not-sure-fancy-garden.md`
§Phase 3. Drove with the `rotate-secret` skill; map = `credentials-map.md` (changelog has every leg).

## What got done (all in branch `chore/phase3b-bearer-rotations`)
Three leaked MCP bearers rotated-on-migrate, fresh `openssl rand -hex 32`, **non-echoing** mint+store
(`val=$(openssl rand -hex 32); op item edit <ID> "credential[password]=$val"; unset val`), one at a time,
verified after each. `/credential` stays CONCEALED (len 64). Item IDs: MAC `kxjl5looa4x3fqhuynpqxsdunq`,
GH `34kn5t4ryjyyfm2pnj7eiwmbqm`, OP_MCP_BEARER `zpdb57x2brfm2rrh4y3zb354jy`.

1. **`MAC_MCP_AUTH_TOKEN`** → restarted `com.schnapp.macmcp` (+`com.schnapp.obsidian-mcp`). Verified Mac:
   `:8765` new bearer → HTTP 200, bogus → 401. (Killed the old `…6267` value = the bearer that made Mac
   MCP tools `unauthorized` in prior sessions.)
2. **`GITHUB_MCP_AUTH_TOKEN`** → restarted `com.schnapp.githubmcp`. Verified Mac: `:8766` new → 200,
   bogus → 401.
3. **`OP_MCP_BEARER`** (owner present, opted in). Owner did Render `op-mcp` env + redeploy and Cloudflare
   portal `mcp.schnapp.bet` `op-mcp` Custom header `Authorization: Bearer …`. **Leg 3 (direct client
   bearer) = N/A** — Mac/claude.ai/iPhone reach op-mcp via the portal over **OAuth** (`config.json`
   `oauth:tokenCache`, no static client bearer); only a direct `op-mcp.onrender.com` client would use it,
   none configured. Verified: `op_health` authenticated; origin `/health` 200, `/mcp` new → 200, bogus → 401.

### Mid-rotation infra fixes (rename residual + security — Mac-side, recorded in the map changelog)
- **Broken `server.py` symlinks (PREREQ, would have crash-looped a restart):** deployed
  `~/{mac,github,obsidian}-mcp/server.py` pointed at the **dead** `~/code/claude-kit/connectors/*` path
  (Phase 2 finalize removed the `~/code/claude-kit` transitional symlink). Services survived only as
  long-running processes; any restart/reboot → ENOENT crash-loop. Repointed all three to
  `~/code/schnapp-os/connectors/*/server.py` (`ln -sfn`) **before** the first restart. Validated by the
  rotation restarts (fresh PIDs loaded the new target).
- **Clobbered macmcp plist (reboot-exposure):** `~/Library/LaunchAgents/com.schnapp.macmcp.plist` had been
  overwritten with a bare JSON `ProgramArguments` array (no `Label`/`WorkingDirectory`). On reboot launchd
  would start macmcp with cwd `/` → `MCP_TOKEN=""` → **bearer auth disabled (exposed)**, or fail to load.
  Rewrote it as a proper **secrets-free op-wrap `<dict>`** matching the live loaded job (lint OK, cwd
  `~/mac-mcp`, op-wrap resolves `~/mac-mcp/.env.template`). **Not reloaded** (running job healthy +
  verified); activates next reboot/reload. Clobbered file saved `.jsonarray-bak-20260623`.
- **obsidian-mcp vestigial ref:** `connectors/obsidian-mcp/.env.template` (repo + deployed) injected
  `MAC_MCP_AUTH_TOKEN` but the OAuth server reads no `*_AUTH_TOKEN` (verified) — injected-but-ignored.
  Removed (anti-stale). So obsidian-mcp is **not** a functional MAC_MCP_AUTH_TOKEN consumer; the map's
  `consumed_by` now says so (mac-mcp is the only functional consumer).

## ⚠️ OWNER-GATED — open items (what + where; agent cannot)
1. **Client bearer legs for #1/#2** (don't break anything; just refresh the client to the new value):
   - claude.ai connector `mac-mcp.schnapp.bet` → Authorization Bearer = `op://web-variables/MAC_MCP_AUTH_TOKEN/credential`.
   - Copilot / github-mcp client bearer = `op://web-variables/GITHUB_MCP_AUTH_TOKEN/credential`.
   (Copy the value from the 1Password app — never paste it into a tracked file.)
2. **Plaintext-secrets backup**: `rm ~/Library/LaunchAgents/com.schnapp.macmcp.plist.bak.20260524-105649`
   (plain terminal — destructive-guard blocks me). It holds the dead MAC bearer + **live** `GH_PAT` +
   `RUNNER_API_KEY`.
3. **Owner-console rotations still outstanding** (rotate-on-migrate, leaked values): `GITHUB_PAT`
   (+`GITHUB_PAT_ADMIN`), Anthropic API key, Claude OAuth, DB `sa`, Web App secrets incl.
   **`RUNNER_API_KEY`** (= Web App `/runner_api_key`; newly surfaced + transited this transcript via a
   redaction gap), Webshare, Cloudflare. See `memory/credential-leak-2026-06-17.md`.
4. **Merge the PR** (`chore/phase3b-bearer-rotations`). After merge, `git branch -D` the `[gone]` branch
   (guard blocks `/clean-gone`).
5. **Optional (offered):** a validated reload of macmcp (`launchctl bootout`/`bootstrap`) at a safe time
   to exercise the rewritten plist end-to-end. Not done to avoid disturbing the freshly-verified job.

## Deferred (unchanged from 032)
- ~28-file `obsidian-vault` export leak scrub (separate repo; history-rewrite still deferred until after
  all rotation). Promote `check-op-refs.sh` to BLOCK once stable. Tighten the `assignment-secret` WARN
  heuristic (still flags prose like "Authorization Bearer …", non-failing).

## Standing gotchas
- `op item edit … "credential[password]=$val"` prints a non-fatal `(404) Not Found` to stderr but the
  edit applies (confirm via a masked `op item get`, no `--reveal`). Use **item IDs**, not titles
  (`op item get <title>` emits a disambiguation hint).
- Verify a bearer non-echoing: `NEW=$(op read op://web-variables/<ID>/credential)`; `curl -s` to
  `127.0.0.1:<port>/mcp` with `Authorization: Bearer $NEW` (200) and a bogus token (401); `unset NEW`.
  Ports: mac-mcp 8765, github-mcp 8766, obsidian-mcp 8767 (OAuth). op-mcp origin `op-mcp.onrender.com`.
- **When dumping a file that may hold secrets, redact ALL value-shaped strings, not just `ops_`/`github_pat_`
  prefixes** — a narrow `sed` echoed `RUNNER_API_KEY` this session.
- `op-wrap.sh` requires the SA token UNQUOTED in `~/.zshrc`. [[op-wrap-token-unquoted]]
- `destructive-guard` + auto-mode block `rm`/`git branch -D` → owner-terminal-only.
- Kept identifiers (do NOT rename): `claude-kit-core`, `CLAUDE_KIT_REPO`, `claude-kit-op-mcp`.

## Commits (branch `chore/phase3b-bearer-rotations`)
`6936b2a` rotate MAC + symlink fix · `1f6e5aa` rotate GITHUB · `2510dd9` OP_MCP_BEARER [~] ·
`14dc290` OP_MCP_BEARER done · `8b4d56b` plist/obsidian hardening · `4d7a286` memory.

## Copy-paste primer (new session)
```
Resume the schnapp-os rebuild (repo SchnappAPI/schnapp-os, dir ~/code/schnapp-os). Phase 1 (SA rotation),
Phase 2 (rename), Phase 3A (secrets toolkit), and Phase 3B (the 3 MCP-bearer rotations) are all DONE.
Phase 3B is in branch chore/phase3b-bearer-rotations (open PR): MAC_MCP_AUTH_TOKEN, GITHUB_MCP_AUTH_TOKEN,
OP_MCP_BEARER rotated-on-migrate (fresh openssl, non-echoing) + Mac-verified (new bearer 200 / bogus 401;
op_health authenticated). Also fixed mid-rotation: deployed server.py symlinks repointed off the dead
~/code/claude-kit path; the clobbered macmcp launchd plist rewritten secrets-free (reboot-exposure fix);
the obsidian-mcp vestigial MAC_MCP_AUTH_TOKEN ref removed. Read first: handoffs/033-phase3b-bearer-rotations.md,
handoffs/032-…, memory/credentials-state.md, memory/credential-leak-2026-06-17.md, credentials-map.md.

OWNER-GATED (agent can't): merge the PR; set the two CLIENT bearers (claude.ai mac-mcp.schnapp.bet,
Copilot github-mcp) to the new op:// values; rm the plaintext .bak
(~/Library/LaunchAgents/com.schnapp.macmcp.plist.bak.20260524-105649); console-rotate the remaining leaked
values (GITHUB_PAT, Anthropic, Claude-OAuth, DB sa, Web App incl RUNNER_API_KEY, Webshare, Cloudflare);
git branch -D the [gone] branch after merge. Optional: validated macmcp reload.

NEXT after merge: the ~28-file obsidian-vault export leak scrub (separate repo; history-rewrite deferred);
promote check-op-refs.sh to BLOCK. Owner prefs: terse/caveman, parallelize, small skills, automate (do
don't tell), surface owner-only steps with what+where, NEVER echo a secret value. Mac MCP tools may return
unauthorized → drive vault/Mac work via local Bash (op is the SA 55TZ). op-wrap needs the SA token UNQUOTED.
```
