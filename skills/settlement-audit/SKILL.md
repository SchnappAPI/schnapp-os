---
name: settlement-audit
description: Use to independently audit schnapp-bet's NBA prop grading/settlement - re-derive Won/Lost from the final boxscore stat vs the stored line_value, cross-check ev_pct/implied_prob against the stored over_price, and assert the keep-closest-to-tipoff dedup left exactly one grade row per key. Reports every mismatch instead of trusting grade_props.py's own output. Read-only against common.daily_grades + nba boxscore tables via the mac-mcp sql_query tool. NBA-first (MLB/NFL deferred).
---

# settlement-audit

Independent re-derivation of schnapp-bet's bet grades. The settlement/dedup path is a
twice-mis-fixed regression, and nothing re-derives the grade independently: settlement is a
single SQL WHEN-ladder inside `run_outcomes` in `~/code/schnapp-bet/grading/grade_props.py`
that trusts itself. The adjacent guards do not cover it (`shared/integrity.py` is ingest-side
only; `grading/verify_tier_rows.py` is a one-shot printer, no diff, no assertion).

## The four anchors (re-confirm against the grader before trusting a run)

Everything here is a projection of `grade_props.py`. If the audit and the grader disagree on a
definition, they silently pass bad grades. Anchors are function/symbol names, not line
numbers; locate each by search:

| What | Grader source of truth (search anchor) |
|---|---|
| Settle-able markets + stat expression | the `market_groups` mapping inside `run_outcomes`; mirrors `MARKET_STAT_MAP` |
| Outcome ladder | the `CASE ... WHEN` outcome ladder inside `run_outcomes` |
| Dedup key + keep-rule | the post-upsert `PARTITION BY` dedup in the grader's upsert path, and `cleanup_stale_odds_and_grades.py` |
| EV chain (implied_prob, ev_pct) | the EV block where `implied_prob`/`ev_pct` are computed from `over_price`; scope gated by `LOGISTIC_MARKET_GROUP_MAP` |

## The contract (what the audit asserts)

- **Settlement**: 20 markets settle (points/rebounds/assists/threes/blocks/steals + the
  PRA/PR/PA/RA combos, each with `_alternate`); stat is the per-game `SUM` from
  `nba.player_box_score_stats`, gated on `nba.schedule.game_status = 3` (final).
  `player_double_double`, `player_triple_double`, `player_first_basket` legitimately stay
  `outcome = NULL` - do not flag them.
- **Ladder, no Push**: Over `stat >= line` Won, `stat < line` Lost; Under `stat <= line` Won,
  `stat > line` Lost; else NULL. Ties resolve to Won on both sides; the grader never writes
  `Push`.
- **Dedup**: exactly one row per **7-column** key (`grade_date, event_id, player_id,
  market_key, bookmaker_key, line_value, outcome_name`), keep max `grade_id`. Asserting on 5
  columns raises false positives (one legitimate row per book and per grade_date).
- **EV chain**: from stored `over_price` (American odds), `implied_prob = 100/(price+100)` for
  positive, `|price|/(|price|+100)` for negative; `ev_pct = (model_prob * payout -
  (1 - model_prob)) * 100` with payout the profit multiple. `model_prob` is trusted as stored,
  never re-derived.

## Running the audit (read-only, mac-mcp sql_query)

Run each file in [`queries/`](queries/); **rows returned = violations, empty = pass** (except
the diagnostic). Report every row; never summarize a mismatch away.

| File | Checks |
|---|---|
| [`queries/settlement-rederivation.sql`](queries/settlement-rederivation.sql) | stored outcome vs re-derived (misgraded / ungraded_but_final) |
| [`queries/dedup-uniqueness.sql`](queries/dedup-uniqueness.sql) | 7-column key uniqueness |
| [`queries/ev-chain-crosscheck.sql`](queries/ev-chain-crosscheck.sql) | implied_prob / ev_pct arithmetic vs over_price |
| [`queries/cross-book-count-diagnostic.sql`](queries/cross-book-count-diagnostic.sql) | diagnostic only: distinct books per prop (count > 1 is normal) |

## Scope and drift

- **NBA-first.** Add MLB / NFL only after the NBA re-derivation is confirmed against real
  settled data - their stat tables and market sets differ.
- **Re-pull on grader change.** If `grade_props.py` changes the `run_outcomes` market_groups,
  the outcome ladder, the dedup partition, or the EV block, update the matching query file and
  this contract in the same pass - a diff there means the audit is testing an old definition.
