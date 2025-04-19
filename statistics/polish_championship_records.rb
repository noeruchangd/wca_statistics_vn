require_relative "../core/grouped_statistic"
require_relative "../core/solve_time"
require_relative "../core/events"

class PolishChampionshipRecords < GroupedStatistic
  def initialize
    @title = "Polish Championship records"
    @note = "This is a list of the best results from all Polish Championships. It corresponds to Olympic records for Olympic sports."
    @table_header = { "Event" => :left, "Result" => :right, "Person" => :left, "Citizen of" => :left, "Competition" => :left }
  end

  def query
    <<-SQL
      SELECT
        event_id,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
        CONCAT('[', competition.cell_name, '](https://www.worldcubeassociation.org/competitions/', competition.id, ')') competition_link,
        best single,
        average
      FROM results
      JOIN persons person ON person.wca_id = person_id AND person.sub_id = 1 AND person.country_id = 'Poland'
      JOIN competitions competition ON competition.id = competition_id
      JOIN countries country ON country.id = person.country_id
      JOIN championships ON championships.competition_id = results.competition_id
      WHERE championship_type = 'PL'
    SQL
  end

  def transform(query_results)
    { "Single" => "single", "Average" => "average" }.map do |header, type|
      records_by_event = Hash.new { |hash, key| hash[key] = { type => SolveTime::DNF } }
      query_results
        .each do |result|
          result[type] = SolveTime.new(result["event_id"], type, result[type])
          if result[type] <= records_by_event[result["event_id"]][type]
            records_by_event[result["event_id"]] = result
          end
        end
      records = Events::OFFICIAL
        .map { |event_id, event_name| [event_name, records_by_event[event_id]] }
        .select { |event_name, result| result[type].complete? }
        .map! do |event_name, result|
          [event_name, result[type].clock_format, result["person_link"], result["competition_link"]]
        end
      [header, records]
    end
  end
end
