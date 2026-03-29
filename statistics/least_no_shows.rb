require_relative "../core/statistic"

class LeastNoShows < Statistic
  def initialize
    @title = "Competitions with the least number of no-shows in Vietnam"
    @note = "This statistic shows the competitions in Vietnam with the least number of no-shows."
    @table_header = { "Competition" => :left, "Total registered" => :right, "Total competed" => :right, "No-shows" => :right }
  end

  def query
    <<-SQL
      SELECT
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, ')') AS competition_link,
        COUNT(DISTINCT r.user_id) AS total_registered,
        COUNT(DISTINCT res.person_id) AS total_competed,
        (COUNT(DISTINCT r.user_id) - COUNT(DISTINCT res.person_id)) AS no_shows
      FROM competitions c
      JOIN registrations r ON r.competition_id = c.id
      LEFT JOIN results res ON res.competition_id = c.id AND res.person_id = (
        SELECT wca_id FROM users WHERE id = r.user_id
      )
      WHERE r.competing_status = 'accepted'
        AND c.country_id = 'Vietnam' AND c.use_wca_registration = 1
      GROUP BY c.id, c.name
      ORDER BY no_shows ASC, total_registered DESC
      LIMIT 20
    SQL
  end
end
