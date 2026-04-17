require_relative "../core/statistic"

class MedalsCompetitionsRatio < Statistic
  def initialize
    @title = "Medals to competitions ratio"
    @note = "Only Vietnamese competitors included"
    @table_header = { "Person" => :left, "Medals" => :right, "Competitions" => :right, "Ratio" => :right }
  end

  def query
    <<-SQL
     SELECT
  CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
  stats.medals,
  stats.competitions,
  FORMAT(stats.medals / stats.competitions, 2) AS ratio
FROM (
  SELECT
    person_id,
    SUM(IF(pos IN (1,2,3) AND best > 0 AND round_type_id IN ('c', 'f'), 1, 0)) AS medals,
    COUNT(DISTINCT competition_id) AS competitions
  FROM results
  GROUP BY person_id
) AS stats
JOIN persons person ON person.wca_id = stats.person_id AND person.sub_id = 1
WHERE person.country_id = 'Vietnam'
  AND stats.competitions > 0
  AND (stats.medals / stats.competitions) > 1.5
ORDER BY CAST(ratio AS DECIMAL(10,2)) DESC, stats.medals DESC, stats.competitions ASC, person.name

    SQL
  end
end
