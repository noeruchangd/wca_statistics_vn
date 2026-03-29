require_relative "../core/statistic"

class MostCommonDelegatesTeam < Statistic
  def initialize
    @title = "Most common delegate teams in Vietnam"
    @note = "This statistic shows the most common teams of delegates in Vietnam. It is based on the number of competitions where the exact team of delegates was listed."
    @table_header = { "Number of competitions" => :left, "Team": :left }
  end

  def query
    <<-SQL
        WITH team_delegates AS (
          SELECT
            competition_id,
            GROUP_CONCAT(
              CONCAT('[', users.name, '](https://www.worldcubeassociation.org/persons/', users.wca_id, ')')
              ORDER BY users.name SEPARATOR ' + '
            ) AS team,
            COUNT(*) AS team_size
          FROM competition_delegates
          JOIN users ON users.id = competition_delegates.delegate_id
          JOIN competitions ON competitions.id = competition_delegates.competition_id
          WHERE competitions.results_posted_at IS NOT NULL AND competitions.country_id = 'Vietnam'
          GROUP BY competition_id
        )
        SELECT
        COUNT(*) AS num_competitions,
        team
        FROM team_delegates
        WHERE team_size >= 2
        GROUP BY team
        ORDER BY num_competitions DESC
        LIMIT 100;
    SQL
  end
end
