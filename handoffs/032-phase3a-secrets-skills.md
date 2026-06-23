# Handoff 032 — Phase 3A: secrets skills + secret-scan CI (toolkit built; rotations next)

Date: 2026-06-23. Surface: Claude Code (Mac). Status: **Phase 3 part A DONE** (delivered in PR #7,
CI green, awaiting owner merge). Next = Phase 3 part B (rotations + leak scrub — mostly owner-gated).
Canonical plan: `~/.claude/plans/i-am-not-sure-fancy-garden.md` §Phase 3. Prior: `handoffs/031-…`.

## What got done this session (PR #7 — open, green)
- **3 secrets skills** (`plugins/core/skills/`, auto-discover via `claude-kit-core`):
  - `vault-resolve` — resolve `op://` per surface (Mac `op` / op-mcp MCP / GH Actions); field-label
    gotcha (`GITHUB_PAT`→`/token`); non-echoing reads (`op run` / `op inject` / `$(op read)`).
  - `cleanse-secrets` — report + redact modes wrapping the scanner; non-echoing redact; the
    obsidian-vault leak-scrub procedure.
  - `rotate-secret` — rotate-on-migrate protocol: `consumed_by` → mint (self-serve vs owner console)
    → non-echoing store → propagate every leg → restart/redeploy → verify → changelog.
- **Single-source scanner** `plugins/core/scripts/scan-secrets.sh` (one pattern set, two consumers:
  CI + `cleanse-secrets`). Catches the classes the reused `opensource-sanitizer` lib MISSED —
  `ops_` (master SA token) + `sk-ant-*` — as first-class BLOCK rules. Masks values, skips `op://`
  pointers, exits non-zero on BLOCK. Proven by `scripts/tests/{secret-fixtures.txt,test-scan-secrets.sh}`.
- `plugins/core/scripts/check-op-refs.sh` — flags `op://` refs whose item is absent from
  `credentials-map.md` (WARN-only for now).
- **CI**: `freshness.yml` +3 steps (scanner self-test; secret scan over tracked files, fixtures
  excluded; op:// ref check). **Repo scans 0 BLOCK** (no leaked value tracked in schnapp-os). Both
  push + PR runs **success**.
- **`.gitignore` class-fix** (a real bug found while committing): the broad `**/*secret*` ignore
  silently dropped every toolkit file named "secret" (scan-secrets.sh, both skills, fixtures) — the
  same pattern that once dropped the always-loaded `secrets-as-references.md` (patched per-file then).
  Replaced name-match with content-shape patterns (`*secret*.json`, `.secrets/`, `*.key`, `*.pem`,
  `.env`); the value guard is now `scan-secrets.sh` in CI, regardless of filename. **Net security:
  stronger** (blocks actual values, not just suspicious names). Worth an owner glance in the PR.
- Verified via read-only skill-reviewer gap-test; fixed all example commands to be **non-echoing by
  construction** (the original read/store/redact examples could have echoed a value to the transcript).

## In-flight carry — VERIFIED this session
- Vault items `MAC_MCP_AUTH_TOKEN` + `GITHUB_MCP_AUTH_TOKEN` **exist** (created earlier; still hold the
  LEAKED bearer values → rotate in part B).
- 6 connector `.env.template` files **repointed + committed** (tree clean): mac/github/obsidian-mcp
  point at the new item names; op-mcp holds the bootstrap fields. No uncommitted carry remains.
- `op` works via local Bash (SA `55TZ`); Mac MCP tools still `unauthorized` (the connector bearer).

## OWNER-GATED — open items (agent cannot; what + where)
1. **Merge PR #7** (or tell me to): https://github.com/SchnappAPI/schnapp-os/pull/7 — CI green.
   Glance at the `.gitignore` change (security policy) before merging.
2. **Mac MCP connector bearer** stale in the **Claude account** (server/env/vault all = `…6267`;
   only the account-side config is stale). claude.ai → Settings → Connectors → `mac-mcp.schnapp.bet`
   → Authorization Bearer = current `op://web-variables/MAC_MCP_AUTH_TOKEN/credential` (`…6267`) — OR
   the Cloudflare One MCP portal entry. (Part B can rotate this bearer fresh in the same motion —
   see below.) Not fixable from the Mac.
3. **Orphaned plugin cache** `~/.claude/plugins/cache/claude-kit/` — `rm -rf` blocked by
   destructive-guard + auto-mode. Run in a plain terminal: `rm -rf ~/.claude/plugins/cache/claude-kit`.
4. **Stale `[gone]` branches**: `chore/phase1-sa-rotation-record`, `chore/rename-to-schnapp-os` were
   NOT present in this clone (already deleted or never local). `chore/handoff-031` (merged #6) and,
   after #7 merges, `chore/phase3-secrets-skills` will be `[gone]` — `git branch -D` them in a plain
   terminal (same guard blocks `/clean-gone`).

## NEXT = Phase 3 part B (rotations + scrub) — drive with the new `rotate-secret` skill
1. **Rotate the remaining leaked values** (rotate-on-migrate, fresh values), one item at a time per
   the skill's protocol. Self-serve mint (`openssl`, this Bash): `MAC_MCP_AUTH_TOKEN`,
   `GITHUB_MCP_AUTH_TOKEN`, `OP_MCP_BEARER` — BUT propagation legs (Render env+redeploy, Cloudflare
   portal, claude.ai connector) are owner. **Smart move: rotate `MAC_MCP_AUTH_TOKEN` fresh and have
   owner set the new value in claude.ai in one motion → kills the leak AND fixes open item #2.**
   Owner-console mint: `GITHUB_PAT` (+held-back `GITHUB_PAT_ADMIN`), Anthropic key, Claude OAuth,
   DB `sa`, Web App secrets, Webshare, Cloudflare. Leak record: `memory/credential-leak-2026-06-17.md`.
2. **Leak scrub** of the ~28 `obsidian-vault` export files: `cleanse-secrets` report→redact→re-scan
   to 0 BLOCK (keep conversations, strip values). **Separate repo** (commit there). History-rewrite
   decision still DEFERRED until after rotation (then leaked history holds dead values).
3. **After rotations**: regenerate `credentials-map.md` + append changelog rows; promote
   `check-op-refs.sh` to BLOCK once stable; consider tightening the `assignment-secret` WARN heuristic
   (10 prose false-positives today, non-failing).

## Standing gotchas
- `op-wrap.sh` greps `~/.zshrc` → SA token line MUST be **unquoted**. [[op-wrap-token-unquoted]]
- After any SA/bearer rotation: restart launchd services + re-run `com.schnapp.environment` + Render
  redeploy. [[credentials-state]]
- Mac MCP tools (`ec6a9080…`) return `unauthorized` → drive Mac/vault work via **local Bash** (`op`).
- `destructive-guard` + auto-mode block `rm -rf` and `git branch -D` → those are owner-terminal-only.
- **`.gitignore` is now content-shape based, not name-based** — a file named `*secret*` is tracked;
  `scan-secrets.sh` (CI) is what keeps values out. Don't re-broaden to `**/*secret*`.
- Kept identifiers (do NOT rename): `claude-kit-core`, `CLAUDE_KIT_REPO`, `claude-kit-op-mcp`.

## Copy-paste primer (new session)
```
Resume the schnapp-os single-source rebuild (repo SchnappAPI/schnapp-os, dir ~/code/schnapp-os).
Phase 1 (SA rotation) + Phase 2 (rename) DONE+merged. Phase 3 part A (secrets toolkit) DONE in PR #7
(open, CI green): built skills vault-resolve / cleanse-secrets / rotate-secret + single-source
scan-secrets.sh + secret-scan CI in freshness.yml + a .gitignore class-fix (name-match → content-shape;
scan-secrets is now the value guard). Read first: handoffs/032-phase3a-secrets-skills.md,
handoffs/031-…, ~/.claude/plans/i-am-not-sure-fancy-garden.md, memory/credentials-state.md,
memory/credential-leak-2026-06-17.md, memory/owner-working-preferences.md.

OWNER-GATED (agent can't): merge PR #7; set claude.ai Mac-MCP connector bearer (mac-mcp.schnapp.bet)
= op://web-variables/MAC_MCP_AUTH_TOKEN/credential (…6267); `rm -rf ~/.claude/plugins/cache/claude-kit`;
`git branch -D` the [gone] branches — all in a plain terminal (destructive-guard + auto-mode block me).

NEXT = Phase 3 part B: drive rotations with the new rotate-secret skill (rotate-on-migrate the leaked
values; self-serve openssl bearers MAC_MCP_AUTH_TOKEN/GITHUB_MCP_AUTH_TOKEN/OP_MCP_BEARER — rotate
MAC_MCP_AUTH_TOKEN in the same motion as fixing the claude.ai bearer; owner consoles for GITHUB_PAT/
Anthropic/Claude-OAuth/DB sa/Web App/Webshare/Cloudflare). Then cleanse-secrets the ~28 obsidian-vault
export files (separate repo; history-rewrite deferred). Then regen credentials-map + changelog; promote
check-op-refs to BLOCK. Owner prefs: terse/caveman, parallelize, small skills, automate (do don't tell),
surface owner-only steps with what+where, NEVER echo a secret value. Mac MCP unauthorized → local Bash.
```
