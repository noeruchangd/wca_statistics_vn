require_relative "../core/grouped_statistic"
require_relative "../core/events"

class MostPersonalRecordsByEvent < GroupedStatistic
  def initialize
    @title = "Most personal records by event"
    @note = "Counts how many personal records (single or average) a competitor achieved in each event."
    @table_header = { "PRs" => :right, "Person" => :left }
  end

  def query
    <<-SQL
      SELECT
        event_id,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
        best single,
        average
      FROM results
      JOIN persons person ON person.wca_id = person_id AND person.sub_id = 1 AND person.country_id = 'Vietnam'
      JOIN competitions competition ON competition.id = competition_id
      JOIN round_types round_type ON round_type.id = round_type_id
      ORDER BY competition.start_date, round_type.rank
    SQL
  end

  def transform(query_results)
    Events::ALL.map do |event_id, event_name|
      pbs_by_person = Hash.new { |h, k| h[k] = { "single" => Float::INFINITY, "average" => Float::INFINITY, "count" => 0 } }

      query_results
        .select { |result| result["event_id"] == event_id }
        .each do |result|
          pbs = pbs_by_person[result["person_link"]]
          %w(single average).each do |type|
            if result[type] > 0 && result[type] < pbs[type]
              pbs[type] = result[type]
              pbs["count"] += 1
            end
          end
        end

      results = pbs_by_person
        .map { |person_link, stats| [stats["count"], person_link] }
        .filter { |count, _| count > 0 }
        .sort_by { |count, _| -count }
        .first(10)

      [event_name, results]
    end
  end
end
