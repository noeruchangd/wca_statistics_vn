require_relative "../core/statistic"

class MostAttendedCompetitionsInSingleMonthUnique < Statistic
  def initialize
    @title = "Most attended competitions in a single month (unique competitor)"
    @table_header = { "Competitions" => :right, "Person" => :left, "Month" => :left, "Year" => :left, "List" => :left }
  end
  def query
    <<-SQL
      WITH unique_competitions AS (
        SELECT DISTINCT person_id, competition_id
        FROM results
      ),
      counted_competitions AS (
        SELECT
          uc.person_id,
          MONTH(c.start_date) AS competitions_month,
          YEAR(c.start_date) AS competitions_year,
          COUNT(*) AS attended_within_month
        FROM unique_competitions uc
        JOIN competitions c ON c.id = uc.competition_id
        GROUP BY uc.person_id, MONTH(c.start_date), YEAR(c.start_date)
      ),
      competition_links AS (
        SELECT
          uc.person_id,
          MONTH(c.start_date) AS competitions_month,
          YEAR(c.start_date) AS competitions_year,
          GROUP_CONCAT(
            CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, ')')
            ORDER BY c.start_date
          ) AS competition_links
        FROM unique_competitions uc
        JOIN competitions c ON c.id = uc.competition_id
        GROUP BY uc.person_id, MONTH(c.start_date), YEAR(c.start_date)
      ),
      ranked_competitions AS (
        SELECT
          cc.person_id,
          cc.competitions_month,
          cc.competitions_year,
          cc.attended_within_month,
          cl.competition_links,
          ROW_NUMBER() OVER (PARTITION BY cc.person_id ORDER BY cc.attended_within_month DESC) AS rn
        FROM counted_competitions cc
        JOIN competition_links cl
          ON cc.person_id = cl.person_id
          AND cc.competitions_month = cl.competitions_month
          AND cc.competitions_year = cl.competitions_year
      )
      SELECT
        rc.attended_within_month,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        MONTHNAME(STR_TO_DATE(rc.competitions_month, '%m')) AS month_name,
        rc.competitions_year,
        rc.competition_links
      FROM ranked_competitions rc
      JOIN persons p ON p.wca_id = rc.person_id AND p.sub_id = 1 AND p.country_id = 'Vietnam'
      WHERE rc.rn = 1 AND rc.attended_within_month >= 2
      ORDER BY rc.attended_within_month DESC, p.name
    SQL
  end  
end
