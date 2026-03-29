require_relative "../core/statistic"

class AvgResultsSubmissionTime < Statistic
  def initialize
    @title = "Average results submission time by Vietnamese delegates"
    @table_header = { "Delegate" => :right, "Average time" => :left, "Total delegated" => :right }
  end

  def query
    <<-SQL
SELECT
    CASE 
        WHEN d.wca_id IS NOT NULL THEN CONCAT('[', d.name, '](https://www.worldcubeassociation.org/persons/', d.wca_id, ')')
        ELSE d.name 
    END AS delegate_name,
    CASE 
        WHEN ABS(AVG(TIMESTAMPDIFF(SECOND, (
            SELECT sa.end_time
            FROM schedule_activities sa
            JOIN venue_rooms vr ON sa.venue_room_id = vr.id
            JOIN competition_venues cv ON vr.competition_venue_id = cv.id
            WHERE cv.competition_id = c.id
            ORDER BY sa.end_time DESC
            LIMIT 1
        ), c.results_submitted_at) / 3600)) < 24 THEN
            CONCAT(ROUND(AVG(TIMESTAMPDIFF(SECOND, (
                SELECT sa.end_time
                FROM schedule_activities sa
                JOIN venue_rooms vr ON sa.venue_room_id = vr.id
                JOIN competition_venues cv ON vr.competition_venue_id = cv.id
                WHERE cv.competition_id = c.id
                ORDER BY sa.end_time DESC
                LIMIT 1
            ), c.results_submitted_at) / 3600), 2), 'h')
        ELSE
            CONCAT(
                FLOOR(AVG(TIMESTAMPDIFF(SECOND, (
                    SELECT sa.end_time
                    FROM schedule_activities sa
                    JOIN venue_rooms vr ON sa.venue_room_id = vr.id
                    JOIN competition_venues cv ON vr.competition_venue_id = cv.id
                    WHERE cv.competition_id = c.id
                    ORDER BY sa.end_time DESC
                    LIMIT 1
                ), c.results_submitted_at) / 3600) / 24), 'd ',
                MOD(ROUND(AVG(TIMESTAMPDIFF(SECOND, (
                    SELECT sa.end_time
                    FROM schedule_activities sa
                    JOIN venue_rooms vr ON sa.venue_room_id = vr.id
                    JOIN competition_venues cv ON vr.competition_venue_id = cv.id
                    WHERE cv.competition_id = c.id
                    ORDER BY sa.end_time DESC
                    LIMIT 1
                ), c.results_submitted_at) / 3600), 2), 24), 'h'
            )
    END AS avg_submission_time,
    COUNT(DISTINCT c.id) AS delegated_competitions
FROM 
    competitions c
JOIN 
    competition_delegates cd ON cd.competition_id = c.id
JOIN 
    users d ON cd.delegate_id = d.id AND d.country_iso2 = 'VN'
WHERE 
    c.results_submitted_at IS NOT NULL
    AND c.country_id NOT IN ('XA', 'XE', 'XF', 'XM', 'XN', 'XO', 'XS', 'XW')
GROUP BY 
    d.id, d.name, d.wca_id
HAVING 
    avg_submission_time IS NOT NULL
ORDER BY 
    AVG(TIMESTAMPDIFF(SECOND, (
        SELECT sa.end_time
        FROM schedule_activities sa
        JOIN venue_rooms vr ON sa.venue_room_id = vr.id
        JOIN competition_venues cv ON vr.competition_venue_id = cv.id
        WHERE cv.competition_id = c.id
        ORDER BY sa.end_time DESC
        LIMIT 1
    ), c.results_submitted_at)) ASC;
    SQL
  end
end
