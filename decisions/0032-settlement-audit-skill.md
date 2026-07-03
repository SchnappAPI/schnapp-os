# 0032 - settlement-audit skill: independent re-derivation, definitions pulled from the grader

Date: 2026-07-03. Status: DECIDED by owner.

## Context
schnapp-bet's NBA prop settlement is a twice-mis-fixed regression. Nothing re-derives a grade
independently: `run_outcomes` (`grade_props.py:3054-3062`) is a single SQL WHEN-ladder that trusts
itself, and `cleanup_stale_odds_and_grades.py:17-19` documents its own prior failed fix (the dropped
`is_standard` column + `uq_daily_grades_standard` index). The two adjacent guards do not cover
settlement value: `shared/integrity.py` is ingest-side only (write-time NULL/required invariants) and
`grading/verify_tier_rows.py` is a one-shot printer (top rows + coverage counts, no diff, no
assertion). The owner asked for an independent auditor that reports mismatches instead of trusting the
grader's own output.

## Decision
Add `.claude/skills/settlement-audit/SKILL.md`: three read-only SQL checks run via the mac-mcp
`sql_query` tool against `common.daily_grades` + the NBA boxscore/schedule tables.
1. **Settlement re-derivation** - re-derive Won/Lost from the final boxscore stat vs stored
   `line_value`, per market.
2. **Dedup uniqueness** - assert exactly one grade row per key.
3. **EV chain** - re-derive `implied_prob` / `ev_pct` from stored `model_prob` + `over_price`.

All definitions (stat->line mapping, outcome ladder, dedup key, EV formula) are **pulled verbatim from
`grade_props.py`**, not re-invented, so the audit and grader cannot silently disagree.

Two places the task's brief diverged from the grader's actual code were resolved by matching the code
(owner-confirmed 2026-07-03):
- **No Push.** The grader writes only Won/Lost/NULL; Over uses `>=`, Under uses `<=`, so ties resolve
  to Won. The audit re-derives with the identical ladder and does not invent a Push outcome.
- **Dedup key is 7 columns**, not 5: `grade_date, event_id, player_id, market_key, bookmaker_key,
  line_value, outcome_name` (keep max `grade_id`). Asserting on the 5-column subset would false-positive
  on legitimate per-book and per-date rows. The 5-column cross-book collapse is kept as a separate
  informational diagnostic, not a failure.

`model_prob` itself is a logistic output (needs `common.grade_weights` + the full feature vector) and
is **not** re-derived; the audit treats it as the grader's stored output and checks only the arithmetic
chain model_prob -> implied_prob / ev_pct -> over_price.

## Scope
NBA-first, matching where the bug recurred and where `integrity.py` +
`cleanup_stale_odds_and_grades.py` are scoped. MLB / NFL are deferred until the NBA re-derivation is
confirmed against real settled data.

## Consequences
- The skill is a projection of `grade_props.py`. If the grader changes the market_groups/ladder
  (`:3037-3062`), the dedup partition (`:2443-2448`), or the EV block (`:2669-2677`), the skill's
  matching section must be updated in the same pass. The four anchors named in the skill are the
  contract.
- Read-only: the audit never writes. It surfaces `misgraded` rows (the defect) and
  `ungraded_but_final` rows (settlement lag/gap) separately.
