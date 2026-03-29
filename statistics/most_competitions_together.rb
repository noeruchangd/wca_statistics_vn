require_relative "../core/statistic"

class MostCompetitionsTogether < Statistic
  def initialize
    @title = "Most competitions together"
    @table_header = { "Shared competitions" => :right, "Pair" => :left }
  end

  def query
    <<-SQL
      SELECT DISTINCT
        r.person_id,
        r.competition_id,
        p.name
      FROM results r
      JOIN persons p ON r.person_id = p.wca_id
      WHERE p.country_id = 'Vietnam'
    SQL
  end

  def transform(query_results)
    competitions = Hash.new { |h, k| h[k] = [] }

    query_results.each do |row|
      competitions[row["competition_id"]] << {
        id: row["person_id"],
        name: row["name"]
      }
    end

    pair_counts = Hash.new(0)

    competitions.each_value do |people|
      people.uniq! { |p| p[:id] }
      people.combination(2).each do |a, b|
        pair = [a, b].sort_by { |x| x[:id] }
        key = [pair[0][:id], pair[1][:id]]
        pair_counts[key] += 1
      end
    end

    person_names = {}
    query_results.each { |row| person_names[row["person_id"]] ||= row["name"] }

    pair_counts
      .sort_by { |_, count| -count }
      .first(100)
      .map do |(id1, id2), count|
        name1 = person_names[id1]
        name2 = person_names[id2]
        label = "[#{name1}](https://www.worldcubeassociation.org/persons/#{id1}) & [#{name2}](https://www.worldcubeassociation.org/persons/#{id2})"
        [count, label]
      end
  end
end
