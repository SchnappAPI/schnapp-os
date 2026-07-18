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
- [ ] extend `scripts/learning_distill.py` (or sibling `session_mine.py`): read miner TSV +
      low-signal transcript remainder, emit skill/rule/memory candidates with >= 2-session
      evidence attached (same bounded Agent SDK harness: no Bash, bounded turns)
- [ ] wire into `learning-worker.sh` nightly after the recurrence pre-step

## Phase 3 - gate extension (tier 2 auto-mint)
- [ ] `learning-gate.sh`: admit `skills/*/SKILL.md` create/sharpen when evidence file present,
      size cap, no trigger-phrase collision vs catalog, projections regenerated same commit
- [ ] auto-prune: zero fires across two consecutive windows -> remove skill + regen (same gate)
- [ ] tests for both paths in `scripts/tests/`

## Phase 4 - hook observe lane (tier 3)
- [ ] observe-mode wrapper template (log would-block, exit 0) + escalation ledger
- [ ] self-escalation: >= 7 clean days -> flip wrapper to blocking, same-commit self-test
- [ ] tests: observe never blocks; escalation flips only on clean ledger

## Validation
- [ ] end-to-end dry-run: seeded fixture transcripts -> minted skill lands on a throwaway
      clone's main with catalog regenerated and gates green
