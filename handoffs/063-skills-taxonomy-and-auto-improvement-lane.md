# 063 - skills taxonomy cleanup + auto-improvement lane (ADR 0037)

Date: 2026-07-18. Two work streams in one session: the owner-directed skills taxonomy cleanup,
then the autonomous improvement lane the owner escalated to full no-approval autonomy mid-session.

## Stream 1 - skills taxonomy cleanup (commit 37c77c8)

Trigger-matrix pass over all 36 skills. Six collision classes de-overlapped to one routing home
each (token/401, subagent-audit verification, connector liveness, secret-leak, alert-path,
installer output); mutual partitions added for the decision trio (council/grill-me/intent-check),
state trio (surface-check/status/os-cross-surface-campaign), SQL pair, and capture trio
(learn-route/rules-distill/session-to-skill); when-NOT sections added where absent. No
load-bearing verified content touched. The debugging-playbook/failure-archaeology partition held.

## Stream 2 - auto-improvement lane (ADR 0037; commits 144bc5b..ed600b9)

Owner directive: "I want this to be automatic. I don't want to have to approve it." ADR 0037
records the tiered no-approval policy; all four phases of the plan doc
(docs/superpowers/plans/2026-07-18-auto-improvement-lane.md) are built and tested:

1. `scripts/transcript-mine.py` - deterministic fire-rate miner (skill/agent/hook counts per
   session, `--since` window). 7-day baseline: only 5 repo-skill fires, agents dominate; the
   os-* library essentially unfired (meta-work week; prune deliberately held for object-work data).
2. `scripts/session_mine.py` + `scripts/session-mine-worker.sh` - nightly bounded-SDK skill
   proposal (at most one mint/sharpen) with deterministic verification: every evidence quote must
   grep verbatim in its named transcript (>= 2 distinct sessions) and quoted trigger phrases must
   collide with no other skill; catalog projections regenerate in the same commit; reuses
   `learning-gate.sh` with a skills scope. Zero-fire auto-prune across two snapshot windows.
   LaunchAgent `com.schnapp.session-mine` armed, nightly 03:40.
3. Hook lane: `hooks/auto/` drop-in dir + `auto-dispatch.sh` (single settings.json entry) +
   `auto-hook-lib.sh` (observe = ledger + exit 0, enforce = exit 2) +
   `scripts/auto-hook-escalate.sh` (observe -> enforce after 7 days with no open `auto-hook-fp`
   issue; fail-closed when gh unreadable). Contract: hooks/auto/README.md.

Self-tests for all three lanes are in freshness.yml (transcript-mine, session-mine-worker,
auto-hook-lane). Escalator gotcha fixed during build: `git log --follow` traced a new hook to an
older sibling's add-commit when contents were similar - the age check uses no `--follow`.

## Open items

- First LIVE nightly session-mine run: 2026-07-19 03:40. Its ops-alert issue (green/red,
  component `session-mine`) is the end-to-end validation evidence. Check it.
- First real auto-hook mint: the lane's job (needs a >= 2-occurrence mistake class), not manual.
- Meta-freeze skill prune: still owner-planned, still blocked on object-work usage data;
  the nightly snapshots in `scheduled-tasks/.mining-history/` are accumulating the evidence.
- Auto-dispatch hook goes live in each session at its next SessionStart (hooks reload then).

## Gotchas for the next session

- One mid-stream CI red (38e69a6, stale CATALOG pushed before regen; fixed in ed600b9): any
  commit adding a cataloged script must run gen-catalog.sh BEFORE push, not after freshness
  flags it locally.
- session-mine-worker runs the escalator on the CLEAN tree before the proposal step - keep that
  ordering; running it after the proposal commit would push ungated work.
