require_relative "../core/statistic"

class MostCompetitionsOrganized < Statistic
  def initialize
    @title = "Most competitions organized"
    @table_header = { "Organized" => :right, "Person" => :left}
  end

  def query
    <<-SQL
      SELECT
        organized_count,
        CASE 
          WHEN user.wca_id IS NOT NULL THEN CONCAT('[', user.name, '](https://www.worldcubeassociation.org/persons/', user.wca_id, ')')
          ELSE user.name 
        END AS person_link
      FROM (
        SELECT
          COUNT(DISTINCT competition_id) organized_count,
          organizer_id
        FROM competition_organizers
        JOIN competitions competition ON competition.id = competition_id
        WHERE show_at_all = 1 AND cancelled_at IS NULL AND start_date < CURDATE()
        GROUP BY organizer_id
      ) AS organized_count_by_user
      JOIN users user ON user.id = organizer_id AND user.country_iso2 = 'PL'
      HAVING organized_count > 2
      ORDER BY organized_count DESC
    SQL
  end
end
