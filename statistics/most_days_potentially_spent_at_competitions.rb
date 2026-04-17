require_relative "../core/statistic"

class MostDaysPotentiallySpentAtCompetitions < Statistic
  def initialize
    @title = "Most days potentially spent at competitions"
    @table_header = { "Days" => :right, "Person" => :left, "Competitions" => :right }
  end

  def query
    <<-SQL
      SELECT
        SUM(DATEDIFF(end_date, start_date) + 1) AS total_days,
        CONCAT('[', name, '](https://www.worldcubeassociation.org/persons/', person_id, ')') person_link,
        COUNT(DISTINCT id) AS competitions
      FROM ( 
        SELECT DISTINCT
          r.person_id,
          p.name,
          c.id,
          c.start_date,
          c.end_date,
          p.wca_id
        FROM results r
        JOIN competitions c ON r.competition_id = c.id
        JOIN persons p ON r.person_id = p.wca_id
        WHERE p.country_id = 'Vietnam' AND p.sub_id = 1
      ) AS unique_participations
      GROUP BY name, person_id
      HAVING total_days > 20
      ORDER BY total_days DESC;
    SQL
  end
end
