# Handoff 038 — Mac access restored (network allowlist), sessions reconciled, web→main

**Date:** 2026-06-29. **Supersedes the open items of:** handoff 037. **State:** Mac autonomy is
UNBLOCKED for real (037 open #1 closed), all 14 stray session branches reconciled + deleted (037 open
#4 closed), and web sessions are now policy-bound to `main` (ADR 0017). Two 037 items remain
(LaunchAgent reinstall + worker e2e) and one new production risk surfaced (stale SQL backups).

## What changed this session
- **Mac access restored — and 037's theory was wrong.** 037 open #1 guessed the `unauthorized` was a
  duplicate UI connector shadowing `.mcp.json`. The REAL blocker: the cloud environment's
  **network-policy allowlist** did not include `mac-mcp.schnapp.bet`, so the agent proxy returned
  **403 on CONNECT** and `Schnapp_Mac` never connected. Owner added the host to allowed domains →
  403→reachable; `mac_info` + `site_health` returned live. Recorded as memory [[mac-cloud-access]].
  Access path confirmed: `.mcp.json` project server `Schnapp_Mac` + `Authorization: Bearer
  ${MAC_MCP_AUTH_TOKEN}` (env, len 64). **No claude.ai UI connector needed** — removing it does not cut access.
- **All 14 stray branches reconciled + deleted (037 open #4 closed).** Analyzed every branch tip-vs-`main`:
  12 fully merged, 2 (`compassionate-brown`, `self-edit/…-record-failed-approaches`) carried only
  already-landed or deliberately-retired (`self-edit-stage.sh`) content — **zero lost work**. Deleted
  all 14 on the Mac (`git push origin --delete`; the cloud env's git proxy 403s pushes). Remote is now
  **`main` only**; 0 open PRs.
- **Web sessions → `main` (ADR 0017).** Root cause of the branch litter: web sessions defaulted to a
  per-session `claude/*` branch and died without merging. Policy now: web sessions commit to `main`
  like every other surface. **Owner step:** set the web environment/trigger working branch to `main`
  (UI knob, not a repo file). Backstop wired below.
- **Auto-reconcile wired (PLAN 11.1).** `scheduled-tasks/run-ci-routines.sh` Routine 2 now surfaces
  ALL non-`main` branches, classified **unmerged** (review) vs **merged residue** (safe to delete) —
  not just unmerged. Spec updated (`sync-unmerged-check.md`). Read-only; never deletes.

## Decisions / records this session (all on main)
- **ADR 0017** — web sessions target `main` directly (refines 0016; backstopped by the sync routine).
- Memory **[[mac-cloud-access]]** (new) — the allowlist gate; corrects 037 #1.
- `owner-working-preferences.md` #7 refreshed — main-only every surface incl. web; self-edits use the
  pre-commit gate (0016), not a branch.

## OPEN — next session, in order
1. **Investigate stale SQL backups (NEW — production risk).** `backup_status` 2026-06-29: most recent
   `.bacpac` is **55 days old** (2026-05-03), `backup_current: false`, `next_scheduled_fire: null` —
   the weekly backup is NOT firing. Check the `bet.schnapp.bacpac-backup` LaunchAgent (loaded? plist
   present? script erroring?). Mutation (running a backup / fixing the schedule) is **asks-first** per
   `scheduled-tasks/README.md` — diagnose read-only, then queue the fix.
2. **Re-install the learning-worker LaunchAgent** (037 open #2; still open). WatchPaths + full-capability
   + `ANTHROPIC_API_KEY` ref. Steps in `scheduled-tasks/README.md`. Owner-confirmed, production-Mac-only.
3. **Verify the worker's live `claude -p` path end-to-end** (037 open #3; still open; only gate + dry-run
   are CI-tested). Seed a real correction → confirm a clean rule commits to `main` OR opens a review issue.
4. **Refresh stale memory** flagged at session start: `keep-tracker-current.md` (25d), `obsidian-state.md`
   (12d) — supersede-not-append.

## Key facts / locations
- **Mac access:** memory [[mac-cloud-access]]; `decisions/0014`. Allowlist must include
  `mac-mcp.schnapp.bet`; `MAC_MCP_AUTH_TOKEN` in env.
- **Branch policy:** ADR 0016 (no branches) + **ADR 0017** (web→main). Cloud env CANNOT push/delete
  (git proxy 403); do branch deletes on the Mac.
- **Reconcile routine:** `scheduled-tasks/run-ci-routines.sh` Routine 2; spec `sync-unmerged-check.md`.
- **Conventions unchanged:** commit straight to `main` (no branches), standing authority (ADR 0015),
  concise/actionable replies, current-state-only docs (`owner-working-preferences.md`).

## DONE + verified this session
- Mac MCP reachable (403→200; `mac_info`, `site_health: all_ok`, `backup_status` live).
- 14 stray branches deleted; remote = `main` only; 0 open PRs.
- Freshness gate green locally with these changes; CATALOG unaffected (no rule/skill/command/hook added).
