require_relative "../core/grouped_statistic"

class MostSolvesBeforeBldSuccess < GroupedStatistic
  def initialize
    @title = "Most solves before getting a successful BLD attempt"
    @table_header = { "Attempts" => :right, "Person" => :left }
  end

  def query
    <<-SQL
      SELECT
        r.event_id,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
        ra.value
      FROM results r
      JOIN result_attempts ra ON ra.result_id = r.id
      JOIN persons person 
        ON person.wca_id = r.person_id 
        AND person.sub_id = 1 
        AND person.country_id = 'Poland'
      JOIN competitions competition 
        ON competition.id = r.competition_id
      JOIN round_types round_type 
        ON round_type.id = r.round_type_id
      WHERE r.event_id IN ('333bf', '444bf', '555bf', '333mbf')
        AND ra.value != 0
      ORDER BY competition.start_date, round_type.rank, ra.attempt_number
    SQL
  end

  def transform(query_results)
    Events::BLD.map do |event_id, event_name|
      attempts_with_people = query_results
        .select { |result| result["event_id"] == event_id }
        .group_by { |result| result["person_link"] }
        .map do |person_link, results|
          attempts_before_success = results
            .map { |result| result["value"] }
            .find_index { |time| time > 0 }
  
          [attempts_before_success, person_link]
        end
        .reject { |attempts_before_success, _| attempts_before_success.nil? }
        .sort_by! { |attempts_before_success, person_link| -attempts_before_success }
        .first(20)
  
      [event_name, attempts_with_people]
    end
  end
end
