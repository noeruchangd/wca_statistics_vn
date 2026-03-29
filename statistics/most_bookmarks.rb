require_relative "../core/statistic"

class MostBookmarks < Statistic
  def initialize
    @title = "Most bookmarks compared to competitor limit"
    @table_header = { "Competition" => :right, "Bookmarks" => :left, "Competitor limit" => :left, "Ratio" => :left }
  end

  def query
    <<-SQL
      SELECT 
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, ')') competition_link,
        COUNT(*) AS bookmarks, 
        competitor_limit, 
        ROUND(CAST(COUNT(*) AS FLOAT) / competitor_limit, 5) AS bookmark_ratio
      FROM bookmarked_competitions AS bc 
      JOIN competitions AS c ON bc.competition_id = c.id 
      WHERE competitor_limit_enabled = true 
        AND c.country_id = "Vietnam"
      GROUP BY competition_id, c.name, competitor_limit
      HAVING COUNT(*) > 0
      ORDER BY bookmark_ratio DESC
      LIMIT 20;
    SQL
  end
end
