require_relative "../../core/grouped_statistic"
require_relative "../../core/events"
require_relative "../../core/solve_time"

class Rankings < GroupedStatistic
  def initialize(title:, note:, condition:)
    @condition = condition

    @title = title
    @note = note
    @table_header = { "Person" => :left, "Result" => :right, "Competition" => :left, "Details" => :left }
  end

  def query
    <<-SQL
      SELECT
        r.event_id,
        r.best single,
        r.average,
        ra.value,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
        CONCAT('[', competition.cell_name, '](https://www.worldcubeassociation.org/competitions/', competition.id, ')') competition_link,
        country.name country
      FROM results r
      JOIN result_attempts ra ON ra.result_id = r.id
      JOIN persons person 
        ON person.wca_id = r.person_id 
        AND person.sub_id = 1 
        AND person.country_id = 'Poland'
      JOIN countries country ON country.id = person.country_id
      JOIN competitions competition ON competition.id = r.competition_id
      #{@condition}
      ORDER BY r.event_id, ra.attempt_number
    SQL
  end

  def transform(query_results)
    Events::ALL.flat_map do |event_id, event_name|
      %w(single average).map do |type|
        results = query_results
          .select { |result| result["event_id"] == event_id && result[type] > 0 }
          .group_by { |result| result["person_link"] }
          .map do |person_link, attempts|
            main_result = SolveTime.new(event_id, type.to_sym, attempts.first[type])
            result_details = attempts
              .map { |attempt| SolveTime.new(event_id, :single, attempt["value"]).clock_format }
              .reject(&:empty?)
              .join(', ')
            [person_link, "**#{main_result.clock_format}**", attempts.first["country"], attempts.first["competition_link"], result_details]
          end
          .sort_by { |r| r[1] } # sortujemy po wyniku
          .first(10)
        ["#{event_name} - #{type.capitalize}", results]
      end
    end
  end
end
