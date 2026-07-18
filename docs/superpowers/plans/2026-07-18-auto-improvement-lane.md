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
- [ ] observe-mode wrapper template (log would-block, exit 0) + escalation ledger
- [ ] self-escalation: >= 7 clean days -> flip wrapper to blocking, same-commit self-test
- [ ] tests: observe never blocks; escalation flips only on clean ledger

## Validation
- [ ] end-to-end dry-run: seeded fixture transcripts -> minted skill lands on a throwaway
      clone's main with catalog regenerated and gates green
