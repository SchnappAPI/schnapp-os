# Auto-improvement lane (ADR 0037)

Transcript mining -> frequent-pattern detection -> autonomous fix landing, tiered per
[decisions/0037](../../../decisions/0037-auto-improvement-lane.md). Status of each box:
PROGRESS.md is the log; this is the live tracker.

## Phase 1 - deterministic miner
- [x] `scripts/transcript-mine.py`: fire-rate table (skills / agents / hooks) from
      `~/.claude/projects/**/*.jsonl`, `--since` window, TSV out
- [x] self-test `scripts/tests/test-transcript-mine.sh` (fixture JSONL, expected counts)
- [x] ADR 0037 recorded

## Phase 2 - mining agent pass
- [x] `scripts/session_mine.py`: bounded Agent SDK proposal (miner TSV + transcript corpus in,
      at most one skill mint/sharpen + evidence JSON out; no Bash, bounded turns/timeout)
- [x] own nightly lane `scripts/session-mine-worker.sh` + `com.schnapp.session-mine.plist`
      (03:40; separate from the correction-queue worker, same auth + clean-tree discipline)

## Phase 3 - gate extension (tier 2 auto-mint)
- [x] gate reuse: `learning-gate.sh` called with scope `skills/*/SKILL.md|CATALOG.md|surfaces/
      claude-ai-skills.md` + `LEARNING_GATE_MAX_ADDED=150` (no gate edit needed); worker adds
      the two skill-specific checks first: every evidence quote greps verbatim in its named
      transcript (>= 2 distinct sessions), quoted trigger phrases collide with no other skill
- [x] auto-prune: zero fires across two consecutive snapshots + dir predates the older one ->
      `git rm` + regen in the same gated commit
- [x] tests: `scripts/tests/test-session-mine-worker.sh` (evidence good/fabricated/single,
      collision hit/miss, dry-run e2e) wired into freshness.yml

## Phase 4 - hook observe lane (tier 3)
- [x] lane mechanics: `hooks/auto/` drop-in dir + `hooks/auto-dispatch.sh` (one settings.json
      entry, PostToolUse Write|Edit) + `hooks/auto-hook-lib.sh` (observe = ledger line + exit 0,
      enforce = exit 2); contract + FP-brake procedure in `hooks/auto/README.md`
- [x] self-escalation: `scripts/auto-hook-escalate.sh` (>= 7 days old, no open `auto-hook-fp`
      issue -> flip to enforce, commit+push; gh unreadable = fail-closed hold), run nightly by
      the session-mine worker on the clean tree
- [x] tests: `scripts/tests/test-auto-hook-lane.sh` (observe never blocks + ledger written,
      enforce blocks via dispatcher, erroring hook ignored, escalator age gate) in freshness.yml
- [ ] first real auto-hook minted through the lane (needs a >= 2-occurrence mistake class from
      live data; the mint itself is the lane's job, not a manual step)

## Validation
- [~] lane dry-runs verified (session-mine worker + escalator fixtures); first LIVE nightly run
      2026-07-19 03:40 is the end-to-end check - its ops-alert issue is the evidence
