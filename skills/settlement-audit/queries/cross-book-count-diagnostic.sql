-- Query B2 - cross-book count (DIAGNOSTIC, not a failure; run via mac-mcp sql_query).
-- How many distinct books priced the same prop. This is the 5-column collapse the
-- "one row per prop" phrasing reaches for; the grader intentionally keeps one row per
-- book, so a count > 1 here is normal, not a bug.
SELECT dg.grade_date, dg.event_id, dg.player_id, dg.market_key,
       dg.line_value, dg.outcome_name, COUNT(DISTINCT dg.bookmaker_key) AS n_books
FROM common.daily_grades dg
JOIN odds.upcoming_events ev
  ON ev.event_id = dg.event_id AND ev.sport_key = 'basketball_nba'
GROUP BY dg.grade_date, dg.event_id, dg.player_id, dg.market_key,
         dg.line_value, dg.outcome_name
HAVING COUNT(DISTINCT dg.bookmaker_key) > 1
ORDER BY n_books DESC;
