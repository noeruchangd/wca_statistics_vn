require_relative "../core/statistic"

class MinxTo333 < Statistic
  def initialize
    @title = "Megaminx results compared to 3x3 (Vietnam)"
    @table_header = { "Person" => :left, "Megaminx" => :right, "3x3" => :right, "Ratio" => :right }
    @note = "This statistic compares the best Megaminx average to the best 3x3 average for Vietnamese competitors."
  end

  def query
    <<-SQL
      SELECT 
          CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') person_link,
          a.best AS minx_best,
          b.best AS three_by_three_best,
          FORMAT(ROUND(a.best / b.best, 3), 2) AS ratio_minx_to_333
      FROM 
          ranks_average a
      JOIN 
          ranks_average b ON a.person_id = b.person_id
      JOIN persons p ON a.person_id = p.wca_id
      WHERE 
          a.event_id = 'minx' AND b.event_id = '333' AND p.country_id = "Vietnam" AND p.sub_id = 1
      ORDER BY ROUND(a.best / b.best, 3)
      LIMIT 20;
    SQL
  end

  def transform(query_results)
    query_results.map do |result|
      minx_best = SolveTime.new("minx", :average, result["minx_best"]).clock_format
      three_by_three_best = SolveTime.new("333", :average, result["three_by_three_best"]).clock_format
      [result["person_link"], minx_best, three_by_three_best, result["ratio_minx_to_333"]]
    end
  end
end
