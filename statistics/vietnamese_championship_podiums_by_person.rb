require_relative "../core/statistic"

class VietnameseChampionshipPodiumsByPerson < Statistic
  def initialize
    @title = "Vietnamese Championship podiums by person"
    @table_header = { "Person" => :left, "Gold" => :center, "Silver" => :center, "Bronze" => :center, "Total" => :center }
  end

  def query
    <<-SQL
      WITH vietnamese_results AS (
        SELECT
          result.*,
          ROW_NUMBER() OVER (
            PARTITION BY result.competition_id, result.event_id, result.round_type_id
            ORDER BY result.best ASC
          ) AS vn_rank
        FROM results result
        JOIN competitions competition ON competition.id = result.competition_id
        JOIN championships ON championships.competition_id = result.competition_id
        WHERE
          result.country_id = 'Vietnam'
          AND result.best > 0
          AND result.round_type_id IN ('c', 'f')
          AND championship_type = 'VN'
      )

      SELECT
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
        CONCAT('**', gold_medals, '**'),
        silver_medals,
        bronze_medals,
        gold_medals + silver_medals + bronze_medals total
      FROM (
        SELECT
          person_id,
          SUM(CASE WHEN vn_rank = 1 THEN 1 ELSE 0 END) gold_medals,
          SUM(CASE WHEN vn_rank = 2 THEN 1 ELSE 0 END) silver_medals,
          SUM(CASE WHEN vn_rank = 3 THEN 1 ELSE 0 END) bronze_medals
        FROM vietnamese_results
        GROUP BY person_id
      ) AS medals_by_country
      JOIN persons person ON person.wca_id = person_id AND sub_id = 1
      WHERE gold_medals + silver_medals + bronze_medals > 0
      ORDER BY gold_medals DESC, silver_medals DESC, bronze_medals DESC, person.name
    SQL
  end
end
