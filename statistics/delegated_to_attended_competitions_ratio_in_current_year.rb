require_relative "../core/statistic"

class DelegatedToAttendedCompetitionsRatioInCurrentYear < Statistic
  def initialize
    @title = "Delegated to attended competition ratio in the current year (Vietnam)"
    @table_header = {
      "Delegated" => :right,
      "Attended" => :right,
      "Ratio" => :right,
      "Person" => :left,
      "List on WCA" => :center
    }
  end

  def query
    <<-SQL
      SELECT
        delegated_count,
        attended_count,
  FORMAT(delegated_count / attended_count, 2) AS ratio,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') AS person_link,
        CONCAT('[List](https://www.worldcubeassociation.org/competitions?year=all+years&state=past&delegate=', users.id, ')') AS list_link
      FROM (
        SELECT
          delegate_id,
          COUNT(DISTINCT competition_id) AS delegated_count
        FROM competition_delegates
        JOIN competitions ON competitions.id = competition_id
        WHERE show_at_all = 1
          AND cancelled_at IS NULL
          AND start_date < CURDATE()
          AND results_posted_at IS NOT NULL
          AND competition_id LIKE CONCAT('%', YEAR(CURDATE()))
        GROUP BY delegate_id
      ) AS delegated
   JOIN users ON users.id = delegated.delegate_id
      JOIN (
        SELECT
          person_id,
          COUNT(DISTINCT competition_id) AS attended_count
        FROM results
        WHERE competition_id LIKE CONCAT('%', YEAR(CURDATE()))
          AND country_id = "Vietnam"
        GROUP BY person_id
      ) AS attended ON attended.person_id = users.wca_id
      JOIN persons person ON person.wca_id = users.wca_id AND person.sub_id = 1 AND person.country_id = 'Vietnam'
      ORDER BY ratio DESC, delegated_count DESC
    SQL
  end
end
