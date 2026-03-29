require_relative "../core/grouped_statistic"

class AvgCompsNumberOfDelegates < GroupedStatistic
  def initialize
    @title = "Average number of competitions of listed delegates at Vietnamese competitions by number of delegates"
    @note = "Competitions are grouped by how many delegates they had. Each table shows the competitions with the highest average number of competitions that listed delegates had participated in up to and including the one they delegated."
    @table_header = {
      "Competition" => :left,
      "Delegates" => :left,
      "Average number of competitions of listed delegates" => :right
    }
  end

  def query
    <<-SQL
      WITH delegate_person AS (
        SELECT
          u.id AS delegate_id,
          u.name,
          u.wca_id AS person_id
        FROM users u
        WHERE u.wca_id IS NOT NULL
      ),
      delegate_competitions AS (
        SELECT
          cd.competition_id,
          cd.delegate_id,
          c.name AS competition_name,
          c.cell_name,
          c.end_date
        FROM competition_delegates cd
        JOIN competitions c ON c.id = cd.competition_id
        WHERE c.country_id = 'Vietnam'
          AND c.cancelled_at IS NULL
          AND c.results_posted_at IS NOT NULL
      ),
      delegate_stats AS (
        SELECT
          dc.competition_id,
          dc.delegate_id,
          COUNT(DISTINCT r.competition_id) AS competitions_as_competitor
        FROM delegate_competitions dc
        JOIN delegate_person dp ON dp.delegate_id = dc.delegate_id
        JOIN competitions c2 ON c2.end_date <= dc.end_date
        JOIN results r ON r.competition_id = c2.id AND r.person_id = dp.person_id
        GROUP BY dc.competition_id, dc.delegate_id
      )
      SELECT
        dc.competition_id,
        dc.competition_name,
        competition.cell_name,
        COUNT(DISTINCT dp.delegate_id) AS num_delegates,
        ROUND(AVG(ds.competitions_as_competitor), 2) AS avg_competitions_before_delegating,
        GROUP_CONCAT(
          DISTINCT CONCAT(
            CASE
              WHEN dp.person_id IS NOT NULL THEN CONCAT('[', dp.name, '](https://www.worldcubeassociation.org/persons/', dp.person_id, ')')
              ELSE dp.name
            END
          )
          ORDER BY dp.name SEPARATOR ', '
        ) AS delegates
      FROM delegate_competitions dc
      JOIN delegate_stats ds ON ds.competition_id = dc.competition_id
      JOIN delegate_person dp ON dp.delegate_id = dc.delegate_id
      JOIN competitions competition ON competition.id = dc.competition_id
      GROUP BY dc.competition_id, dc.competition_name, competition.cell_name
      ORDER BY num_delegates DESC, avg_competitions_before_delegating DESC;
    SQL
  end

  def transform(query_results)
    groups = query_results
      .group_by { |row| row["num_delegates"].to_i }
      .sort_by { |num, _| -num }

    groups.map do |num_delegates, competitions|
      top20 = competitions
        .sort_by { |row| -row["avg_competitions_before_delegating"].to_f }
        .first(20)

      list = top20.map do |row|
        competition_link = "[#{row["cell_name"]}](https://www.worldcubeassociation.org/competitions/#{row["competition_id"]})"
        [competition_link, row["delegates"], format('%.2f', row["avg_competitions_before_delegating"])]
      end

      ["#{num_delegates} Delegate#{'s' if num_delegates > 1}", list]
    end
  end
end
