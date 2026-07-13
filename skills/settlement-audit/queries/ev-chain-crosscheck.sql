-- Query C - EV chain cross-check (read-only; run via mac-mcp sql_query).
-- Rows returned = violations; empty result = pass.
-- Checks only the arithmetic chain model_prob -> implied_prob / ev_pct -> over_price;
-- model_prob is treated as the grader's stored model output, never re-derived.
-- Only rows with all four fields non-NULL are checked (EV is populated only for markets in
-- LOGISTIC_MARKET_GROUP_MAP with weights present; NULL elsewhere is expected).
-- Tolerances (1e-6, 1e-4) absorb float representation only: stored and expected are the same
-- IEEE double expression, so a genuine mismatch is a corrupted or stale-formula field.
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
