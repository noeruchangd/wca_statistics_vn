require_relative "../core/grouped_statistic"

class MostCompletedSolves < GroupedStatistic
  def initialize
    @title = "Most completed solves"
    @table_header = { "" => :left, "Solves" => :right, "Attempts" => :right }
  end

  def query
    <<-SQL
      SELECT
        SUM(CASE WHEN ra.value > 0 THEN 1 ELSE 0 END) completed_count,
        SUM(CASE WHEN ra.value = -1 THEN 1 ELSE 0 END) dnfs_count,
        CONCAT('[', competition.cell_name, '](https://www.worldcubeassociation.org/competitions/', competition.id, ')') competition_link,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
        country.name country,
        continent.name continent,
        YEAR(competition.start_date) year,
        event.name event
      FROM results r
      JOIN result_attempts ra ON ra.result_id = r.id
      JOIN persons person 
        ON person.wca_id = r.person_id 
        AND person.sub_id = 1 
        AND person.country_id = 'Poland'
      JOIN competitions competition 
        ON competition.id = r.competition_id
      JOIN countries country 
        ON country.id = competition.country_id
      JOIN continents continent 
        ON continent.id = country.continent_id
      JOIN events event 
        ON event.id = r.event_id
      GROUP BY r.id
    SQL
  end

  def transform(query_results)
    {
      "Competition" => "competition_link",
      "Person" => "person_link",
      "Year" => "year",
      "Event" => "event"
    }.map do |group_name, group_field|
      count_by_group = query_results
        .group_by { |result| result[group_field] }
        .map do |group_value, results|
          completed_count = results.sum { |result| result["completed_count"] }
          attempts_count = completed_count + results.sum { |result| result["dnfs_count"] } # Completed and DNFs.
          [group_value, completed_count, attempts_count]
        end
        .sort_by! { |group_value, completed_count, attempts_count| [-completed_count, attempts_count, group_value] }
        .first(20)
        .map! { |group_value, completed_count, attempts_count| [group_value, "**#{completed_count}**", attempts_count] }
      [group_name, count_by_group]
    end
  end
end
