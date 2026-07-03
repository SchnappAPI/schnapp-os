---
name: settlement-audit
description: Use to independently audit schnapp-bet's NBA prop grading/settlement - re-derive Won/Lost from the final boxscore stat vs the stored line_value, cross-check ev_pct/implied_prob against the stored over_price, and assert the keep-closest-to-tipoff dedup left exactly one grade row per key. Reports every mismatch instead of trusting grade_props.py's own output. Read-only against common.daily_grades + nba boxscore tables via the mac-mcp sql_query tool. NBA-first (MLB/NFL deferred).
---

# settlement-audit

Independent re-derivation of schnapp-bet's bet grades. The settlement/dedup path is a
twice-mis-fixed regression (`~/code/schnapp-bet/etl/cleanup_stale_odds_and_grades.py:17-19`
documents its own prior failed fix: the dropped `is_standard` column + `uq_daily_grades_standard`
index) and **nothing re-derives the grade independently**: settlement is a single SQL WHEN-ladder
in `run_outcomes` (`~/code/schnapp-bet/grading/grade_props.py:3054-3062`) that trusts itself. The
two adjacent guards do not cover it:

- `~/code/schnapp-bet/shared/integrity.py` is ingest-side only (write-time NULL/required
  invariants, never a settlement value).
- `~/code/schnapp-bet/grading/verify_tier_rows.py` is a one-shot printer (top rows + coverage
  counts, no diff, no assertion).

This skill runs three read-only checks and reports every row that disagrees.

## Definitions are pulled from grade_props.py - do not re-invent

Everything below is a projection of `~/code/schnapp-bet/grading/grade_props.py`. If the audit and
the grader disagree on a definition, they silently pass bad grades. **Before trusting a run, confirm
the four anchors still match the grader** (re-read the cited lines):

| What | Grader source of truth |
|---|---|
| Settle-able markets + stat expression | `run_outcomes` market_groups `grade_props.py:3037-3049`; mirrors `MARKET_STAT_MAP` `:227` |
| Outcome ladder | `grade_props.py:3054-3062` |
| Dedup key + keep-rule | grader upsert `grade_props.py:2443-2448`; cleanup `cleanup_stale_odds_and_grades.py:237-243` |
| EV chain (implied_prob, ev_pct) | `grade_props.py:2669-2677`; logistic scope `LOGISTIC_MARKET_GROUP_MAP :84` |

### 1. Settle-able markets and stat->line

`run_outcomes` settles exactly these 20 markets. The actual stat is a per-game aggregate from
`nba.player_box_score_stats` (`GROUP BY player_id, game_id`, `grade_props.py:3065-3069`), gated on
the game being final: `nba.schedule.game_status = 3` (`:3025`, `:3074`).

| market_key (and `_alternate`) | stat | box columns |
|---|---|---|
| player_points | pts | `SUM(pts)` |
| player_rebounds | reb | `SUM(reb)` |
| player_assists | ast | `SUM(ast)` |
| player_threes | fg3m | `SUM(fg3m)` |
| player_blocks | blk | `SUM(blk)` |
| player_steals | stl | `SUM(stl)` |
| player_points_rebounds_assists | pra | `SUM(pts)+SUM(reb)+SUM(ast)` |
| player_points_rebounds | pr | `SUM(pts)+SUM(reb)` |
| player_points_assists | pa | `SUM(pts)+SUM(ast)` |
| player_rebounds_assists | ra | `SUM(reb)+SUM(ast)` |

`player_double_double`, `player_triple_double`, `player_first_basket` are in `STANDARD_MARKETS` but
NOT in `run_outcomes` - they legitimately stay `outcome = NULL`. Do not flag them.

### 2. Outcome ladder - there is no Push

`grade_props.py:3056-3062`. Ties resolve to `Won` (Over uses `>=`, Under uses `<=`). The grader
writes only `Won` / `Lost` / `NULL` - **it never writes `Push`.** The audit re-derives with the
identical ladder:

```
Over  and stat >= line -> Won
Over  and stat <  line -> Lost
Under and stat <= line -> Won
Under and stat >  line -> Lost
else                   -> NULL
```

### 3. Dedup key is 7 columns (keep max grade_id)

Both the grader's post-upsert dedup and the cleanup script partition on the **7-column** key and
keep the highest `grade_id` (latest write ~ closest to tipoff):

```
grade_date, event_id, player_id, market_key, bookmaker_key, line_value, outcome_name
ORDER BY grade_id DESC  ->  keep rn = 1
```

The 5-column phrasing (`event_id, market_key, player_id, line_value, outcome_name`) omits
`grade_date` and `bookmaker_key`; asserting on 5 columns raises false positives (one legitimate row
per book, and per grade_date, would look like a duplicate). Assert on 7. A cross-book count is a
separate diagnostic (Query B2), not a dedup failure.

### 4. EV chain

`grade_props.py:2669-2677`. Populated only for markets in `LOGISTIC_MARKET_GROUP_MAP` with weights
present; NULL elsewhere is expected. From the stored `over_price` (American odds):

```
implied_prob = price >= 0 ?  100 / (price + 100)      :  |price| / (|price| + 100)
payout       = price >= 0 ?  price / 100              :  100 / |price|
ev_pct       = (model_prob * payout - (1 - model_prob)) * 100
```

`model_prob` is a logistic output (`expit(features . coef + intercept)`, needs `common.grade_weights`
+ the full feature vector). The audit does **not** re-derive `model_prob`; it treats it as the
grader's stored model output and checks only the arithmetic chain model_prob -> implied_prob / ev_pct
-> over_price. Only rows with all four fields non-NULL are checked.

## Running the audit (read-only, mac-mcp sql_query)

All three are `SELECT`-only. Run each via the `mac-mcp sql_query` tool. **Rows returned = violations;
empty result = pass.** Report every row; never summarize a mismatch away.

### Query A - settlement re-derivation

```sql
WITH box AS (
    SELECT b.player_id, b.game_id,
           SUM(b.pts) AS pts, SUM(b.reb) AS reb, SUM(b.ast) AS ast,
           SUM(b.fg3m) AS fg3m, SUM(b.blk) AS blk, SUM(b.stl) AS stl
    FROM nba.player_box_score_stats b
    GROUP BY b.player_id, b.game_id
),
graded AS (
    SELECT dg.grade_id, dg.grade_date, dg.player_id, dg.game_id,
           dg.market_key, dg.outcome_name, dg.line_value,
           dg.outcome AS stored_outcome,
           CAST(CASE dg.market_key
             WHEN 'player_points'                            THEN box.pts
             WHEN 'player_points_alternate'                  THEN box.pts
             WHEN 'player_rebounds'                          THEN box.reb
             WHEN 'player_rebounds_alternate'                THEN box.reb
             WHEN 'player_assists'                           THEN box.ast
             WHEN 'player_assists_alternate'                 THEN box.ast
             WHEN 'player_threes'                            THEN box.fg3m
             WHEN 'player_threes_alternate'                  THEN box.fg3m
             WHEN 'player_blocks'                            THEN box.blk
             WHEN 'player_blocks_alternate'                  THEN box.blk
             WHEN 'player_steals'                            THEN box.stl
             WHEN 'player_steals_alternate'                  THEN box.stl
             WHEN 'player_points_rebounds_assists'           THEN box.pts + box.reb + box.ast
             WHEN 'player_points_rebounds_assists_alternate' THEN box.pts + box.reb + box.ast
             WHEN 'player_points_rebounds'                   THEN box.pts + box.reb
             WHEN 'player_points_rebounds_alternate'         THEN box.pts + box.reb
             WHEN 'player_points_assists'                    THEN box.pts + box.ast
             WHEN 'player_points_assists_alternate'          THEN box.pts + box.ast
             WHEN 'player_rebounds_assists'                  THEN box.reb + box.ast
             WHEN 'player_rebounds_assists_alternate'        THEN box.reb + box.ast
           END AS FLOAT) AS stat_val
    FROM common.daily_grades dg
    JOIN nba.schedule s
      ON s.game_id = dg.game_id AND s.game_status = 3
    JOIN box
      ON box.player_id = dg.player_id AND box.game_id = dg.game_id
    WHERE dg.player_id IS NOT NULL
      AND dg.game_id   IS NOT NULL
      AND dg.market_key IN (
        'player_points','player_points_alternate',
        'player_rebounds','player_rebounds_alternate',
        'player_assists','player_assists_alternate',
        'player_threes','player_threes_alternate',
        'player_blocks','player_blocks_alternate',
        'player_steals','player_steals_alternate',
        'player_points_rebounds_assists','player_points_rebounds_assists_alternate',
        'player_points_rebounds','player_points_rebounds_alternate',
        'player_points_assists','player_points_assists_alternate',
        'player_rebounds_assists','player_rebounds_assists_alternate')
),
expected AS (
    SELECT *,
           CASE
             WHEN outcome_name = 'Over'  AND stat_val >= line_value THEN 'Won'
             WHEN outcome_name = 'Over'  AND stat_val <  line_value THEN 'Lost'
             WHEN outcome_name = 'Under' AND stat_val <= line_value THEN 'Won'
             WHEN outcome_name = 'Under' AND stat_val >  line_value THEN 'Lost'
             ELSE NULL
           END AS expected_outcome
    FROM graded
)
SELECT grade_id, grade_date, player_id, game_id, market_key,
       outcome_name, line_value, stat_val, stored_outcome, expected_outcome,
       CASE WHEN stored_outcome IS NULL THEN 'ungraded_but_final' ELSE 'misgraded' END AS mismatch_type
FROM expected
WHERE (stored_outcome IS NULL     AND expected_outcome IS NOT NULL)
   OR (stored_outcome IS NOT NULL AND stored_outcome <> expected_outcome)
ORDER BY grade_date DESC, market_key;
```

`misgraded` = the grade is wrong (the real defect). `ungraded_but_final` = a final-game row the
outcomes job has not settled yet - a settlement gap; expect a batch of these right after games and
before `run_outcomes --mode outcomes` runs. To see only wrong grades, add
`AND mismatch_type = 'misgraded'` to the outer `WHERE` (or filter the result).

### Query B - dedup uniqueness (7-column key)

```sql
SELECT dg.grade_date, dg.event_id, dg.player_id, dg.market_key,
       dg.bookmaker_key, dg.line_value, dg.outcome_name, COUNT(*) AS n_rows
FROM common.daily_grades dg
JOIN odds.upcoming_events ev
  ON ev.event_id = dg.event_id AND ev.sport_key = 'basketball_nba'
GROUP BY dg.grade_date, dg.event_id, dg.player_id, dg.market_key,
         dg.bookmaker_key, dg.line_value, dg.outcome_name
HAVING COUNT(*) > 1
ORDER BY n_rows DESC;
```

Any row = the dedup regression is back (more than one grade per key). Empty = pass.

**Query B2 (diagnostic, not a failure)** - how many distinct books priced the same prop. This is the
5-column collapse the "one row per prop" phrasing reaches for; the grader intentionally keeps one row
per book, so a count > 1 here is normal, not a bug:

```sql
SELECT dg.grade_date, dg.event_id, dg.player_id, dg.market_key,
       dg.line_value, dg.outcome_name, COUNT(DISTINCT dg.bookmaker_key) AS n_books
FROM common.daily_grades dg
JOIN odds.upcoming_events ev
  ON ev.event_id = dg.event_id AND ev.sport_key = 'basketball_nba'
GROUP BY dg.grade_date, dg.event_id, dg.player_id, dg.market_key,
         dg.line_value, dg.outcome_name
HAVING COUNT(DISTINCT dg.bookmaker_key) > 1
ORDER BY n_books DESC;
```

### Query C - EV chain cross-check

```sql
WITH chk AS (
    SELECT dg.grade_id, dg.grade_date, dg.market_key, dg.over_price,
           dg.model_prob, dg.implied_prob, dg.ev_pct,
           CASE WHEN dg.over_price >= 0
                THEN 100.0 / (dg.over_price + 100.0)
                ELSE ABS(dg.over_price) / (ABS(dg.over_price) + 100.0)
           END AS expected_implied_prob,
           CASE WHEN dg.over_price >= 0
                THEN (dg.model_prob * (dg.over_price / 100.0) - (1.0 - dg.model_prob)) * 100.0
                ELSE (dg.model_prob * (100.0 / ABS(dg.over_price)) - (1.0 - dg.model_prob)) * 100.0
           END AS expected_ev_pct
    FROM common.daily_grades dg
    WHERE dg.model_prob   IS NOT NULL
      AND dg.implied_prob IS NOT NULL
      AND dg.ev_pct       IS NOT NULL
      AND dg.over_price   IS NOT NULL
)
SELECT grade_id, grade_date, market_key, over_price, model_prob,
       implied_prob, expected_implied_prob, ev_pct, expected_ev_pct
FROM chk
WHERE ABS(implied_prob - expected_implied_prob) > 1e-6
   OR ABS(ev_pct - expected_ev_pct) > 1e-4
ORDER BY grade_date DESC;
```

The tolerances (`1e-6`, `1e-4`) absorb float representation only, not a real modeling slack: stored
and expected are the same IEEE double expression, so a genuine mismatch is a corrupted or
stale-formula field, not rounding.

## Scope and drift

- **NBA-first**, matching where the bug recurred and where `integrity.py` +
  `cleanup_stale_odds_and_grades.py` are scoped. Add MLB / NFL only after the NBA re-derivation is
  confirmed against real settled data - their stat tables and market sets differ.
- **Re-pull on grader change.** If `grade_props.py` changes any of: `run_outcomes` market_groups or
  the WHEN-ladder (`:3037-3062`), the dedup partition (`:2443-2448`), or the EV block (`:2669-2677`),
  update the matching section here in the same pass. The four anchors in the table above are the
  contract; a diff there means the audit is testing an old definition.
