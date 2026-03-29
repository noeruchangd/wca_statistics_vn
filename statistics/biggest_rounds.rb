require_relative "../core/grouped_statistic"
require_relative "../core/events"
require_relative "../core/solve_time"

class BiggestRounds < GroupedStatistic
  def initialize
    @title = "Biggest rounds in Vietnam"
    @table_header = { "Number of competitors" => :right, "Competition": :left }
  end

  def query
    <<-SQL
      SELECT
        event_id,
        CONCAT('[', competition.cell_name, '](https://www.worldcubeassociation.org/competitions/', competition.id, ')') competition_link,
        COUNT(*) as competitors
      FROM results
      JOIN competitions competition ON competition.id = competition_id
      WHERE competition.country_id = 'Vietnam'
      GROUP BY event_id, competition_id, round_type_id
      ORDER BY competitors DESC
    SQL
  end

  def transform(query_results)
    Events::ALL.map do |event_id, event_name|
      event_results = query_results
        .select { |result| result["event_id"] == event_id }
        .sort_by { |result| -result["competitors"].to_i }
        .first(10)
        .map do |result|
          [result["competitors"], result["competition_link"]]
        end
      [event_name, event_results]
    end
  end
end
