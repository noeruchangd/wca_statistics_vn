require_relative "../core/grouped_statistic"

class MostDelegatedWithAnotherDelegate < GroupedStatistic
  def initialize
    @title = "Most delegated competitions with another delegate"
    @note = "Shows how many times each delegate has co-delegated with others. Only Vietnamese delegates are included, and only competitions that have taken place in Vietnam and have results posted are considered."
    @table_header = { "Co-delegate" => :left, "Count" => :right }
  end

  def query
    <<-SQL
      SELECT
        competition_id,
        competitions.country_id,
        users.name AS delegate_name,
        users.wca_id AS wca_id
      FROM competition_delegates
      JOIN users ON users.id = competition_delegates.delegate_id AND users.country_iso2 = 'PL'
      JOIN competitions ON competitions.id = competition_delegates.competition_id
      WHERE competitions.results_posted_at IS NOT NULL
    SQL
  end

  def transform(query_results)
    all_delegate_comps = Hash.new { |h, k| h[k] = Set.new }
    pl_delegate_comps = Hash.new { |h, k| h[k] = Set.new }

    competition_to_delegates = query_results.group_by { |row| row["competition_id"] }
                                            .transform_values do |rows|
      rows.map do |r|
        key = "[#{r["delegate_name"]}](https://www.worldcubeassociation.org/persons/#{r["wca_id"]})"
        all_delegate_comps[key] << r["competition_id"]
        pl_delegate_comps[key] << r["competition_id"] if r["country_id"] == "Vietnam"
        { name: r["delegate_name"], link: key }
      end
    end

    delegate_stats = Hash.new { |h, k| h[k] = Hash.new(0) }

    competition_to_delegates.each_value do |delegates|
      delegates.combination(2).each do |a, b|
        delegate_stats[a[:link]][b[:link]] += 1
        delegate_stats[b[:link]][a[:link]] += 1
      end
    end

    delegate_stats.map do |delegate, partners|
      sorted = partners.sort_by { |_, count| -count }
      table_rows = sorted.map { |partner, count| [partner, count] }
      total = all_delegate_comps[delegate].size
      Vietnamese = pl_delegate_comps[delegate].size
      decorated_name = "#{delegate}\n_Total delegated competitions: #{total} (#{Vietnamese} in Vietnam)_"
      [decorated_name, table_rows]
    end.sort_by { |delegate, _| delegate }
  end
end