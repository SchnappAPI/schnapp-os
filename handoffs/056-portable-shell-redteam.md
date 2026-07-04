# Handoff 056: Portable shell red-teamed - hardened, faster, two guard holes closed

Date: 2026-07-03. Surface: Claude Code (Mac). Prior: [055](055-portable-shell.md).

## Goal
/critique-os red-team of the portable shell + whole system (dimensions: failure modes,
security, context cost, staleness, verification debt, simplification). Rule in force: verify
LIVE before flagging; fix or subtract in-session; no re-litigating settled decisions without
new evidence. No settled decision was reopened, so no new ADR.

## Findings -> actions (ranked by impact; all fixes committed 13430c1 + vault 00ec466/f17b757)
1. **Bash-written files were unscanned machine-wide** (verified: PostToolUse matcher is
   Write|Edit|MultiEdit only; a heredoc/echo secret never met a hook). FIXED:
   `global-secret-scan.sh` gained a PreToolUse Bash leg scanning command TEXT before
   execution; fast path = new `scan-secrets.sh --block-re` (registry emits its own
   alternation, zero pattern copies); no-hit cost 0.09s measured; never self-skips.
2. **The vault chokepoint had ZERO secret scanning** (pre-commit = schema+flatten only; no CI
   scan; the lane pushes to GitHub within minutes). FIXED: vault pre-commit now scans staged
   files (memory/ pre-verified 0 BLOCK; the 120 legacy BLOCKs are all `Claude Export/`,
   accepted-risk envelope - fact updated: plaintext lives in BOTH private repos). Plus:
   `install.sh` now sets vault `core.hooksPath` - a fresh clone committed UNGATED (Mac had
   it only from a manual bootstrap).
3. **SessionEnd failures were invisible** (the session is over; a pre-commit rejection left
   the tree dirty silently; only Mac launchd would retry). FIXED: the gate now surfaces
   vault BACKLOG (dirty/unpushed counts) at the next session start in ANY repo.
4. **Gate latency**: 4.4s measured on every session start. FIXED: parallel pulls -> 2.7s.
   Considered and REJECTED a fetch debounce: it trades the live-freshness guarantee (the
   design's core value) for ~2s. Matcher widened to `startup|resume|clear` (a resumed/cleared
   session sat on stale clones + lost the orient line); installer migrates old wiring in
   place, ours-only groups.
5. **Vault push race** (two SessionEnds): race-tested in a scratch clone - winner sweeps all
   (`git add -A`), no data loss, but the loser misdiagnosed as "pre-commit gate?" exit 2.
   FIXED: index.lock/nothing-to-commit reclassified benign exit 0. Installer settings write
   made atomic (concurrent drift auto-heal safety).
6. **Wiring drift window**: gate detected drift but instructed instead of acting. FIXED:
   auto-runs the idempotent installer (owner rule: automate).
7. **Force-push guard probed with 13 bypass shapes**: blocks all accidental shapes (incl.
   sh -c, env-prefix, alias-definition, script text in printf). Bypasses need deliberate
   obfuscation (base64, var-assembled flags, `pu''sh`) - no regex hook stops that; threat
   model is accidents. KEEP unchanged.
8. **Subtracted**: `hooks/hooks.json` (tombstone; history lives in 0011/0024), 2 orphan
   `.claude/worktrees/` + branches, 2 empty remote `claude/*` branches (main-only).
9. **Docs**: web env-var VALUES exception now documented (environment-and-access.md §1:
   bootstrap credentials cannot self-resolve; rotation includes those fields).

## Resolved questions
- **Duplicate skills (project + user scope)**: RESOLVED - the harness dedupes same-name
  skills; this interactive schnapp-os session listed each exactly once. No action.
- **Context cost (audited, numbers)**: shell footprint ~6.1k tok/session = rules 3,130 (52%,
  `working-style.md` alone 1,190) + skills metadata 2,220 (26 skills, ~85 avg) + agents 480 +
  commands 190. Curation split (move settlement-audit, betting-grading-reviewer, appfolio,
  quickbase, etl/sql/throughput items to work-repo scope) saves ~820-1,100 tok/session.
  DEFERRED: 0033 accepted the cost; ~0.5% of a 200k window does not yet pay for per-repo
  wiring. The single biggest lever is a `working-style.md` diet - owner-voice file, owner call.

## Open items (owner)
1. **Web env paste** (unchanged from 055, the only remaining T5 leg): paste
   `shell/web-setup.sh` into each web environment's setup script; first web session answers
   ADR 0033 fact 5 - a `[shell]` line = user scope honored; none = documented boundary stands.
   Not testable from a Mac session; needs a real web container.
2. **Other machines**: clone both repos + run `shell/install.sh` (now also sets vault
   hooksPath, migrates matchers, wires the Bash-leg scan).

## Copy-paste primer (new session)
Portable shell LIVE + red-teamed (ADR 0033; plan 2026-07-03-portable-shell T1-T4+T6 done, T5
web leg = owner paste). Gate: parallel pulls 2.7s, startup|resume|clear, drift auto-heal,
vault-backlog surfacing. Guards: secret scan covers Write/Edit files AND Bash command text
machine-wide; vault pre-commit scans staged files; installer sets vault hooksPath. Vault push
race benign. Resume point = this handoff.
