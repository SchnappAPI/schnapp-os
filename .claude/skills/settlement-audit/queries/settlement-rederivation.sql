-- Query A - settlement re-derivation (read-only; run via mac-mcp sql_query).
-- Rows returned = violations; empty result = pass.
-- mismatch_type: 'misgraded' = the grade is wrong (the real defect);
-- 'ungraded_but_final' = a final-game row run_outcomes has not settled yet (a settlement
-- gap; expect a batch right after games, before `run_outcomes --mode outcomes` runs).
-- To see only wrong grades, add AND mismatch_type = 'misgraded' to the outer WHERE.
-- Definitions mirror grade_props.py run_outcomes (market_groups + WHEN-ladder); if the
-- grader changes, update this file in the same pass (see SKILL.md anchors).
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
