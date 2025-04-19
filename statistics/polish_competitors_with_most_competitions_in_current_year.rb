require_relative "../core/statistic"

class PolishCompetitorsWithMostCompetitionsInCurrentYear < Statistic
  def initialize
    @title = "Polish competitors with most competitions in the current year"
    @table_header = { "Competitions" => :right, "Person" => :left }
  end

  def query
    <<-SQL
      SELECT 
        COUNT(DISTINCT competition_id) AS c, 
        CONCAT('[', person_name, '](https://www.worldcubeassociation.org/persons/', person_id, ')') person_link
      FROM results 
      WHERE competition_id LIKE CONCAT('%', YEAR(CURDATE())) 
            AND country_id="Poland" 
      GROUP BY person_id, person_name
      ORDER BY c DESC
    SQL
  end  
end
