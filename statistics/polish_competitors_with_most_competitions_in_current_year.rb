require_relative "../core/statistic"

class PolishCompetitorsWithMostCompetitionsInCurrentYear < Statistic
  def initialize
    @title = "Polish competitors with most competitions in the current year"
    @table_header = { "Competitions" => :right, "Person" => :left }
  end

  def query
    <<-SQL
      SELECT 
        COUNT(DISTINCT competitionId) AS c, 
        CONCAT('[', personName, '](https://www.worldcubeassociation.org/persons/', personId, ')') person_link
      FROM Results 
      WHERE competitionId LIKE CONCAT('%', YEAR(CURDATE())) 
            AND countryId="Poland" 
      GROUP BY personId, personName
      ORDER BY c DESC
    SQL
  end  
end
