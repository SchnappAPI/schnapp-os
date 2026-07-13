-- Query B - dedup uniqueness on the 7-column key (read-only; run via mac-mcp sql_query).
-- Any row returned = the dedup regression is back (more than one grade per key). Empty = pass.
-- The key is 7 columns; asserting on the 5-column phrasing (omitting grade_date and
-- bookmaker_key) raises false positives - one legitimate row per book and per grade_date
-- would look like a duplicate. Cross-book counts are the separate diagnostic
-- (cross-book-count-diagnostic.sql), not a dedup failure.
SELECT dg.grade_date, dg.event_id, dg.player_id, dg.market_key,
       dg.bookmaker_key, dg.line_value, dg.outcome_name, COUNT(*) AS n_rows
FROM common.daily_grades dg
JOIN odds.upcoming_events ev
  ON ev.event_id = dg.event_id AND ev.sport_key = 'basketball_nba'
GROUP BY dg.grade_date, dg.event_id, dg.player_id, dg.market_key,
         dg.bookmaker_key, dg.line_value, dg.outcome_name
HAVING COUNT(*) > 1
ORDER BY n_rows DESC;
