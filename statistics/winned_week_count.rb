require_relative "../core/grouped_statistic"

class WinnedWeekCount < GroupedStatistic
  def initialize
    @title = "Winned week count"
    @note = "In other words it's the number of weeks when the given person got the fastest single in the given event."
    @table_header = { "Person" => :left, "Winned weeks" => :right }
  end

  # def query
  #   <<-SQL
  #     SELECT
  #       event_id,
  #       CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
  #       winned_weeks
  #     FROM (
  #       SELECT
  #         333_best_by_week.event_id,
  #         person_id,
  #         COUNT(DISTINCT 333_best_by_week.event_id, best, week_start_date) winned_weeks
  #       FROM (
  #         SELECT
  #           event_id,
  #           MIN(best) week_best,
  #           DATE_ADD(start_date, INTERVAL(-WEEKDAY(start_date)) DAY) week_start_date,
  #           DATE_ADD(start_date, INTERVAL(6 - WEEKDAY(start_date)) DAY) week_end_date
  #         FROM results
  #         JOIN competitions competition ON competition.id = competition_id
  #         WHERE best > 0
  #         GROUP BY event_id, week_start_date, week_end_date
  #       ) AS 333_best_by_week
  #       JOIN results result ON result.event_id = 333_best_by_week.event_id AND best = week_best
  #       JOIN competitions competition ON competition.id = competition_id
  #       WHERE start_date BETWEEN week_start_date AND week_end_date
  #       GROUP BY 333_best_by_week.event_id, person_id
  #     ) AS winned_weeks_by_person
  #     JOIN persons person ON person.wca_id = person_id AND sub_id = 1 AND person.country_id = 'Vietnam';
  #   SQL
  # end

  def query
    <<-SQL
      SELECT
        bw.event_id,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        COUNT(*) AS winned_weeks
      FROM (
        SELECT
          r.event_id,
          MIN(r.best) AS week_best,
          DATE_ADD(c.start_date, INTERVAL(-WEEKDAY(c.start_date)) DAY) AS week_start
        FROM results r
        JOIN competitions c ON c.id = r.competition_id
        JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Vietnam'
        WHERE r.best > 0
        GROUP BY r.event_id, week_start
      ) bw
      JOIN results r ON r.event_id = bw.event_id AND r.best = bw.week_best
      JOIN competitions c ON c.id = r.competition_id
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Vietnam'
      WHERE DATE_ADD(c.start_date, INTERVAL(-WEEKDAY(c.start_date)) DAY) = bw.week_start
      GROUP BY bw.event_id, p.wca_id, p.name
      ORDER BY winned_weeks DESC;
    SQL
  end

  def transform(query_results)
    Events::ALL.map do |event_id, event_name|
      results = query_results
        .select { |result| result["event_id"] == event_id }
        .sort_by! do |result|
          -result["winned_weeks"]
        end
        .first(20)
        .map! do |result|
          [result["person_link"], result["winned_weeks"]]
        end
      [event_name, results]
    end
  end
end
