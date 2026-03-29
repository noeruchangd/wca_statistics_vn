require_relative "../core/statistic"
require "date"

class CompetedInMostConsecutiveWeeks < Statistic
  def initialize
    @title = "Most consecutive weeks with competitions"
    @note = "Only includes people from Vietnam. Weeks are counted as ISO weeks (Monday-Sunday). Multiple competitions in the same week count as one."
    @table_header = {
      "Count" => :right,
      "Person" => :left,
      "Start comp" => :left,
      "End comp" => :left
    }
  end

  def query
    <<-SQL
      SELECT
        person.name,
        person.wca_id,
        competition.id competition_id,
        competition.name competition_name,
        competition.start_date
      FROM results
      JOIN persons person ON person.wca_id = person_id AND person.sub_id = 1 AND person.country_id = 'Vietnam'
      JOIN competitions competition ON competition.id = competition_id
    SQL
  end

  def transform(results)
    results.group_by { |r| r["wca_id"] }.map do |wca_id, person_results|
      name = person_results.first["name"]

      weeks = person_results.map do |r|
        date = r["start_date"]
        monday = date - (date.cwday - 1)
        {
          monday: monday,
          competition_link: "[#{r["competition_name"]}](https://www.worldcubeassociation.org/competitions/#{r["competition_id"]})"
        }
      end.uniq { |entry| entry[:monday] }.sort_by { |entry| entry[:monday] }

      next if weeks.empty?

      max_streak = 1
      current_streak = 1
      streak_start = weeks.first
      best_start = streak_start
      best_end = streak_start

      weeks.each_cons(2) do |prev, curr|
        if curr[:monday] == prev[:monday] + 7
          current_streak += 1
        else
          if current_streak > max_streak
            max_streak = current_streak
            best_start = streak_start
            best_end = prev
          end
          current_streak = 1
          streak_start = curr
        end
      end

      if current_streak > max_streak
        max_streak = current_streak
        best_start = streak_start
        best_end = weeks.last
      end

      [
        max_streak,
        "[#{name}](https://www.worldcubeassociation.org/persons/#{wca_id})",
        best_start[:competition_link],
        best_end[:competition_link]
      ]
    end.compact.sort_by { |row| -row[0] }.first(100)
  end

  def iso_week_string(date)
    "W#{date.cweek.to_s.rjust(2, "0")} #{date.cwyear}"
  end
end
