require_relative "../core/statistic"

class MostCompletedSolvesAtOneCompetition < Statistic
  def initialize
    @title = "Most completed solves at one competition"
    @table_header = { "Person" => :left, "Competition" => :right, "Solves" => :right, "Attempts" => :right }
  end

  def query
    <<-SQL
      SELECT
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
        CONCAT('[', competition.cell_name, '](https://www.worldcubeassociation.org/competitions/', competition.id, ')') competition_link,
        SUM(CASE WHEN ra.value > 0 THEN 1 ELSE 0 END) completed_count,
        SUM(CASE WHEN ra.value != 0 THEN 1 ELSE 0 END) attempts_count
      FROM results r
      JOIN result_attempts ra ON ra.result_id = r.id
      JOIN persons person 
        ON person.wca_id = r.person_id 
        AND person.sub_id = 1
      JOIN competitions competition 
        ON competition.id = r.competition_id
      GROUP BY person.wca_id, competition.id
      ORDER BY completed_count DESC
      LIMIT 20
    SQL
  end
end
